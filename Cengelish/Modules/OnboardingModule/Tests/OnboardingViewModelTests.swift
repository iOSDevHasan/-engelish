import ContentKit
import DesignKit
import Foundation
import Testing
import UserDataKit
@testable import OnboardingModule

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {

  @Test("Adımlar sırayla ilerler ve geri gider")
  func steps() {
    let sut = makeSUT()
    sut.next()
    #expect(sut.step == .profile)
    sut.back()
    #expect(sut.step == .welcome)
  }

  @Test("Takma ad 16 karakterle sınırlanır")
  func nicknameLimit() {
    let sut = makeSUT()
    sut.setNickname(String(repeating: "a", count: 30))
    #expect(sut.nickname.count == 16)
  }

  @Test("Yeni amaçlar tema paketleriyle aynı kimliği taşır")
  func goals() {
    #expect(LearningGoal.business.rawValue == "is")
    #expect(LearningGoal.travel.title == "Seyahat")
    #expect(LearningGoal.football.rawValue == "futbol")
    #expect(LearningGoal.toefl.title == "TOEFL")
    #expect(DailyGoalOption.all.map(\.minutes) == ["5 dk", "10 dk", "15 dk"])
  }

  @Test("Hatırlatıcı metni seçilen saati gösterir")
  func reminderDetail() {
    let sut = makeSUT()
    #expect(sut.reminderDetail == "Her gün 20:00 · Günün bulmacası hazır")
    sut.reminderHour = 8
    sut.reminderMinute = 30
    #expect(sut.reminderDetail == "Her gün 08:30 · Günün bulmacası hazır")
  }

  @Test("Seviye testinin önerisi kabul edilince seviye seçilir ve test kapanır")
  func acceptLevel() {
    let sut = makeSUT()
    sut.openLevelTest()
    #expect(sut.levelTest != nil)
    sut.acceptLevel(.b2)
    #expect(sut.level == .b2)
    #expect(sut.levelTest == nil)
  }

  @Test("Bitince profil kaydedilir, akış kapanır ve paywall bir kez açılır")
  func complete() async {
    let store = UserDataStore(inMemory: true)
    var finished = false
    var paywallCount = 0
    let sut = OnboardingViewModel(
      userData: store, content: LevelContent(), onFinish: { finished = true },
      showPaywall: { paywallCount += 1 })
    sut.setNickname("Deniz")
    sut.reminderOn = false
    sut.useICloud = false
    sut.reminderHour = 21
    await sut.complete()
    #expect(finished)
    #expect(paywallCount == 1)
    #expect(store.profile?.nickname == "Deniz")
    #expect(store.settings.reminderHour == 21)
  }

  @Test("Çengelish+ kullanıcısına onboarding sonunda paywall gösterilmez")
  func completePremium() async {
    var paywallCount = 0
    let sut = OnboardingViewModel(
      userData: UserDataStore(inMemory: true), content: LevelContent(), isPremium: { true },
      onFinish: {}, showPaywall: { paywallCount += 1 })
    sut.reminderOn = false
    sut.useICloud = false
    await sut.complete()
    #expect(paywallCount == 0)
  }

  private func makeSUT() -> OnboardingViewModel {
    OnboardingViewModel(
      userData: UserDataStore(inMemory: true), content: LevelContent(), onFinish: {})
  }
}

@Suite("LevelTestViewModel")
@MainActor
struct LevelTestViewModelTests {

  @Test("Her soruda dört farklı şık var; doğru anlam içinde, yanlışlar aynı seviyeden")
  func options() async throws {
    let sut = makeSUT()
    await sut.start()
    #expect(sut.phase == .asking)
    let question = try #require(sut.question)
    #expect(question.options.count == 4)
    #expect(Set(question.options).count == 4)
    #expect(question.options[question.correctIndex] == question.word.meaning)
    let prefix = question.level.rawValue.lowercased()
    #expect(question.options.allSatisfy { $0.hasPrefix(prefix) })
    #expect(question.level == .a2)
  }

  @Test("Hep doğru cevap seviyeyi C1'e çıkarır")
  func allCorrect() async {
    let sut = makeSUT()
    await sut.start()
    var levels: [CEFRLevel] = []
    while sut.phase == .asking, let question = sut.question {
      levels.append(question.level)
      sut.answer(question.correctIndex)
      sut.next()
    }
    #expect(levels.count == 10)
    #expect(Array(levels.prefix(4)) == [.a2, .b1, .b2, .c1])
    #expect(Set(levels.map(\.rawValue)).count == 4)
    #expect(sut.phase == .finished(.c1))
    #expect(sut.correctCount == 10)
  }

  @Test("Hep yanlış cevap A1 önerir")
  func allWrong() async {
    let sut = makeSUT()
    await sut.start()
    while sut.phase == .asking, let question = sut.question {
      sut.answer((question.correctIndex + 1) % question.options.count)
      sut.next()
    }
    #expect(sut.phase == .finished(.a1))
    #expect(sut.correctCount == 0)
  }

  @Test("Aynı soruya ikinci cevap ve cevapsız ilerleme yok sayılır")
  func guards() async throws {
    let sut = makeSUT()
    await sut.start()
    sut.next()
    #expect(sut.askedCount == 1)
    let question = try #require(sut.question)
    sut.answer(question.correctIndex)
    sut.answer((question.correctIndex + 1) % 4)
    #expect(sut.correctCount == 1)
    #expect(sut.lastAnswerCorrect == true)
    sut.next()
    #expect(sut.askedCount == 2)
    #expect(sut.selectedIndex == nil)
  }

  @Test("Kelime sorulduktan sonra tekrar sorulmaz")
  func noRepeats() async {
    let sut = makeSUT()
    await sut.start()
    var ids: [String] = []
    while sut.phase == .asking, let question = sut.question {
      ids.append(question.word.id)
      sut.answer(question.correctIndex)
      sut.next()
    }
    #expect(Set(ids).count == ids.count)
  }

  @Test("Yeterli kelime yoksa test açılmaz")
  func unavailable() async {
    let sut = LevelTestViewModel(content: LevelContent(wordsPerLevel: 0))
    await sut.start()
    #expect(sut.phase == .unavailable)
  }

  @Test("Seviye tahmini %50 başarılı en yüksek seviyedir")
  func estimate() {
    #expect(LevelTestViewModel.estimate([:]) == .a1)
    #expect(LevelTestViewModel.estimate([.a2: (2, 2), .b1: (1, 2), .b2: (0, 2)]) == .b1)
    #expect(LevelTestViewModel.estimate([.a2: (1, 1), .b1: (1, 3)]) == .a2)
    #expect(LevelTestViewModel.step(.c1, by: 1) == .c1)
    #expect(LevelTestViewModel.step(.a1, by: -1) == .a1)
  }

  private func makeSUT() -> LevelTestViewModel {
    LevelTestViewModel(content: LevelContent(), generator: SeededGenerator(seed: 7))
  }
}

/// Her seviyede kelimesi olan sahte içerik (anlamlar `a1-anlam-0` biçiminde).
private struct LevelContent: ContentProviding {
  var wordsPerLevel = 6

  private var words: [Word] {
    CEFRLevel.allCases.flatMap { level in
      (0..<wordsPerLevel).map { index in
        let code = level.rawValue.lowercased()
        return Word(
          id: "w_\(code)_\(index)", en: "\(code)word\(index)", level: level, pos: "noun",
          clue: "ipucu", meaning: "\(code)-anlam-\(index)", ipa: "", example: "")
      }
    }
  }

  func packs() async -> [Pack] {
    CEFRLevel.allCases.enumerated().map { order, level in
      let code = level.rawValue.lowercased()
      return Pack(
        id: code, title: level.rawValue, subtitle: "", kind: .level, level: level, order: order,
        freeCount: 1, productId: nil, puzzleIds: ["p_\(code)"], wordCount: wordsPerLevel)
    }
  }

  func pack(id: String) async -> Pack? { nil }
  func puzzle(id: String) async -> Puzzle? { nil }

  func puzzles(inPack packId: String) async -> [Puzzle] {
    let entries = words.filter { $0.level.rawValue.lowercased() == packId }.map { word in
      PuzzleEntry(
        wordId: word.id, answer: word.en.uppercased(), clue: word.clue, row: 0, col: 1,
        dir: .across, clueRow: 0, clueCol: 0)
    }
    guard let level = CEFRLevel(rawValue: packId.uppercased()) else { return [] }
    return [
      Puzzle(
        id: "p_\(packId)", packId: packId, kind: .pack, level: level, width: 12, height: 1,
        entries: entries)
    ]
  }

  func words(ids: [String]) async -> [Word] {
    let all = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
    return ids.compactMap { all[$0] }
  }

  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
  func refreshFromRemote(entitledPackIds: Set<String>) async {}
}

/// Testlerde tekrarlanabilir karıştırma için basit üreteç (SplitMix64).
private struct SeededGenerator: RandomNumberGenerator {
  var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }
}
