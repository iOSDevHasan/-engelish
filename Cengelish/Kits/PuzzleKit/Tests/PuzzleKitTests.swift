import ContentKit
import SwiftUI
import Testing
import UIKit

@testable import PuzzleKit

struct PuzzleKitTests {

  private let puzzle = Puzzle(
    id: "t", packId: nil, kind: .daily, level: .a1, width: 6, height: 6,
    entries: [
      PuzzleEntry(
        wordId: "w_house", answer: "HOUSE", clue: "Ev", row: 1, col: 1, dir: .across,
        clueRow: 1, clueCol: 0),
      PuzzleEntry(
        wordId: "w_heron", answer: "HERON", clue: "Balıkçıl", row: 1, col: 1, dir: .down,
        clueRow: 0, clueCol: 1),
    ])

  @Test("Kesişim kutusu iki kelimeye de aittir ve doğru harfi verir")
  func intersection() {
    let layout = CrosswordLayout(puzzle: puzzle)
    let point = GridPoint(row: 1, col: 1)
    #expect(layout.entries(at: point).count == 2)
    #expect(layout.answer(at: point) == "H")
    #expect(layout.entry(at: point, preferring: .down)?.wordId == "w_heron")
  }

  @Test("İpucu kutuları ve bloklar doğru sınıflanır")
  func kinds() {
    let layout = CrosswordLayout(puzzle: puzzle)
    if case .clue = layout.kind(at: GridPoint(row: 1, col: 0)) {
    } else {
      Issue.record("ipucu değil")
    }
    #expect(layout.kind(at: GridPoint(row: 3, col: 3)) == .blank)
  }

  @Test("Tema kimliği bilinmiyorsa Canlı döner; koyu modda Gece'ye geçer")
  func themes() {
    #expect(PuzzleTheme.theme(id: "yok").id == "canli")
    #expect(
      PuzzleTheme.resolve(id: "okyanus", isDark: true, autoNight: true, highContrast: false).id
        == "gece")
  }

  @Test("Koyu görünümü olan temalar koyu modda Gece'ye geçmez")
  func darkReadyThemesStay() {
    for id in ["canli", "neon", "orman", "karatahta"] {
      #expect(
        PuzzleTheme.resolve(id: id, isDark: true, autoNight: true, highContrast: false).id == id)
    }
  }
}

// MARK: - Theme catalog

struct PuzzleThemeCatalogTests {

  /// Kayıtlı ayarlarda saklanan, değişmemesi gereken eski tema kimlikleri.
  private let legacyIds = ["canli", "kagit", "gece", "okyanus", "pastel", "kareli"]

  /// Sonradan eklenen Çengelish Plus temaları.
  private let plusIds = [
    "orman", "gunbatimi", "sepya", "gecemavisi", "karatahta", "neon", "lavanta", "kahve", "buzul",
    "altin",
  ]

  /// Sonradan eklenen ücretsiz temalar.
  private let newFreeIds = ["nane", "limonata"]

  @Test("Tema kimlikleri ve adları benzersiz, eski kimlikler korunuyor")
  func uniqueIds() {
    let ids = PuzzleTheme.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(Set(PuzzleTheme.all.map(\.name)).count == ids.count)
    for id in legacyIds + plusIds + newFreeIds {
      #expect(PuzzleTheme.theme(id: id).id == id)
    }
  }

  @Test("Ücretsiz ve Plus temaları doğru işaretli")
  func plusFlags() {
    let free = PuzzleTheme.all.filter { !$0.isPremium }.map(\.id)
    #expect(free == ["canli", "kagit", "gece", "okyanus", "nane", "limonata"])
    // Ücretsiz temalar listenin başında durur.
    #expect(Array(PuzzleTheme.all.prefix(free.count).map(\.id)) == free)
    for id in plusIds {
      #expect(PuzzleTheme.theme(id: id).isPremium)
    }
  }

  @Test("Her temada kalem ve ipucu yazısı açık ve koyu modda okunur", arguments: PuzzleTheme.all)
  func legibility(theme: PuzzleTheme) {
    for style in [UIUserInterfaceStyle.light, .dark] {
      let ratio = ContrastProbe(style: style)
      #expect(ratio(theme.pen, theme.cell) >= 4.5, "\(theme.id) kalem/kutu \(style.rawValue)")
      #expect(ratio(theme.pen, theme.highlight) >= 4.5, "\(theme.id) kalem/vurgu")
      #expect(ratio(theme.pen, theme.active) >= 4.5, "\(theme.id) kalem/etkin kutu")
      #expect(ratio(theme.clueInk, theme.clue) >= 4.5, "\(theme.id) ipucu yazısı")
    }
  }

  @Test("Yeni temalarda ok, anahtar, çizgi ve ipucu kutusu ayırt edilir")
  func plusThemeDetails() {
    for theme in PuzzleTheme.all where (plusIds + newFreeIds).contains(theme.id) {
      #expect(theme.keepsInDarkMode)
      for style in [UIUserInterfaceStyle.light, .dark] {
        let ratio = ContrastProbe(style: style)
        #expect(ratio(theme.arrow, theme.clue) >= 3, "\(theme.id) ok")
        #expect(ratio(theme.keyInk, theme.cell) >= 3, "\(theme.id) anahtar")
        #expect(ratio(theme.line, theme.cell) >= 1.4, "\(theme.id) çizgi")
        #expect(ratio(theme.clue, theme.cell) >= 1.1, "\(theme.id) ipucu kutusu")
        if let ring = theme.activeRing {
          #expect(ratio(ring, theme.cell) >= 3, "\(theme.id) etkin çerçeve")
        }
      }
    }
  }
}

/// İki rengin verilen görünüm modundaki WCAG kontrast oranını hesaplar.
private struct ContrastProbe {
  let style: UIUserInterfaceStyle

  func callAsFunction(_ first: Color, _ second: Color) -> Double {
    let a = luminance(first)
    let b = luminance(second)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }

  /// Rengin göreli parlaklığı (sRGB).
  private func luminance(_ color: Color) -> Double {
    let traits = UITraitCollection(userInterfaceStyle: style)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).resolvedColor(with: traits).getRed(
      &red, green: &green, blue: &blue, alpha: &alpha)
    func linear(_ value: CGFloat) -> Double {
      let v = Double(value)
      return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }
}
