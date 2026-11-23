import SwiftUI
import UIKit

/// Kullanıcının yuvarlak avatarı: profil fotoğrafı varsa o, yoksa Kalemo maskotu.
///
/// Profil ve Ana Sayfa aynı görünümü kullanır.
public struct UserAvatarView: View {
  private let photo: UIImage?
  private let avatar: AvatarConfig
  private let size: CGFloat

  /// Fotoğraf (isteğe bağlı), maskot seçimi ve çapla oluşturur.
  public init(photo: UIImage?, avatar: AvatarConfig, size: CGFloat) {
    self.photo = photo
    self.avatar = avatar
    self.size = size
  }

  public var body: some View {
    if let photo {
      Image(uiImage: photo)
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .background(Circle().fill(avatar.background.color))
        .clipShape(Circle())
        .accessibilityLabel("Profil fotoğrafı")
    } else {
      AvatarView(avatar, size: size)
    }
  }
}
