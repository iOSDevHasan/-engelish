import Foundation

/// Tohumla başlatılan, her çalıştırmada aynı diziyi üreten rastgele sayı üreteci (SplitMix64).
///
/// Tekrar bulmacası testlerde tohumla belirlenebilir olsun diye kullanılır.
public struct SeededGenerator: RandomNumberGenerator, Sendable {

  // MARK: - Properties

  private var state: UInt64

  // MARK: - Init

  /// Üreteci verilen tohumla oluşturur.
  public init(seed: UInt64) {
    state = seed
  }

  // MARK: - RandomNumberGenerator

  public mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }

  /// 0..<1 aralığında bir ondalık sayı.
  mutating func nextUnit() -> Double {
    Double(next() >> 11) / Double(UInt64(1) << 53)
  }
}
