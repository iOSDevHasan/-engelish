import SwiftUI

// MARK: - Public API

extension View {
  /// Ekranın altına, sağ-sol-alt kenarlara yapışık açılan uygulama paneli.
  ///
  /// Sistem panelinin iOS 26'da kenarlardan boşluk bırakan yüzen görünümü yerine kullanılır.
  /// Panel içeriğine göre boylanır; ekranın %88'inden uzun içerik panel içinde kaydırılır.
  /// İçerik kendi `ScrollView`'unu içermemelidir. İçeriden kapatmak için
  /// `@Environment(\.dismissAppSheet)` kullanılır.
  public func appBottomSheet<Content: View>(
    isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(
      AppBottomSheetModifier(
        isPresented: isPresented,
        onDismiss: { isPresented.wrappedValue = false },
        content: content))
  }

  /// Öğeye bağlı uygulama paneli; öğe `nil` olunca kapanır.
  public func appBottomSheet<Item: Identifiable, Content: View>(
    item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content
  ) -> some View {
    modifier(AppBottomSheetItemModifier(item: item, content: content))
  }
}

extension EnvironmentValues {
  /// Açık uygulama panelini animasyonla kapatır; panel dışında hiçbir şey yapmaz.
  @Entry public var dismissAppSheet: AppSheetDismissAction = AppSheetDismissAction {}
}

/// Paneli kapatma eylemi (`dismissAppSheet()` diye çağrılır).
public struct AppSheetDismissAction: Sendable {
  private let action: @MainActor @Sendable () -> Void

  /// Verilen eylemle oluşturur.
  public init(_ action: @escaping @MainActor @Sendable () -> Void) {
    self.action = action
  }

  /// Paneli kapatır.
  @MainActor public func callAsFunction() { action() }
}

// MARK: - Item adapter

/// Öğe bağlamasını panelin açık/kapalı durumuna çevirir; kapanış animasyonu bitene kadar son
/// öğeyi tutar ki içerik boşalmasın.
private struct AppBottomSheetItemModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
  @Binding var item: Item?
  let content: (Item) -> SheetContent
  @State private var shownItem: Item?

  func body(content base: Content) -> some View {
    base
      .modifier(
        AppBottomSheetModifier(
          isPresented: Binding(get: { item != nil }, set: { if !$0 { item = nil } }),
          onDismiss: { item = nil },
          content: {
            if let current = item ?? shownItem { content(current) }
          })
      )
      .onChange(of: item?.id, initial: true) { _, _ in
        if let item { shownItem = item }
      }
  }
}

// MARK: - Presenter

/// Paneli şeffaf, animasyonsuz bir tam ekran örtü içinde çizer; böylece sekme çubuğunun ve
/// gezinme yığınının da üstünde açılır. Giriş/çıkış animasyonunu panel kendisi yapar.
private struct AppBottomSheetModifier<SheetContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let onDismiss: @MainActor () -> Void
  @ViewBuilder let content: () -> SheetContent
  @State private var isCoverShown = false

  func body(content base: Content) -> some View {
    base
      .fullScreenCover(isPresented: $isCoverShown) {
        AppBottomSheetContainer(
          isPresented: isPresented,
          onDismiss: onDismiss,
          onFinished: { setCover(false) },
          content: content
        )
        .presentationBackground(.clear)
      }
      .onChange(of: isPresented, initial: true) { _, isOn in
        if isOn { setCover(true) }
      }
  }

  /// Örtüyü sistem animasyonu olmadan açar/kapatır.
  private func setCover(_ isOn: Bool) {
    guard isCoverShown != isOn else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { isCoverShown = isOn }
  }
}

// MARK: - Container

/// Karartma, tutamak, içerik yüksekliğine göre boylanan yüzey ve aşağı çekerek kapatma.
private struct AppBottomSheetContainer<SheetContent: View>: View {
  let isPresented: Bool
  let onDismiss: @MainActor () -> Void
  let onFinished: @MainActor () -> Void
  @ViewBuilder let content: () -> SheetContent

  @State private var isVisible = false
  @State private var dragOffset: CGFloat = 0
  @State private var contentHeight: CGFloat = 0
  /// Panelin ölçülen yüksekliği; ölçülmeden giriş animasyonu başlamaz.
  @State private var sheetHeight: CGFloat = 0
  @State private var isClosing = false
  @State private var hasAppeared = false
  /// İçerik en üstte mi; yalnızca öyleyken aşağı çekmek paneli taşır.
  @State private var isAtTop = true
  /// Sürükleme paneli taşıyorsa başladığı andaki çekme miktarı; taşımıyorsa `nil`.
  @State private var sheetDragStart: CGFloat?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Panelin ekran yüksekliğine oranla en fazla kaplayacağı alan.
  private static var maxHeightRatio: CGFloat { 0.88 }
  /// Panelin üstünde en az bırakılan karartma payı (klavye açıkken panel bu kadar uzayabilir).
  private static var minTopGap: CGFloat { 16 }
  /// Açılış: sistem paneline yakın, sekmeden yumuşak bir yay.
  private static var openAnimation: Animation { .smooth(duration: 0.45) }
  /// Kapanış: aşağı hızlanarak çekilir.
  private static var closeAnimation: Animation { .smooth(duration: 0.3) }

  /// Gizli paneli tam boyu kadar (ölçülmediyse kap yüksekliği kadar) aşağıda tutar.
  private func hiddenOffset(container: CGFloat, bottomInset: CGFloat) -> CGFloat {
    sheetHeight > 0 ? sheetHeight + bottomInset + 24 : container
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        Color.black
          .opacity(isVisible ? 0.4 : 0)
          .ignoresSafeArea()
          .onTapGesture { close() }
          .accessibilityHidden(true)
        // Panel hep çizilir, gizliyken ekranın altında bekler. Böylece içerik yüksekliği
        // ölçüldükten sonra tam boyuyla aşağıdan kayarak gelir (sistem paneli gibi); koşullu
        // eklemede ilk karede yükseklik sıfır olduğu için panel birden beliriyordu.
        sheet(
          maxHeight: proxy.safeAreaInsets.bottom > 100
            ? proxy.size.height - Self.minTopGap
            : proxy.size.height * Self.maxHeightRatio
        )
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { sheetHeight = $0 }
        .offset(
          y: isVisible
            ? max(dragOffset, 0)
            : hiddenOffset(container: proxy.size.height, bottomInset: proxy.safeAreaInsets.bottom)
        )
        .accessibilityHidden(!isVisible)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    .environment(\.dismissAppSheet, AppSheetDismissAction { close() })
    .onChange(of: contentHeight) { _, height in
      guard height > 0, !hasAppeared else { return }
      hasAppeared = true
      // Ölçülen yükseklik yerleşsin diye giriş bir sonraki karede başlar.
      Task { @MainActor in
        withAnimation(reduceMotion ? nil : Self.openAnimation) { isVisible = true }
      }
    }
    .onChange(of: isPresented) { _, isOn in
      if !isOn { close() }
    }
  }

  /// Tutamaklı, üstü yuvarlak, kenarlara ve alta yapışık panel yüzeyi.
  private func sheet(maxHeight: CGFloat) -> some View {
    VStack(spacing: 0) {
      Capsule()
        .fill(Palette.lineStrong)
        .frame(width: 40, height: 5)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
      ScrollView {
        content()
          .frame(maxWidth: 600)
          .frame(maxWidth: .infinity)
          .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = ceil($0) }
      }
      .scrollBounceBehavior(.basedOnSize)
      .scrollIndicators(.hidden)
      .scrollDisabled(sheetDragStart != nil)
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top <= 1
      } action: { _, atTop in
        isAtTop = atTop
      }
      // Kap ilk karede sıfır boyutlu gelebilir; yükseklik hiçbir zaman 1'in altına inmez.
      .frame(height: max(min(contentHeight, maxHeight - 19), 1))
    }
    .frame(maxWidth: .infinity)
    .background {
      UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
        .fill(Palette.background)
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .shadow(color: .black.opacity(0.16), radius: 20, y: -4)
    }
    .simultaneousGesture(dragGesture)
    .accessibilityElement(children: .contain)
    .accessibilityAddTraits(.isModal)
    .accessibilityAction(.escape) { close() }
  }

  /// Sistem paneli gibi aşağı çekme: tutamaktan ya da içerik en üstteyken içeriğin her yerinden
  /// çekilir. Panel taşınırken içerik kaydırılmaz; yeterince çekilirse kapanır, değilse yerine
  /// döner.
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 6, coordinateSpace: .global)
      .onChanged { value in
        let height = value.translation.height
        if sheetDragStart == nil {
          let isDownward = height > 0 && abs(height) > abs(value.translation.width)
          guard isAtTop, isDownward else { return }
          sheetDragStart = height
        }
        dragOffset = max(height - (sheetDragStart ?? 0), 0)
      }
      .onEnded { value in
        guard let start = sheetDragStart else { return }
        sheetDragStart = nil
        let pulled = value.translation.height - start
        let predicted = value.predictedEndTranslation.height - start
        if pulled > 120 || predicted > 260 {
          close()
        } else {
          withAnimation(Motion.snappy) { dragOffset = 0 }
        }
      }
  }

  /// Paneli aşağı kaydırıp karartmayı söndürür, ardından örtüyü kaldırır.
  private func close() {
    guard !isClosing else { return }
    isClosing = true
    withAnimation(reduceMotion ? nil : Self.closeAnimation) {
      isVisible = false
    } completion: {
      onDismiss()
      onFinished()
    }
  }
}
