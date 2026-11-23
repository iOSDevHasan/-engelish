import Foundation

/// Gömülü takvimde bulmacası olmayan günler için cihazda "Günün Bulmacası"
/// üreten belirlenimci üretici.
///
/// Tohum gün anahtarından (`yyyy-MM-dd`) türetilir; aynı kelime havuzuyla aynı gün herkes aynı
/// bulmacayı alır, uygulama yeniden açılsa da değişmez. Izgarayı `ReviewPuzzleBuilder` kurar:
/// günün "öne çıkan" kelimeleri tekrar kelimesi gibi önceliklidir, kalan kutular aynı ve komşu
/// seviyedeki kelimelerle dolar. Öne çıkan kelimeler seviyenin kelime listesinde günden güne
/// kayan bir pencereden seçilir; böylece ardışık günler aynı kelimeleri tekrar etmez.
public struct DailyPuzzleBuilder: Sendable {

  // MARK: - Constants

  /// Günlük bulmaca kimliklerinin ön eki (`daily_2027-03-01`).
  public static let idPrefix = "daily_"
  /// Günlük bulmacaya girebilen seviyeler (generate.py'deki günlük havuzla aynı).
  static let levels: Set<CEFRLevel> = [.a1, .a2, .b1]
  /// Günlerin sırayla dönüşümlü aldığı ana seviyeler.
  static let dayLevels: [CEFRLevel] = [.a2, .b1]
  /// Günlük havuzdan çıkarılan sınav etiketleri.
  static let excludedTags: Set<String> = ["yds", "yokdil", "lgs", "ielts", "toefl", "c1"]
  /// Her gün öne çıkan (öncelikli yerleştirilen) kelime sayısı; 6 ve üstü 7×9 ızgarayı seçtirir.
  static let featuredCount = 6
  /// Seviye listelerinin sabit karıştırma tohumu; değişirse tüm günlerin bulmacası değişir.
  static let rotationSeed: UInt64 = 0x00C3_A7E6_6E6C_6973

  // MARK: - Properties

  /// Uygun kelimeler, kimliğe göre sıralı.
  private let pool: [Word]
  /// Ana seviyelerin sabit sırayla karıştırılmış kelimeleri (öne çıkan kelime penceresi).
  private let rotations: [CEFRLevel: [Word]]

  // MARK: - Init

  /// Üreticiyi kelime havuzuyla oluşturur.
  ///
  /// Herkeste aynı sonucu vermesi için uygulamaya gömülü kelimeler verilmelidir (uzaktan inen
  /// kelimeler cihazdan cihaza değişebilir).
  public init(words: [Word]) {
    let eligible = words.filter(Self.isEligible).sorted { $0.id < $1.id }
    var rotations: [CEFRLevel: [Word]] = [:]
    var rng = SeededGenerator(seed: Self.rotationSeed)
    for level in Self.dayLevels {
      rotations[level] = eligible.filter { $0.level == level }.shuffled(using: &rng)
    }
    pool = eligible
    self.rotations = rotations
  }

  // MARK: - Building

  /// Gün anahtarı (`yyyy-MM-dd`) için günlük bulmacayı kurar; anahtar bozuksa ya da havuz
  /// yetersizse nil döner.
  public func build(dayKey: String) -> Puzzle? {
    guard let day = Self.dayNumber(from: dayKey) else { return nil }
    let level = Self.dayLevels[Self.positiveModulo(day, Self.dayLevels.count)]
    let featured = featuredWords(level: level, day: day)
    guard !featured.isEmpty,
      let built = ReviewPuzzleBuilder(seed: Self.seed(for: dayKey))
        .build(dueWords: featured, pool: pool)
    else { return nil }
    return Puzzle(
      id: Self.idPrefix + dayKey, packId: nil, kind: .daily, level: level, width: built.width,
      height: built.height, entries: built.entries)
  }

  /// Seviyenin karışık listesinde güne göre kayan pencereden öne çıkan kelimeler.
  ///
  /// Aynı seviyeli günler (iki günde bir) pencereyi `featuredCount` kadar ilerletir; liste
  /// bitince başa döner.
  func featuredWords(level: CEFRLevel, day: Int) -> [Word] {
    guard let list = rotations[level], !list.isEmpty else { return [] }
    let count = min(Self.featuredCount, list.count)
    let start = Self.positiveModulo((day / Self.dayLevels.count) * count, list.count)
    return (0..<count).map { list[(start + $0) % list.count] }
  }

  // MARK: - Helpers

  /// Kelime günlük bulmacaya uygun mu: seviye uygun, sınav etiketi yok, uzunluk ızgaraya sığar.
  static func isEligible(_ word: Word) -> Bool {
    levels.contains(word.level) && excludedTags.isDisjoint(with: word.tags)
      && ReviewPuzzleBuilder.lengthRange.contains(word.en.count)
  }

  /// Gün anahtarından kararlı tohum (FNV-1a 64); `Hasher` her açılışta değiştiği için
  /// kullanılmaz.
  static func seed(for dayKey: String) -> UInt64 {
    var hash: UInt64 = 0xCBF2_9CE4_8422_2325
    for byte in Array("daily:\(dayKey)".utf8) {
      hash ^= UInt64(byte)
      hash = hash &* 0x0000_0100_0000_01B3
    }
    return hash
  }

  /// `yyyy-MM-dd` anahtarının 1970-01-01'den bu yana gün sayısı (saat diliminden bağımsız).
  static func dayNumber(from dayKey: String) -> Int? {
    let parts = dayKey.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else {
      return nil
    }
    // Howard Hinnant'ın `days_from_civil` algoritması.
    let month = parts[1]
    let year = month <= 2 ? parts[0] - 1 : parts[0]
    let era = (year >= 0 ? year : year - 399) / 400
    let yearOfEra = year - era * 400
    let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + parts[2] - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
  }

  /// Negatif sayılarda da 0..<divisor aralığında kalan.
  private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
    ((value % divisor) + divisor) % divisor
  }
}
