import Combine
import CoreGraphics
import DesignKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import UserDataKit

@Suite("Profil fotoğrafı ve tüm verileri silme")
@MainActor
struct ProfilePhotoAndEraseTests {

  // MARK: - Photo

  @Test("Büyük fotoğraf 512 px'e küçültülüp JPEG olarak profille saklanır")
  func photoIsDownsampled() async throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let raw = try Self.png(width: 2_000, height: 1_000)
    let prepared = try #require(await ProfilePhoto.normalized(raw))
    #expect(ProfilePhoto.isNormalized(prepared))
    #expect(store.setProfilePhoto(prepared))
    let saved = try #require(store.profilePhoto)
    let size = try Self.pixelSize(saved)
    #expect(max(size.width, size.height) == ProfilePhoto.maxPixelSize)
    #expect(size.width == 512 && size.height == 256)
    #expect(Self.type(saved) == UTType.jpeg.identifier)
  }

  @Test("Hazırlanmamış veri kaydederken küçültülür, okunamayan veri reddedilir")
  func photoIsValidated() throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    #expect(store.setProfilePhoto(try Self.png(width: 900, height: 1_200)))
    let size = try Self.pixelSize(try #require(store.profilePhoto))
    #expect(size.height == 512)
    #expect(!store.setProfilePhoto(Data("foto değil".utf8)))
    #expect(store.profilePhoto != nil)
  }

  @Test("Fotoğraf kaldırılabilir; profil güncellemesi fotoğrafa dokunmaz")
  func photoRemoval() throws {
    let store = UserDataStore(inMemory: true)
    #expect(!store.setProfilePhoto(try Self.png(width: 10, height: 10)))
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    store.setProfilePhoto(try Self.png(width: 10, height: 10))
    var profile = try #require(store.profile)
    profile.nickname = "Ada"
    store.updateProfile(profile)
    #expect(store.profilePhoto != nil)
    store.setProfilePhoto(nil)
    #expect(store.profilePhoto == nil)
    #expect(store.profile?.nickname == "Ada")
  }

  // MARK: - Erase

  @Test("Tüm verileri sil: profil, fotoğraf, ayarlar, ilerleme, harfler, defter, seri ve rozet")
  func deleteAllErasesEverything() throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig(), level: "B1"))
    store.setProfilePhoto(try Self.png(width: 40, height: 40))
    store.updateSettings { $0.puzzleTheme = "gece" }
    store.saveDraft(puzzleId: "a1_02", drawing: Data([1, 2, 3]), durationSec: 30)
    store.saveTyped(puzzleId: "a1_03", letters: ["1,1": "A"])
    store.saveRevealed(puzzleId: "a1_03", cells: ["1,2"], hintsUsed: 1)
    _ = store.consumeHints(1, isPremium: false)
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": false], wordIdsByEntry: ["e1": "w_racer"],
      isPremium: false, now: .now)
    #expect(!store.badges.isEmpty)

    store.deleteAll()

    #expect(store.profile == nil)
    #expect(store.profilePhoto == nil)
    #expect(store.settings == AppSettings())
    #expect(store.allProgress().isEmpty)
    #expect(store.progress(for: "a1_03").typedLetters.isEmpty)
    #expect(store.progress(for: "a1_02").drawing == nil)
    #expect(store.notebook.isEmpty)
    #expect(store.stats == UserStats())
    #expect(store.badges.isEmpty)
    #expect(store.hintsLeft(isPremium: false) == 3)
  }

  @Test("Silme önce dataErased, ardından changes yayınlar")
  func deleteAllPublishesErase() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    var events: [String] = []
    var cancellables: Set<AnyCancellable> = []
    store.dataErased.sink { events.append("erased") }.store(in: &cancellables)
    store.changes.sink { events.append("changed") }.store(in: &cancellables)
    store.updateSettings { $0.leftHanded = true }
    #expect(events == ["changed"])
    store.deleteAll()
    #expect(events == ["changed", "erased", "changed"])
    #expect(store.profile == nil)
  }

  // MARK: - Helpers

  /// Verilen boyutta düz renkli PNG üretir.
  private static func png(width: Int, height: Int) throws -> Data {
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())
    let output = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return output as Data
  }

  /// Görüntünün piksel boyutu.
  private static func pixelSize(_ data: Data) throws -> (width: Int, height: Int) {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let properties = try #require(
      CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
    let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)
    return (width, height)
  }

  /// Görüntünün tür kimliği.
  private static func type(_ data: Data) -> String? {
    CGImageSourceCreateWithData(data as CFData, nil).flatMap(CGImageSourceGetType) as String?
  }
}
