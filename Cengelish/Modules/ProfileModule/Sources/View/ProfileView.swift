import DesignKit
import SwiftUI
import UserDataKit

/// Profil sekmesi: kimlik kartı (sayaçlarla), İngilizce seviyesi ve tüm rozetler.
struct ProfileView: View {
  @StateObject var viewModel: ProfileViewModel
  @State private var isEditing = false

  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        header
        identityCard.appearAnimation(index: 0)
        level.appearAnimation(index: 1)
        badgeSection.appearAnimation(index: 2)
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 32)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
      // Rozet balonu komşu kartların üstüne taşar; tamamı dokunulabilir kalsın diye burada çizilir.
      .badgeTooltipHost()
    }
    .scrollIndicators(.hidden)
    .coordinateSpace(name: Self.space)
    .statusBarScrim()
    .screenBackground()
    .appBottomSheet(isPresented: $isEditing) { EditProfileSheet(viewModel: viewModel) }
  }

  /// Rozet balonlarının yönünü ölçmek için kaydırma alanının adı.
  private static let space = "profileScroll"
  /// Kimlik kartının üstündeki renkli kapağın yüksekliği.
  private static let coverHeight: CGFloat = 92
  /// Avatar boyutu.
  private static let avatarSize: CGFloat = 96
  /// Avatarın kapağın içine taştığı yükseklik.
  private static let avatarOverlap: CGFloat = 52

  // MARK: - Header

  private var header: some View {
    HStack(spacing: 10) {
      Text("Profil").font(AppFont.rounded(28, weight: .black)).foregroundStyle(Palette.ink)
      Spacer()
      Button(action: viewModel.openSettings) { IconCircle("gearshape.fill") }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Ayarlar")
    }
    .frame(minHeight: 44)
  }

  // MARK: - Identity card

  /// Kapak, ortada kalemli avatar, ad, unvan ve seviye, üyelik tarihi ve sayaçlar.
  private var identityCard: some View {
    VStack(spacing: 0) {
      cover
      VStack(spacing: 8) {
        editableAvatar
          .padding(.top, -Self.avatarOverlap)
        Text(viewModel.profile.displayName)
          .font(AppFont.rounded(24, weight: .black))
          .foregroundStyle(Palette.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        HStack(spacing: 6) {
          Pill(viewModel.title.title, systemImage: "trophy.fill", tone: .accent)
          Pill(viewModel.profile.level)
        }
        Text(viewModel.memberSinceText)
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 14)
      Rectangle().fill(Palette.line).frame(height: 1)
      statsRow
    }
    .background(Palette.surface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(Palette.cardBorder, lineWidth: 1)
    )
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
        .shadow(color: Color.black.opacity(0.06), radius: 14, y: 10)
    )
  }

  /// Avatarın arka plan rengindeki kapak; köşede Plus rozeti, zeminde soluk bulmaca kareleri.
  private var cover: some View {
    ProfileCover.gradient(viewModel.profile.avatar.background)
      .frame(height: Self.coverHeight)
      .overlay(alignment: .trailing) {
        ProfileCoverPattern()
          .padding(.trailing, 14)
          .accessibilityHidden(true)
      }
      .overlay(alignment: .topLeading) {
        if viewModel.isPremium {
          PlusBadge(compact: true).padding(12)
        }
      }
  }

  /// Sağ altında kalem düğmesi olan avatar; dokununca düzenleme paneli açılır.
  private var editableAvatar: some View {
    Button(action: startEditing) {
      UserAvatarView(
        photo: viewModel.photo, avatar: viewModel.profile.avatar, size: Self.avatarSize
      )
      .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 4))
      .overlay(alignment: .bottomTrailing) {
        Image(systemName: "pencil")
          .font(.system(size: 12, weight: .black))
          .foregroundStyle(.white)
          .frame(width: 30, height: 30)
          .background(Circle().fill(Palette.buttonFill))
          .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
          .offset(x: 1, y: 1)
      }
    }
    .buttonStyle(PressScaleButtonStyle())
    .accessibilityLabel("Profili düzenle")
    .accessibilityHint("Fotoğrafını ve takma adını değiştir")
  }

  /// Taslağı hazırlayıp düzenleme panelini açar.
  private func startEditing() {
    viewModel.beginEditing()
    isEditing = true
  }

  // MARK: - Stats

  private var statsRow: some View {
    HStack(spacing: 0) {
      stat("flame.fill", Palette.streak, viewModel.stats.streak, "gün seri")
      divider
      stat("square.grid.3x3.fill", Palette.accent, viewModel.stats.puzzlesSolved, "bulmaca")
      divider
      stat("book.fill", Palette.good, viewModel.stats.wordsSeen, "kelime")
      divider
      stat("medal.fill", BadgeColors.sealDark, viewModel.badges.count, "rozet")
    }
    .padding(.vertical, 12)
  }

  private var divider: some View {
    Rectangle().fill(Palette.line).frame(width: 1, height: 34)
  }

  private func stat(_ icon: String, _ tint: Color, _ value: Int, _ label: String) -> some View {
    VStack(spacing: 3) {
      HStack(spacing: 4) {
        Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(tint)
        Text("\(value)")
          .font(AppFont.rounded(18, weight: .black))
          .foregroundStyle(Palette.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .contentTransition(.numericText(value: Double(value)))
      }
      Text(label).font(AppFont.rounded(11, weight: .heavy)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Badges

  /// Tüm rozetler: kazanılan sayısı, ilerleme çubuğu ve madalya ızgarası (dokununca balon).
  private var badgeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("Rozetler")
          .font(AppFont.bodyBold)
          .foregroundStyle(Palette.ink)
          .accessibilityAddTraits(.isHeader)
        Spacer()
        Pill(viewModel.badgeCountText, tone: .accent)
          .contentTransition(.numericText(value: viewModel.badgeProgress))
      }
      ProgressBar(value: viewModel.badgeProgress, tint: BadgeColors.sealDark)
        .accessibilityHidden(true)
      Text(
        viewModel.badges.isEmpty
          ? "İlk bulmacanı bitirince ilk rozetin parlar. Dokun, nasıl kazanılacağını gör."
          : "Bir rozete dokun: anlamını, nasıl kazanıldığını ve ilerlemeni gör."
      )
      .font(AppFont.tiny)
      .foregroundStyle(Palette.muted)
      .fixedSize(horizontal: false, vertical: true)
      BadgeGrid(
        items: viewModel.badgeItems, space: Self.space, medalSize: 76,
        dateText: viewModel.dateText
      )
      .padding(.top, 8)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 14)
    .card(padding: 0)
  }

  // MARK: - Level

  /// İngilizce seviyesi: seviye renginde kabartmalı rozet, sonraki seviyeye kalan ve çubuk.
  private var level: some View {
    let progress = viewModel.levelProgress
    let code = progress.code
    return HStack(spacing: 14) {
      Text(code)
        .font(AppFont.rounded(20, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 56, height: 52)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(LevelTint.color(code: code))
            .shadow(color: LevelTint.ledge(code: code), radius: 0, y: 4)
        )
        .padding(.bottom, 4)
      VStack(alignment: .leading, spacing: 7) {
        Text("İngilizce seviyen")
          .font(AppFont.rounded(11, weight: .heavy))
          .foregroundStyle(Palette.muted)
        HStack(alignment: .firstTextBaseline) {
          Text(progress.headline).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Spacer(minLength: 8)
          Text(progress.detail)
            .font(AppFont.caption)
            .foregroundStyle(Palette.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        ProgressBar(value: progress.fraction, tint: LevelTint.color(code: code))
      }
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .card(padding: 0)
    .accessibilityElement(children: .combine)
  }
}

/// Kapağın sağında soluk, eğik bulmaca kareleri (süs).
private struct ProfileCoverPattern: View {
  /// Kare dizilimi: dolu kareler harf kutusu, boşlar boşluk.
  private static let cells: [[Bool]] = [
    [true, true, true, false],
    [false, true, false, false],
    [true, true, true, true],
  ]

  var body: some View {
    VStack(spacing: 4) {
      ForEach(Self.cells.indices, id: \.self) { row in
        HStack(spacing: 4) {
          ForEach(Self.cells[row].indices, id: \.self) { column in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(.white.opacity(Self.cells[row][column] ? 0.45 : 0))
              .frame(width: 16, height: 16)
          }
        }
      }
    }
    .rotationEffect(.degrees(-8))
  }
}
