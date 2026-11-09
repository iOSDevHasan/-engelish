import SwiftUI
import UIKit

extension View {
  /// Sistem gezinme çubuğunu gizler; ekranlar kendi üst barını (`NavHeader`) çizer.
  public func chromeless() -> some View {
    toolbar(.hidden, for: .navigationBar)
      .navigationBarBackButtonHidden(true)
  }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
  /// Gezinme çubuğu gizliyken de kenardan kaydırarak geri gitmeyi açık tutar.
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    viewControllers.count > 1
  }
}
