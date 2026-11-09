import ContentKit
import Foundation

/// Seviye testindeki bir soru: İngilizce kelime ve dört Türkçe anlam.
struct LevelQuestion: Equatable, Identifiable {
  /// Sorulan kelime.
  let word: Word
  /// Şıklar (Türkçe anlamlar), karışık sırada.
  let options: [String]
  /// Doğru şıkkın sırası.
  let correctIndex: Int

  var id: String { word.id }
  /// Sorunun seviyesi.
  var level: CEFRLevel { word.level }
}

/// Seviye testinin durumu.
enum LevelTestPhase: Equatable {
  /// Kelimeler yükleniyor.
  case loading
  /// Sorular soruluyor.
  case asking
  /// Test bitti; önerilen seviye.
  case finished(CEFRLevel)
  /// Yeterli kelime yok.
  case unavailable
}

/// Kısa uyarlanabilir seviye testi: doğru cevapta bir üst, yanlışta bir alt seviyeye geçer.
///
/// Kelimeler `ContentProviding` içindeki paketlerden seviyelerine göre toplanır. Şıklar aynı
/// seviyedeki başka kelimelerin anlamlarıdır (yetmezse komşu seviyelerden tamamlanır).
@MainActor
final class LevelTestViewModel: ObservableObject, Identifiable {

  // MARK: - Properties

  @Published private(set) var phase: LevelTestPhase = .loading
  @Published private(set) var question: LevelQuestion?
  /// Bu soruda seçilen şık (cevaplanmadıysa nil).
  @Published private(set) var selectedIndex: Int?
  /// Sorulan soru sayısı (mevcut soru dahil).
  @Published private(set) var askedCount = 0
  /// Doğru cevap sayısı.
  @Published private(set) var correctCount = 0

  /// Toplam soru sayısı.
  let totalQuestions: Int
  /// Teste başlanan seviye.
  let startLevel: CEFRLevel
  private let content: any ContentProviding
  private var generator: any RandomNumberGenerator
  private var pool: [CEFRLevel: [Word]] = [:]
  private var usedWordIds: Set<String> = []
  private var current: CEFRLevel
  private var results: [CEFRLevel: (correct: Int, total: Int)] = [:]

  // MARK: - Init

  init(
    content: any ContentProviding, totalQuestions: Int = 10, startLevel: CEFRLevel = .a2,
    generator: any RandomNumberGenerator = SystemRandomNumberGenerator()
  ) {
    self.content = content
    self.totalQuestions = totalQuestions
    self.startLevel = startLevel
    self.generator = generator
    current = startLevel
  }

  // MARK: - Intents

  /// Kelime havuzunu yükler ve ilk soruyu hazırlar.
  func start() async {
    guard phase == .loading else { return }
    pool = await Self.loadPool(from: content)
    let total = pool.values.reduce(0) { $0 + $1.count }
    guard total >= 4 else {
      phase = .unavailable
      return
    }
    phase = .asking
    askNext()
  }

  /// Şıkkı seçer; aynı soruya ikinci cevap yok sayılır.
  func answer(_ index: Int) {
    guard phase == .asking, let question, selectedIndex == nil else { return }
    selectedIndex = index
    let isCorrect = index == question.correctIndex
    var result = results[question.level] ?? (0, 0)
    result.total += 1
    if isCorrect {
      result.correct += 1
      correctCount += 1
    }
    results[question.level] = result
    current = Self.step(question.level, by: isCorrect ? 1 : -1)
  }

  /// Sonraki soruya geçer ya da testi bitirir.
  func next() {
    guard phase == .asking, selectedIndex != nil else { return }
    if askedCount >= totalQuestions {
      phase = .finished(Self.estimate(results))
    } else {
      askNext()
    }
  }

  /// Seçilen şık doğru muydu (cevaplanmadıysa nil).
  var lastAnswerCorrect: Bool? {
    guard let selectedIndex, let question else { return nil }
    return selectedIndex == question.correctIndex
  }

  /// İlerleme (0–1).
  var progress: Double {
    totalQuestions == 0 ? 0 : Double(askedCount) / Double(totalQuestions)
  }

  // MARK: - Scoring

  /// Sonuçlardan seviye tahmini: en az bir doğru ve en az %50 başarı olan en yüksek seviye.
  static func estimate(_ results: [CEFRLevel: (correct: Int, total: Int)]) -> CEFRLevel {
    CEFRLevel.allCases.reversed().first { level in
      guard let result = results[level], result.correct > 0 else { return false }
      return Double(result.correct) / Double(result.total) >= 0.5
    } ?? .a1
  }

  /// Seviyeyi `offset` kadar kaydırır (A1–C1 arasında kalır).
  static func step(_ level: CEFRLevel, by offset: Int) -> CEFRLevel {
    let levels = CEFRLevel.allCases
    let index = levels.firstIndex(of: level) ?? 0
    return levels[min(max(index + offset, 0), levels.count - 1)]
  }

  // MARK: - Private

  /// Tüm paketlerin kelimelerini seviyelerine göre toplar (tekrarsız).
  private static func loadPool(from content: any ContentProviding) async -> [CEFRLevel: [Word]] {
    var ids: [String] = []
    var seen: Set<String> = []
    for pack in await content.packs() {
      for puzzle in await content.puzzles(inPack: pack.id) {
        for id in puzzle.wordIds where seen.insert(id).inserted { ids.append(id) }
      }
    }
    let words = await content.words(ids: ids)
    var meanings: Set<String> = []
    let unique = words.filter { !$0.meaning.isEmpty && meanings.insert($0.meaning).inserted }
    return Dictionary(grouping: unique, by: \.level)
  }

  /// Mevcut seviyeye (yoksa en yakın seviyeye) göre yeni soru hazırlar.
  private func askNext() {
    guard let word = pickWord() else {
      phase = .finished(Self.estimate(results))
      return
    }
    usedWordIds.insert(word.id)
    var distractors = distractorMeanings(for: word)
    distractors.shuffle(using: &generator)
    var options = Array(distractors.prefix(3)) + [word.meaning]
    options.shuffle(using: &generator)
    question = LevelQuestion(
      word: word, options: options, correctIndex: options.firstIndex(of: word.meaning) ?? 0)
    selectedIndex = nil
    askedCount += 1
  }

  /// Seviyeye en yakın, henüz sorulmamış kelimeyi seçer.
  private func pickWord() -> Word? {
    for level in Self.nearest(to: current) {
      let fresh = (pool[level] ?? []).filter { !usedWordIds.contains($0.id) }
      if let word = fresh.randomElement(using: &generator) { return word }
    }
    return nil
  }

  /// Aynı seviyeden, yetmezse komşu seviyelerden yanlış şıklar.
  private func distractorMeanings(for word: Word) -> [String] {
    var result: [String] = []
    for level in Self.nearest(to: word.level) {
      let meanings = (pool[level] ?? []).filter { $0.id != word.id }.map(\.meaning)
      result += meanings.filter { $0 != word.meaning && !result.contains($0) }
      if result.count >= 3 { break }
    }
    return result
  }

  /// Seviyeleri verilen seviyeye uzaklığına göre sıralar (eşitlikte alt seviye önce).
  private static func nearest(to level: CEFRLevel) -> [CEFRLevel] {
    let levels = CEFRLevel.allCases
    let index = levels.firstIndex(of: level) ?? 0
    return levels.enumerated()
      .sorted { lhs, rhs in
        let left = abs(lhs.offset - index)
        let right = abs(rhs.offset - index)
        return left == right ? lhs.offset < rhs.offset : left < right
      }
      .map(\.element)
  }
}
