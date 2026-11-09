import DesignKit
import SwiftUI
import UserDataKit

/// Profili düzenle: avatar, takma ad, unvan.
struct EditProfileView: View {
  @StateObject var viewModel: ProfileViewModel

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button("Vazgeç", action: viewModel.cancelDraft).foregroundStyle(Palette.muted)
        Spacer()
        Text("Profili düzenle").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Button("Kaydet", action: viewModel.saveDraft).fontWeight(.heavy).foregroundStyle(
          Palette.accent)
      }
      .font(AppFont.body)
      .padding(.horizontal, Metrics.gutter)
      .padding(.vertical, 10)
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          AvatarView(viewModel.draft.avatar, size: 110).frame(maxWidth: .infinity)
          group("Kalemo rengi") { BodyColorPicker(selection: $viewModel.draft.avatar.body) }
          group("Aksesuar") {
            AccessoryPicker(
              selection: $viewModel.draft.avatar.accessory, body: viewModel.draft.avatar.body,
              lockReason: viewModel.lockReason)
          }
          group("Arka plan") {
            BackgroundPicker(
              selection: $viewModel.draft.avatar.background, isLocked: viewModel.isLocked)
          }
          group("Takma ad") {
            TextField("Kalemci", text: $viewModel.draft.nickname)
              .font(AppFont.bodyBold)
              .padding(14)
              .background(RoundedRectangle(cornerRadius: 16).fill(Palette.surface))
              .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.line, lineWidth: 2))
          }
          group("Unvan") {
            FlowLayout(spacing: 8) {
              ForEach(UserTitle.allCases, id: \.self) { title in
                let unlocked = title.isUnlocked(viewModel.stats)
                let selected = viewModel.draft.titleId == title.id
                Button {
                  if unlocked { viewModel.draft.titleId = title.id }
                } label: {
                  HStack(spacing: 4) {
                    if !unlocked { Image(systemName: "lock.fill").font(.system(size: 10)) }
                    Text(unlocked ? title.title : "\(title.title) · \(title.requirement)")
                  }
                  .font(AppFont.caption.weight(.heavy))
                  .foregroundStyle(selected ? .white : unlocked ? Palette.ink : Palette.muted)
                  .padding(.horizontal, 12)
                  .frame(height: 34)
                  .background(Capsule().fill(selected ? Palette.accent : Palette.surface))
                  .overlay(Capsule().strokeBorder(selected ? .clear : Palette.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
  }

  private func group<Content: View>(
    _ title: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title).font(AppFont.section).foregroundStyle(Palette.ink)
      content()
    }
  }
}
