import FirebaseContentKit
// jarvis:bootstrap-imports

/// Process-wide setup that must run before the first view renders
/// (fonts, theme, analytics — only for the shared kits this app actually links).
@MainActor
public enum AppBootstrap {

  public static func configure() {
    FirebaseBootstrap.configureIfAvailable()
    // jarvis:bootstrap
  }
}
