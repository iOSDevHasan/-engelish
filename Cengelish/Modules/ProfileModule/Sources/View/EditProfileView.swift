import DesignKit
import SwiftUI
import UserDataKit

/// Profili düzenle: avatar, takma ad, unvan.
struct EditProfileView: View {
  @StateObject var viewModel: ProfileViewModel
  @State private var lockedHint: UserTitle?
  @FocusState private var isNicknameFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          preview
          group("Kalemo rengi") { BodyColorPicker(selection: $viewModel.draft.avatar.body) }
          group("Aksesuar", note: "Rozetlerle açılır") {
            AccessoryPicker(
              selection: $viewModel.draft.avatar.accessory, body: viewModel.draft.avatar.body,
              lockReason: viewModel.lockReason)
          }
          group("Arka plan") {
            BackgroundPicker(
              selection: $viewModel.draft.avatar.background, isLocked: viewModel.isLocked)
          }
          nickname
          group("Unvan") { titles }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .screenBackground()
  }

  // MARK: - Subviews

  private var header: some View {
    HStack {
      Button("Vazgeç", action: viewModel.cancelDraft)
        .font(AppFont.bodyBold)
        .foregroundStyle(Palette.accent)
      Spacer()
      Text("Profili düzenle").font(AppFont.section).foregroundStyle(Palette.ink)
      Spacer()
      Button("Kaydet", action: viewModel.saveDraft)
        .buttonStyle(ChunkyButtonStyle(.primary, fullWidth: false, compact: true))
    }
    .padding(.horizontal, Metrics.gutter)
    .frame(minHeight: 44)
    .padding(.vertical, 6)
  }

  private var preview: some View {
    VStack(spacing: 6) {
      AvatarView(viewModel.draft.avatar, size: 88)
      Text(viewModel.draft.displayName)
        .font(AppFont.headline)
        .foregroundStyle(Palette.ink)
        .padding(.top, 4)
      Pill(viewModel.draftTitle.title, systemImage: "trophy.fill", tone: .accent)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  private var nickname: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Takma ad")
        .font(AppFont.rounded(12, weight: .black))
        .foregroundStyle(Palette.muted)
        .padding(.leading, 4)
      HStack(spacing: 8) {
        TextField("Kalemci", text: $viewModel.draft.nickname)
          .font(AppFont.rounded(16, weight: .heavy))
          .foregroundStyle(Palette.ink)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .focused($isNicknameFocused)
          .submitLabel(.done)
          .onChange(of: viewModel.draft.nickname) { viewModel.limitNickname() }
        Text(viewModel.nicknameCounter)
          .font(AppFont.rounded(11.5, weight: .bold))
          .foregroundStyle(Palette.muted)
          .monospacedDigit()
      }
      .padding(.horizontal, 14)
      .frame(height: 50)
      .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(isNicknameFocused ? Palette.accent : Palette.line, lineWidth: 2))
    }
  }

  private var titles: some View {
    VStack(alignment: .leading, spacing: 8) {
      FlowLayout(spacing: 8) {
        ForEach(UserTitle.allCases, id: \.self) { title in
          titleChip(title)
        }
      }
      if let lockedHint {
        Label(
          "\(lockedHint.title): \(lockedHint.requirement) ile açılır", systemImage: "lock.fill"
        )
        .font(AppFont.caption)
        .foregroundStyle(Palette.muted)
      }
    }
  }

  private func titleChip(_ title: UserTitle) -> some View {
    let unlocked = viewModel.isUnlocked(title)
    let selected = viewModel.draftTitle == title
    return Button {
      if unlocked {
        viewModel.draft.titleId = title.id
        lockedHint = nil
      } else {
        lockedHint = title
      }
    } label: {
      HStack(spacing: 6) {
        if !unlocked {
          Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold))
        } else if selected {
          Image(systemName: "checkmark").font(.system(size: 13, weight: .black))
        }
        Text(title.title)
      }
      .font(AppFont.rounded(14, weight: .heavy))
      .foregroundStyle(selected ? .white : Palette.ink)
      .padding(.horizontal, 14)
      .frame(height: 38)
      .background(Capsule().fill(selected ? Palette.accent : Palette.surface))
      .overlay(Capsule().strokeBorder(selected ? .clear : Palette.lineStrong, lineWidth: 1.5))
      .opacity(unlocked ? 1 : 0.55)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(unlocked ? title.title : "\(title.title), kilitli: \(title.requirement)")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func group<Content: View>(
    _ title: String, note: String? = nil, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title).font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        if let note {
          Text(note).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
      }
      content()
    }
  }
}
