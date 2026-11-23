import Foundation

/// Uygulamanın içerik okuma arayüzü; modüller sadece buna bağlıdır.
public protocol ContentProviding: Sendable {
  /// Tüm paketler, sıralı.
  func packs() async -> [Pack]
  /// Kimliği verilen paket.
  func pack(id: String) async -> Pack?
  /// Kimliği verilen bulmaca.
  func puzzle(id: String) async -> Puzzle?
  /// Paketin bulmacaları, paketteki sırayla.
  func puzzles(inPack packId: String) async -> [Puzzle]
  /// Kimlikleri verilen kelimeler (bulunamayanlar atlanır).
  func words(ids: [String]) async -> [Word]
  /// Verilen günün bulmacası.
  func dailyPuzzle(for date: Date) async -> Puzzle?
  /// Cihazdaki tüm kelimeler (elle ekleme araması ve tekrar bulmacası dolgusu için).
  func wordPool() async -> [Word]
  /// Cihazda üretilen geçici bulmacayı (ör. tekrar bulmacası) bellekte kaydeder; böylece
  /// `puzzle(id:)` ve `words(ids:)` onu da bulur. Uygulama kapanınca silinir.
  func registerTransient(_ puzzle: Puzzle, words: [Word]) async
}

extension ContentProviding {
  /// Varsayılan: kelime havuzu yok.
  public func wordPool() async -> [Word] { [] }

  /// Varsayılan: geçici bulmaca desteklenmez.
  public func registerTransient(_ puzzle: Puzzle, words: [Word]) async {}

  /// Geçici bulmacayı ek kelime olmadan kaydeder (kelimeler zaten havuzdaysa).
  public func registerTransient(_ puzzle: Puzzle) async {
    await registerTransient(puzzle, words: [])
  }
}

/// İçerik katmanı hataları.
public enum ContentError: Error, Equatable {
  /// Gömülü başlangıç içeriği bulunamadı ya da bozuk.
  case missingStarterContent
}
