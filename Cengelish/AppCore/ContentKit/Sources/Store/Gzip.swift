import Foundation

/// Gzip (RFC 1952) dosyalarını açar. Paket dosyaları Storage'da `.json.gz` olarak durur.
public enum Gzip {

  /// Gzip hataları.
  public enum Failure: Error {
    /// Dosya gzip biçiminde değil.
    case invalidHeader
    /// Sıkıştırılmış veri açılamadı.
    case corrupted
  }

  /// Gzip verisini açar.
  public static func decompress(_ data: Data) throws -> Data {
    let bytes = [UInt8](data)
    guard bytes.count > 18, bytes[0] == 0x1F, bytes[1] == 0x8B, bytes[2] == 8 else {
      throw Failure.invalidHeader
    }
    let flags = bytes[3]
    var index = 10
    if flags & 0x04 != 0 {
      // FEXTRA: 2 baytlık uzunluk + veri.
      guard index + 2 <= bytes.count else { throw Failure.invalidHeader }
      index += 2 + Int(bytes[index]) + Int(bytes[index + 1]) << 8
    }
    if flags & 0x08 != 0 { index = skipZeroTerminated(bytes, from: index) }
    if flags & 0x10 != 0 { index = skipZeroTerminated(bytes, from: index) }
    if flags & 0x02 != 0 { index += 2 }
    guard index < bytes.count - 8 else { throw Failure.invalidHeader }
    let deflated = Data(bytes[index..<(bytes.count - 8)])
    // `.zlib` Apple'da ham DEFLATE (RFC 1951) demektir; gzip başlığı ve sonu ayrıldı.
    guard let inflated = try? (deflated as NSData).decompressed(using: .zlib) else {
      throw Failure.corrupted
    }
    return inflated as Data
  }

  /// Sıfırla biten alanı (dosya adı, yorum) atlar.
  private static func skipZeroTerminated(_ bytes: [UInt8], from start: Int) -> Int {
    var index = start
    while index < bytes.count, bytes[index] != 0 { index += 1 }
    return index + 1
  }
}
