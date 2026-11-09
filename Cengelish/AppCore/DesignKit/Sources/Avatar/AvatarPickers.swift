import SwiftUI

/// Kalemo gövde rengi seçici satırı.
public struct BodyColorPicker: View {
  @Binding private var selection: AvatarBody

  /// Seçim bağlamıyla oluşturur.
  public init(selection: Binding<AvatarBody>) {
    self._selection = selection
  }

  public var body: some View {
    HStack(spacing: 10) {
      ForEach(AvatarBody.allCases, id: \.self) { item in
        Button {
          selection = item
        } label: {
          Circle().fill(item.color)
            .frame(width: 36, height: 36)
            .overlay(
              Circle().strokeBorder(Palette.background, lineWidth: selection == item ? 3 : 0)
            )
            .overlay(
              Circle().strokeBorder(Palette.accent, lineWidth: selection == item ? 2 : 0)
                .padding(-3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selection == item ? .isSelected : [])
      }
    }
  }
}

/// Arka plan rengi seçici satırı.
public struct BackgroundPicker: View {
  @Binding private var selection: AvatarBackground
  private let isLocked: (AvatarBackground) -> Bool

  /// Seçim ve kilit kuralıyla oluşturur.
  public init(
    selection: Binding<AvatarBackground>,
    isLocked: @escaping (AvatarBackground) -> Bool = { _ in false }
  ) {
    self._selection = selection
    self.isLocked = isLocked
  }

  public var body: some View {
    HStack(spacing: 8) {
      ForEach(AvatarBackground.allCases, id: \.self) { item in
        let locked = isLocked(item)
        Button {
          if !locked { selection = item }
        } label: {
          Circle().fill(item.color)
            .frame(width: 32, height: 32)
            .overlay {
              if locked {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                  .foregroundStyle(.white)
                  .padding(4)
                  .background(Circle().fill(Color.black.opacity(0.35)))
              }
            }
            .overlay(
              Circle().strokeBorder(Palette.accent, lineWidth: selection == item ? 2 : 0)
                .padding(-3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "Kilitli arka plan" : "Arka plan")
      }
    }
  }
}

/// Aksesuar seçici: her aksesuar küçük bir Kalemo önizlemesiyle.
public struct AccessoryPicker: View {
  @Binding private var selection: AvatarAccessory
  private let options: [AvatarAccessory]
  private let body_: AvatarBody
  private let lockReason: (AvatarAccessory) -> String?

  /// Seçim, gösterilecek aksesuarlar, gövde rengi ve kilit nedeniyle oluşturur.
  public init(
    selection: Binding<AvatarAccessory>, options: [AvatarAccessory] = AvatarAccessory.allCases,
    body: AvatarBody, lockReason: @escaping (AvatarAccessory) -> String? = { _ in nil }
  ) {
    self._selection = selection
    self.options = options
    self.body_ = body
    self.lockReason = lockReason
  }

  public var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
      ForEach(options, id: \.self) { item in
        let reason = lockReason(item)
        Button {
          if reason == nil { selection = item }
        } label: {
          VStack(spacing: 4) {
            KalemoView(body: body_, accessory: item)
              .frame(height: 44)
              .opacity(reason == nil ? 1 : 0.35)
            Text(item.title).font(AppFont.tiny).foregroundStyle(Palette.ink)
            if let reason {
              Label(reason, systemImage: "lock.fill")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
          }
          .frame(maxWidth: .infinity, minHeight: 86)
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(selection == item ? Palette.selection : Palette.surface)
              .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .strokeBorder(selection == item ? Palette.accent : Palette.line, lineWidth: 2))
          )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.map { "\(item.title), kilitli: \($0)" } ?? item.title)
      }
    }
  }
}
