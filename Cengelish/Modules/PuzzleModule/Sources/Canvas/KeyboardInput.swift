import SwiftUI
import UIKit

/// Klavye modunda sistem klavyesini açık tutan görünmez metin girişi (`UIKeyInput`).
///
/// Etkinleşince ya da `request` her arttığında klavyeyi açar; etkin değilken kapatır. Yazılan
/// karakterler, silme ve "Sonraki" tuşu kapanışlarla view model'e iletilir. Donanım klavyesi de
/// aynı yoldan çalışır.
struct KeyboardInput: UIViewRepresentable {
  /// Klavye açık olmalı mı.
  let isActive: Bool
  /// Her artışta klavye yeniden açılır (kutuya dokununca).
  let request: Int
  /// Yazılan metin.
  let onInsert: (String) -> Void
  /// Silme tuşu.
  let onDelete: () -> Void
  /// "Sonraki" (return) tuşu.
  let onReturn: () -> Void
  /// Klavye açıldı / kapandı.
  let onFocusChange: (Bool) -> Void

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIView(context: Context) -> KeyInputView {
    let view = KeyInputView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    view.isAccessibilityElement = false
    return view
  }

  func updateUIView(_ view: KeyInputView, context: Context) {
    view.onInsert = onInsert
    view.onDelete = onDelete
    view.onReturn = onReturn
    view.onFocusChange = onFocusChange
    view.wantsFocus = isActive
    let coordinator = context.coordinator
    let shouldOpen = isActive && (!coordinator.wasActive || coordinator.request != request)
    coordinator.wasActive = isActive
    coordinator.request = request
    // İlk yanıtlayıcı değişikliği SwiftUI güncellemesi dışında yapılır.
    if shouldOpen {
      Task { @MainActor [weak view] in
        guard let view, view.window != nil, !view.isFirstResponder else { return }
        _ = view.becomeFirstResponder()
      }
    } else if !isActive, view.isFirstResponder {
      Task { @MainActor [weak view] in
        _ = view?.resignFirstResponder()
      }
    }
  }

  /// Son istek ve etkinlik durumu.
  @MainActor
  final class Coordinator {
    var wasActive = false
    var request = 0
  }
}

/// Klavyeden harf alan görünmez görünüm.
final class KeyInputView: UIView, UIKeyInput {
  var onInsert: ((String) -> Void)?
  var onDelete: (() -> Void)?
  var onReturn: (() -> Void)?
  var onFocusChange: ((Bool) -> Void)?
  /// Pencereye eklenince klavye açılsın mı.
  var wantsFocus = false

  // MARK: - Text input traits

  var autocorrectionType: UITextAutocorrectionType = .no
  var autocapitalizationType: UITextAutocapitalizationType = .allCharacters
  var spellCheckingType: UITextSpellCheckingType = .no
  var smartInsertDeleteType: UITextSmartInsertDeleteType = .no
  var keyboardType: UIKeyboardType = .asciiCapable
  var returnKeyType: UIReturnKeyType = .next
  var inlinePredictionType: UITextInlinePredictionType = .no

  // MARK: - Responder

  override var canBecomeFirstResponder: Bool { true }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil, wantsFocus, !isFirstResponder else { return }
    Task { @MainActor [weak self] in
      _ = self?.becomeFirstResponder()
    }
  }

  override func becomeFirstResponder() -> Bool {
    let became = super.becomeFirstResponder()
    if became { onFocusChange?(true) }
    return became
  }

  override func resignFirstResponder() -> Bool {
    let resigned = super.resignFirstResponder()
    if resigned { onFocusChange?(false) }
    return resigned
  }

  // MARK: - UIKeyInput

  /// Silme tuşu her zaman iletilsin diye metin varmış gibi davranır.
  var hasText: Bool { true }

  func insertText(_ text: String) {
    if text == "\n" {
      onReturn?()
    } else {
      onInsert?(text)
    }
  }

  func deleteBackward() {
    onDelete?()
  }
}
