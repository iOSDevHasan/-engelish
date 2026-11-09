import SwiftUI

/// Environment hook a multi-step flow calls to ask for exit confirmation.
/// It is non-nil only while `Routing.flowExitContext` is set.
public struct FlowExitRequestKey: EnvironmentKey {
  public static let defaultValue: (@MainActor () -> Void)? = nil
}

public extension EnvironmentValues {
  var requestFlowExit: (@MainActor () -> Void)? {
    get { self[FlowExitRequestKey.self] }
    set { self[FlowExitRequestKey.self] = newValue }
  }
}
