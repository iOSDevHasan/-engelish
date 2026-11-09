import Foundation

/// CEFR dil seviyesi.
public enum CEFRLevel: String, Codable, CaseIterable, Comparable, Sendable {
  case a1 = "A1"
  case a2 = "A2"
  case b1 = "B1"
  case b2 = "B2"
  case c1 = "C1"

  /// Seviyenin Türkçe adı.
  public var title: String {
    switch self {
    case .a1: "Başlangıç"
    case .a2: "Temel"
    case .b1: "Orta"
    case .b2: "İleri-orta"
    case .c1: "İleri"
    }
  }

  /// Seviyede işlenen konular.
  public var topics: String {
    switch self {
    case .a1: "Renkler, sayılar, aile"
    case .a2: "Günlük hayat, alışveriş"
    case .b1: "İş, seyahat, duygular"
    case .b2: "Sınav kelimeleri, soyut kavramlar"
    case .c1: "Akademik ve nadir kelimeler"
    }
  }

  public static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
    allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
  }
}

/// Soru havuzundaki bir İngilizce kelime ve Türkçe ipucu.
public struct Word: Codable, Identifiable, Hashable, Sendable {
  /// Kelime kimliği (`w_house`).
  public let id: String
  /// İngilizce kelime.
  public let en: String
  /// Seviye.
  public let level: CEFRLevel
  /// Sözcük türü (noun, verb...).
  public let pos: String
  /// Bulmacadaki kısa Türkçe ipucu.
  public let clue: String
  /// Bitiş ekranında gösterilen Türkçe anlam.
  public let meaning: String
  /// Amerikan telaffuz (IPA).
  public let ipa: String
  /// İngilizce örnek cümle.
  public let example: String
  /// Sınav ve tema etiketleri.
  public let tags: [String]

  /// Kelimeyi tüm alanlarıyla oluşturur.
  public init(
    id: String, en: String, level: CEFRLevel, pos: String, clue: String, meaning: String,
    ipa: String, example: String, tags: [String] = []
  ) {
    self.id = id
    self.en = en
    self.level = level
    self.pos = pos
    self.clue = clue
    self.meaning = meaning
    self.ipa = ipa
    self.example = example
    self.tags = tags
  }

  /// Sözcük türünün Türkçe kısaltması.
  public var posTitle: String {
    switch pos {
    case "noun": "isim"
    case "verb": "fiil"
    case "adj": "sıfat"
    case "num": "sayı"
    default: pos
    }
  }
}
