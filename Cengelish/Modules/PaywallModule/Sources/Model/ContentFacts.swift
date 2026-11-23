import ContentKit
import Foundation
import PurchaseKit

/// Bir sınav paketinin paywall'da gösterilen içerik özeti.
struct ExamFacts: Equatable {
  /// Paket başlığı ("YDS Kelime Paketi").
  let packTitle: String
  /// Paket açıklaması.
  let subtitle: String
  /// Bulmaca sayısı.
  let puzzleCount: Int
  /// Kelime sayısı.
  let wordCount: Int
}

/// Paywall metinlerindeki sayılar: içerikteki paket listesinden türetilir.
struct ContentFacts: Equatable {

  // MARK: - Properties

  /// Tüm paketlerdeki bulmaca sayısı.
  let totalPuzzles: Int
  /// Paket sayısı.
  let packCount: Int
  /// Seviye aralığı ("A1–C1").
  let levelSpan: String
  /// Sınav paketlerindeki toplam bulmaca.
  let examPuzzles: Int
  /// Tema paketi sayısı.
  let themeCount: Int
  /// Kilitli bulmacası olan (Plus ile açılan) tema paketlerinin adları.
  let plusThemeTitles: [String]
  /// Plus ile açılan tema paketlerindeki bulmaca sayısı.
  let themePuzzles: Int
  /// Ürün kimliğine göre sınav paketi özetleri.
  let exams: [String: ExamFacts]

  // MARK: - Init

  /// Değerleri doğrudan verir.
  init(
    totalPuzzles: Int, packCount: Int, levelSpan: String, examPuzzles: Int, themeCount: Int,
    plusThemeTitles: [String], themePuzzles: Int, exams: [String: ExamFacts]
  ) {
    self.totalPuzzles = totalPuzzles
    self.packCount = packCount
    self.levelSpan = levelSpan
    self.examPuzzles = examPuzzles
    self.themeCount = themeCount
    self.plusThemeTitles = plusThemeTitles
    self.themePuzzles = themePuzzles
    self.exams = exams
  }

  /// İçerikteki paketlerden özet çıkarır; liste boşsa `nil`.
  init?(packs: [Pack]) {
    guard !packs.isEmpty else { return nil }
    let levels = packs.filter { $0.kind == .level }.map(\.level)
    let themes = packs.filter { $0.kind == .theme }
    let plusThemes = themes.filter { !$0.isFullyFree }
    let examPacks = packs.filter { $0.kind == .exam }
    var exams: [String: ExamFacts] = [:]
    for pack in examPacks {
      guard let productId = pack.productId else { continue }
      exams[productId] = ExamFacts(
        packTitle: pack.title, subtitle: pack.subtitle, puzzleCount: pack.puzzleIds.count,
        wordCount: pack.wordCount)
    }
    let span =
      if let low = levels.min(), let high = levels.max() {
        low == high ? low.rawValue : "\(low.rawValue)–\(high.rawValue)"
      } else {
        Self.fallback.levelSpan
      }
    self.init(
      totalPuzzles: packs.reduce(0) { $0 + $1.puzzleIds.count },
      packCount: packs.count,
      levelSpan: span,
      examPuzzles: examPacks.reduce(0) { $0 + $1.puzzleIds.count },
      themeCount: themes.count,
      plusThemeTitles: plusThemes.map(\.title),
      themePuzzles: plusThemes.reduce(0) { $0 + $1.puzzleIds.count },
      exams: exams)
  }

  // MARK: - Fallback

  /// İçerik henüz okunmadığında gösterilen değerler (gömülü başlangıç içeriğiyle aynı).
  static let fallback = ContentFacts(
    totalPuzzles: 1_250, packCount: 24, levelSpan: "A1–C1", examPuzzles: 300, themeCount: 14,
    plusThemeTitles: [
      "İş", "Futbol", "Doğa", "Teknoloji", "Okul", "Sanat ve Müzik", "Film ve Dizi",
      "Bilim ve Uzay", "Spor",
    ],
    themePuzzles: 450,
    exams: [
      ProductID.packYDS: ExamFacts(
        packTitle: "YDS Kelime Paketi", subtitle: "YDS'de sık çıkan akademik kelimeler",
        puzzleCount: 60, wordCount: 280),
      ProductID.packYOKDIL: ExamFacts(
        packTitle: "YÖKDİL Kelime Paketi", subtitle: "Fen, sağlık ve sosyal bilimler kelimeleri",
        puzzleCount: 60, wordCount: 258),
      ProductID.packLGS: ExamFacts(
        packTitle: "LGS Kelime Paketi", subtitle: "8. sınıf müfredatından kelimeler",
        puzzleCount: 60, wordCount: 291),
      ProductID.packIELTS: ExamFacts(
        packTitle: "IELTS Kelime Paketi", subtitle: "Akademik ve günlük konular",
        puzzleCount: 60, wordCount: 272),
      ProductID.packTOEFL: ExamFacts(
        packTitle: "TOEFL Kelime Paketi", subtitle: "Akademik dersler ve kampüs hayatı",
        puzzleCount: 60, wordCount: 259),
    ])

  /// Sınav paketinin özeti; içerikte yoksa yedek değer.
  func exam(_ productId: String) -> ExamFacts {
    exams[productId] ?? Self.fallback.exams[productId]
      ?? ExamFacts(packTitle: "", subtitle: "", puzzleCount: 60, wordCount: 250)
  }
}
