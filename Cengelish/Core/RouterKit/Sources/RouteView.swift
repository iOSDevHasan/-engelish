import SwiftUI

public struct RouteView: Hashable, Identifiable {
  public let id = UUID()
  public let view: AnyView

  public init(_ view: AnyView) {
    self.view = view
  }

  public static func == (lhs: RouteView, rhs: RouteView) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
