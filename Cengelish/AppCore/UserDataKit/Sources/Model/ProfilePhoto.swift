import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Profil fotoğrafını saklamaya hazırlar: en uzun kenarı küçültür ve JPEG'e çevirir.
///
/// Fotoğraf seçiciden gelen ham veri (HEIC, PNG, JPEG...) `normalized(_:)` ile ana iş parçacığı
/// dışında hazırlanır; `UserDataStoring.setProfilePhoto(_:)` gelen veriyi yine de denetler.
public enum ProfilePhoto {

  /// Saklanan fotoğrafın en uzun kenarı (piksel).
  public static let maxPixelSize = 512
  /// JPEG sıkıştırma kalitesi.
  public static let compressionQuality = 0.8

  /// Ham görüntüyü arka planda küçültüp JPEG'e çevirir; okunamazsa nil döner.
  @concurrent
  public static func normalized(_ data: Data) async -> Data? {
    normalize(data)
  }

  /// Ham görüntüyü küçültüp JPEG'e çevirir (EXIF yönü uygulanır); okunamazsa nil döner.
  nonisolated static func normalize(_ data: Data) -> Data? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
      CGImageSourceGetCount(source) > 0
    else { return nil }
    let thumbnailOptions =
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
      ] as CFDictionary
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
      return nil
    }
    return jpeg(image)
  }

  /// Veri zaten saklanmaya hazır mı: JPEG ve en uzun kenarı sınırın içinde.
  nonisolated static func isNormalized(_ data: Data) -> Bool {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int
    else { return false }
    return max(width, height) <= maxPixelSize
  }

  /// Görüntüyü JPEG verisine çevirir.
  private nonisolated static func jpeg(_ image: CGImage) -> Data? {
    let output = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        output, UTType.jpeg.identifier as CFString, 1, nil)
    else { return nil }
    let options = [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary
    CGImageDestinationAddImage(destination, image, options)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return output as Data
  }
}
