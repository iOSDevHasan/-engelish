import DesignKit
import Foundation
import PurchaseKit
import PuzzleKit
import UserDataKit

/// Paywall'daki avantaj listeleri ve sınav bilgileri. Her madde uygulamadaki gerçek bir
/// Çengelish Plus kuralına dayanır (ipucu, seri dondurma, tema, avatar, paket kilidi).
enum PaywallCatalog {

  // MARK: - Plus

  /// Çengelish Plus avantajları (tam liste), değer sırasıyla. Yalnızca uygulamada gerçekten Plus'a
  /// bağlı kurallar yazılır: seviye paketleri ve çevrimdışı oyun herkese açık olduğu için yoktur.
  /// Tema paketi maddesinin alt satırı; çok tema varsa ilk dördü ve kalan sayısı yazılır.
  static func themeDetail(_ names: [String]) -> String {
    guard !names.isEmpty else { return "Tema paketlerinin tüm bulmacaları" }
    guard names.count > 5 else { return "\(list(names)) konularında kelimeler" }
    return "\(names.prefix(4).joined(separator: ", ")) ve \(names.count - 4) konu daha"
  }

  static func plusBenefits(facts: ContentFacts) -> [Benefit] {
    let examNames = ProductID.examPacks.compactMap(ProductID.examTitle(for:))
    let themeNames = facts.plusThemeTitles
    let premiumThemes = PuzzleTheme.all.filter(\.isPremium).map(\.name)
    return [
      Benefit(
        id: "plus.exams", systemImage: "graduationcap.fill",
        title: "\(examNames.count) sınav paketi · \(facts.examPuzzles) bulmaca",
        detail: "\(list(examNames)); tek tek satın almana gerek kalmaz", isIncluded: true),
      Benefit(
        id: "plus.themes", systemImage: "square.stack.3d.up.fill",
        title: themeNames.isEmpty
          ? "Tüm tema paketleri"
          : "\(themeNames.count) tema paketi · \(facts.themePuzzles) bulmaca",
        detail: themeDetail(themeNames),
        isIncluded: true),
      Benefit(
        id: "plus.hints", systemImage: "lightbulb.fill", title: "Sınırsız ipucu",
        detail: "Ücretsiz planda günde \(HintRules.freeDailyHints) ipucu; Plus'ta istediğin kadar",
        isIncluded: true),
      Benefit(
        id: "plus.review", systemImage: "arrow.triangle.2.circlepath",
        title: "Defterinden tekrar bulmacası",
        detail: "Zorlandığın kelimelerden sana özel bulmaca", isIncluded: true),
      Benefit(
        id: "plus.freeze", systemImage: "snowflake",
        title: "Ayda \(StreakRules.monthlyFreezes) seri dondurma",
        detail: "Bir gün kaçırsan da serin bozulmaz", isIncluded: true),
      Benefit(
        id: "plus.puzzleThemes", systemImage: "paintpalette.fill",
        title: premiumThemes.isEmpty
          ? "Tüm bulmaca temaları" : "\(premiumThemes.count) özel bulmaca teması",
        detail: themeExamples(premiumThemes), isIncluded: true),
      Benefit(
        id: "plus.future", systemImage: "gift.fill", title: "Yeni paketler dahil",
        detail: "Eklenen her sınav ve tema paketi ek ücret olmadan açılır", isIncluded: true),
      Benefit(
        id: "plus.badge", systemImage: "checkmark.seal.fill", title: "Profilinde Plus rozeti",
        detail: "Profil kartında altın rozetle görünür", isIncluded: true),
    ]
  }

  // MARK: - Exam packs

  /// Sınav paketinin içeriği ve Plus'a göre eksikleri.
  static func packBenefits(for productId: String, facts: ContentFacts) -> [Benefit] {
    let exam = ProductID.examTitle(for: productId) ?? "Sınav"
    let info = facts.exam(productId)
    let others = ProductID.examPacks.filter { $0 != productId }
      .compactMap(ProductID.examTitle(for:))
    return [
      Benefit(
        id: "pack.puzzles", systemImage: "square.grid.3x3.fill",
        title: "\(info.puzzleCount) \(exam) bulmacası",
        detail: "Paketin tüm bulmacaları kilitsiz", isIncluded: true),
      Benefit(
        id: "pack.words", systemImage: "textformat.abc", title: "\(info.wordCount) kelime",
        detail: info.subtitle.isEmpty ? "\(exam) kelimeleri" : info.subtitle, isIncluded: true),
      Benefit(
        id: "pack.level", systemImage: "chart.bar.fill",
        title: "Seviye \(levelRange(for: productId))",
        detail: "\(exam) sınavının kelime düzeyine göre", isIncluded: true),
      Benefit(
        id: "pack.lifetime", systemImage: "infinity", title: "Tek seferlik, ömür boyu",
        detail: "Abonelik yok; Apple Kimliğinle diğer cihazlarına da geri yüklenir",
        isIncluded: true),
      Benefit(
        id: "pack.noExams", systemImage: "graduationcap.fill", title: "Diğer sınav paketleri",
        detail: "\(list(others)) yalnızca Plus'ta", isIncluded: false),
      Benefit(
        id: "pack.noThemes", systemImage: "square.stack.3d.up.fill",
        title: "Plus tema paketleri",
        detail: facts.plusThemeTitles.isEmpty
          ? "Kilitli tema bulmacaları" : list(facts.plusThemeTitles), isIncluded: false),
      Benefit(
        id: "pack.noHints", systemImage: "lightbulb.fill",
        title: "Sınırsız ipucu ve seri dondurma",
        detail: "Ücretsiz planda günde \(HintRules.freeDailyHints) ipucu", isIncluded: false),
      Benefit(
        id: "pack.noExtras", systemImage: "paintpalette.fill",
        title: "Tekrar bulmacası ve özel temalar",
        detail: "Plus'a özel ekstralar", isIncluded: false),
    ]
  }

  /// Sınavın kelime seviye aralığı (Keşfet'teki paket kartlarıyla aynı).
  static func levelRange(for productId: String) -> String {
    switch productId {
    case ProductID.packYDS, ProductID.packYOKDIL: "B2–C1"
    case ProductID.packLGS: "A2–B1"
    default: "B1–C1"
    }
  }

  // MARK: - Helpers

  /// Plus bulmaca temalarından en fazla üç örnek ("Gece, Okyanus, Orman ve daha fazlası").
  static func themeExamples(_ names: [String]) -> String {
    guard !names.isEmpty else { return "Izgaran için tüm renk temaları" }
    guard names.count > 3 else { return "\(list(names)) temaları dahil" }
    return names.prefix(3).joined(separator: ", ") + " ve daha fazlası"
  }

  /// Türkçe liste yazar: "A, B ve C".
  static func list(_ items: [String]) -> String {
    guard let last = items.last else { return "" }
    guard items.count > 1 else { return last }
    return items.dropLast().joined(separator: ", ") + " ve " + last
  }
}
