/// A routable deep-link path (`scheme://<path>`). Apps declare their paths in an extension:
/// `extension DeepLinkPath { static let settings: Self = "settings" }`.
/// Matching is case-insensitive against the URL host and the URL path.
public struct DeepLinkPath: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue.lowercased()
  }

  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}
