import DesignKit
import PhotosUI
import SwiftUI

/// Kimlik kartındaki kalemle açılan panel: profil fotoğrafı ve takma ad.
///
/// `appBottomSheet` içinde gösterilir; kendi kaydırma alanı yoktur.
struct EditProfileSheet: View {
  @ObservedObject var viewModel: ProfileViewModel
  @State private var pickerItem: PhotosPickerItem?
  @FocusState private var isNicknameFocused: Bool
  @Environment(\.dismissAppSheet) private var dismissAppSheet

  /// Paneldeki avatar önizlemesinin çapı.
  private static let previewSize: CGFloat = 104

  var body: some View {
    VStack(spacing: 18) {
      header
      preview
      photoActions
      nickname
      Button {
        viewModel.saveDraft()
        dismissAppSheet()
      } label: {
        Text("Kaydet")
      }
      .buttonStyle(.chunky)
      .disabled(viewModel.isPreparingPhoto)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 8)
    .padding(.bottom, 24)
    .onChange(of: pickerItem) { _, item in
      guard let item else { return }
      Task {
        await load(item)
        pickerItem = nil
      }
    }
  }

  // MARK: - Subviews

  private var header: some View {
    HStack {
      Text("Profilini düzenle").font(AppFont.headline).foregroundStyle(Palette.ink)
      Spacer()
      Button("Vazgeç") { dismissAppSheet() }
        .font(AppFont.bodyBold)
        .foregroundStyle(Palette.accent)
    }
  }

  private var preview: some View {
    VStack(spacing: 10) {
      UserAvatarView(
        photo: viewModel.draftPhoto, avatar: viewModel.profile.avatar, size: Self.previewSize
      )
      .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 4))
      .overlay {
        if viewModel.isPreparingPhoto {
          Circle().fill(.black.opacity(0.35))
          ProgressView().tint(.white)
        }
      }
      .shadow(color: Palette.cardShadow, radius: 0, y: 3)
      .animation(Motion.snappy, value: viewModel.draftPhoto)
      Text(viewModel.draftDisplayName)
        .font(AppFont.headline)
        .foregroundStyle(Palette.ink)
        .lineLimit(1)
        .contentTransition(.opacity)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  private var photoActions: some View {
    let pickTitle = viewModel.draftPhoto == nil ? "Fotoğraf seç" : "Fotoğrafı değiştir"
    return VStack(spacing: 8) {
      HStack(spacing: 10) {
        PhotosPicker(selection: $pickerItem, matching: .images) {
          Label(pickTitle, systemImage: "photo.on.rectangle")
        }
        .buttonStyle(ChunkyButtonStyle(.secondary, compact: true))
        if viewModel.draftPhoto != nil {
          Button(role: .destructive) {
            pickerItem = nil
            viewModel.removeDraftPhoto()
          } label: {
            Label("Fotoğrafı kaldır", systemImage: "trash")
              .foregroundStyle(Palette.bad)
          }
          .buttonStyle(ChunkyButtonStyle(.secondary, compact: true))
          .transition(.scale.combined(with: .opacity))
        }
      }
      .disabled(viewModel.isPreparingPhoto)
      if let error = viewModel.photoError {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .font(AppFont.caption)
          .foregroundStyle(Palette.bad)
          .transition(.opacity)
      }
    }
    .animation(Motion.snappy, value: viewModel.draftPhoto == nil)
    .animation(Motion.snappy, value: viewModel.photoError)
  }

  private var nickname: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Takma ad").font(AppFont.section).foregroundStyle(Palette.ink)
      HStack(spacing: 8) {
        TextField(viewModel.profile.displayName, text: $viewModel.draftNickname)
          .font(AppFont.rounded(16, weight: .heavy))
          .foregroundStyle(Palette.ink)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .focused($isNicknameFocused)
          .submitLabel(.done)
          .onSubmit { isNicknameFocused = false }
          .onChange(of: viewModel.draftNickname) { viewModel.limitNickname() }
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
          .strokeBorder(isNicknameFocused ? Palette.accent : Palette.cardBorder, lineWidth: 2)
      )
      .animation(Motion.snappy, value: isNicknameFocused)
    }
  }

  // MARK: - Actions

  /// Seçilen fotoğrafın verisini okuyup görünüm modeline verir.
  private func load(_ item: PhotosPickerItem) async {
    do {
      guard let data = try await item.loadTransferable(type: Data.self) else {
        return viewModel.photoLoadFailed()
      }
      await viewModel.pickPhoto(data)
    } catch {
      viewModel.photoLoadFailed()
    }
  }
}
