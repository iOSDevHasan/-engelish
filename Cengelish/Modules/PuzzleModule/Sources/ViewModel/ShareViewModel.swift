import DesignKit
import Foundation
import Photos
import PuzzleKit
import SwiftUI
import UIKit

/// Paylaşım kartında gösterilen sonuç (cevaplar yoktur).
struct ShareCard {
  /// Izgara düzeni (kutular sadece dolu olarak çizilir).
  let layout: CrosswordLayout
  /// Bulmaca başlığı.
  let title: String
  /// "Ad · Seviye" satırı.
  let owner: String
  /// Kullanıcının avatarı.
  let avatar: AvatarConfig
  /// Bitiş tarihi.
  let date: Date
  /// Kelime sırasına göre doğru (`true`) / yanlış sonuçlar.
  let results: [Bool]
  /// Süre metni.
  let duration: String
  /// Doğru kelime sayısı.
  let correct: Int
  /// Toplam kelime sayısı.
  let total: Int
  /// Güncel seri.
  let streak: Int
}

/// Fotoğraflara kaydetme sonucu.
enum PhotoSaveOutcome: Equatable, Sendable {
  case saved
  case denied
  case failed
}

/// Resmi fotoğraf arşivine kaydeden servis (testlerde sahtesi verilir).
protocol PhotoSaving: Sendable {
  /// PNG verisini fotoğraflara ekler.
  func save(_ data: Data) async -> PhotoSaveOutcome
}

/// `PHPhotoLibrary` ile sadece ekleme izniyle kaydeder.
///
/// Info.plist'te `NSPhotoLibraryAddUsageDescription` yoksa izin istemek uygulamayı kapatacağı için
/// hiç denemeden `.failed` döner.
struct PhotoLibrarySaver: PhotoSaving {
  /// Kaydeder.
  func save(_ data: Data) async -> PhotoSaveOutcome {
    guard Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") != nil
    else { return .failed }
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else { return .denied }
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
      }
      return .saved
    } catch {
      return .failed
    }
  }
}

/// Paylaş ekranı: kart, hikâye görseli, mesaj, kaydet ve bağlantı.
@MainActor
final class ShareViewModel: ObservableObject {

  // MARK: - Published state

  /// 9:16 hikâye görseli.
  @Published private(set) var storyImage: UIImage?
  /// Mesajla paylaşılan kart görseli.
  @Published private(set) var cardImage: UIImage?
  /// Kısa bildirim (kopyalandı, kaydedildi…).
  @Published private(set) var notice: String?
  /// Kaydetme sürüyor mu.
  @Published private(set) var isSaving = false

  // MARK: - Properties

  /// Kart verisi.
  let card: ShareCard
  private let coordinator: PuzzleCoordinator?
  private let photoSaver: any PhotoSaving
  private var noticeTask: Task<Void, Never>?

  // MARK: - Init

  init(card: ShareCard, coordinator: PuzzleCoordinator?, photoSaver: any PhotoSaving) {
    self.card = card
    self.coordinator = coordinator
    self.photoSaver = photoSaver
  }

  // MARK: - Derived

  /// Mesajla gönderilen metin.
  var messageText: String { ShareText.message }

  // MARK: - Intents

  /// Kart ve hikâye görsellerini hazırlar.
  func prepare() {
    guard storyImage == nil else { return }
    cardImage = render(ShareCardView(card: card).padding(16).background(Palette.background))
    storyImage = render(ShareStoryView(card: card))
  }

  /// Bağlantıyı panoya kopyalar.
  func copyLink(to pasteboard: UIPasteboard = .general) {
    pasteboard.string = ShareText.link
    show("Bağlantı kopyalandı")
  }

  /// Hikâye görselini fotoğraflara kaydeder.
  func saveToPhotos() async {
    guard !isSaving, let data = storyImage?.pngData() else { return }
    isSaving = true
    let outcome = await photoSaver.save(data)
    isSaving = false
    switch outcome {
    case .saved: show("Fotoğraflara kaydedildi")
    case .denied: show("Fotoğraflara izin yok · Ayarlar'dan açabilirsin")
    case .failed: show("Kaydedilemedi, tekrar dene")
    }
  }

  /// Paylaş ekranını kapatır.
  func close() {
    coordinator?.back()
  }

  // MARK: - Private

  private func render(_ view: some View) -> UIImage? {
    let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
    renderer.scale = 3
    return renderer.uiImage
  }

  private func show(_ text: String) {
    noticeTask?.cancel()
    notice = text
    AccessibilityNotification.Announcement(text).post()
    noticeTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      self?.notice = nil
    }
  }
}
