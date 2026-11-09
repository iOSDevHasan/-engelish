# core-packages

Shared, app-agnostic Swift packages for the Jarvis modular architecture — anonymized sample
code from a production modular app, stripped of every product-specific name, host and flow. Apps see this folder as `<App>/Core`
(a symlink created by `jarvis/scripts/arch.py`), so manifests reference `../../Core/<Kit>`.

## Usage policy — opt in, don't default in

The architecture is **local SPM packages + runtime DI + coordinators**, not "link every kit".

| Package | Linked when | Notes |
|---|---|---|
| InjectionKit | **always** | `@Inject` + `Injector` — the DI backbone |
| RouterKit | **always** | Stack navigation + deep links; modules use the `RouterKitInterface` product |
| CacheKit | repeatable read models need memory/disk caching | actor-isolated typed cache; no backend dependency |
| HTTPKit | the app talks to an HTTP API | Alamofire; `APIEndpoint`, `HTTPClient` actor, 401 refresh |
| SessionKit | tokens / Keychain / PKCE are needed | needs HTTPKit |
| UtilityKit | you need its Logger, Analytics facade, build flags or extensions | no third-party deps |
| FirebaseTrackingKit | the app ships Firebase Analytics/Crashlytics | the only Firebase importer |
| StyleKit | the app wants a token design system (palette, spacing, Inter type) | apps with plain system styling skip it |
| DSKit | a screen needs one of its components (buttons, dialogs, OTP, crop…) | pulls StyleKit + UtilityKit |

Native SwiftUI/system API first. Don't add a package for one helper you could write in a line.

## Catalog

| Kit | Purpose | Reference |
|-----|---------|-----------|
| InjectionKit | `@Inject` property wrapper + `Injector` service locator with singleton/factory scopes and test overrides | [reference.md](InjectionKit/reference.md) |
| RouterKit | NavigationBackport stack navigator, `RouterStack`, extensible `DeepLinkPath`, flow-exit hook | [reference.md](RouterKit/reference.md) |
| CacheKit | Typed memory + disk cache with TTL, LRU, request coalescing and read policies | [reference.md](CacheKit/reference.md) |
| HTTPKit | Alamofire-backed `HTTPClient` actor, `APIEndpoint`, auth interceptor, `NetworkMonitor`, `APIConfig` | [reference.md](HTTPKit/reference.md) |
| SessionKit | Keychain store, refresh-capable `SessionTokenProvider`, PKCE helper | [reference.md](SessionKit/reference.md) |
| UtilityKit | OSLog `Logger`, pluggable `Analytics` facade, `BuildFlags`, jailbreak check, extensions | [reference.md](UtilityKit/reference.md) |
| FirebaseTrackingKit | `FirebaseAnalyticsTracker` for UtilityKit's `Analytics` | [reference.md](FirebaseTrackingKit/reference.md) |
| StyleKit | Configurable `ThemePalette` (light/dark), spacing/radius tokens, `Grid`, Inter fonts, `StringTable` + `CommonL10n` | [reference.md](StyleKit/reference.md) |
| DSKit | `DS*` SwiftUI components: button, text field, OTP, nav bars, dialogs, banners, snackbar, stepper, document crop/preview, screenshot guard | [reference.md](DSKit/reference.md) |


## Changing shared code

Every app that links a package gets the change on its next build.

1. Keep it app-agnostic: no brand names, hosts, strings or product flows. Extension points are
   `RawRepresentable` structs (`DeepLinkPath`, `AnalyticsEvent`, `KeychainStore.Key`) and config
   (`Theme.configure`, `HTTPAuth.configure`) — apps extend, the package never enumerates them.
2. Prefer additive API; if a change breaks callers, fix every app that links the package.
3. Promote code from an app only when a **second** app needs it (rule of two).
4. Update the package's `reference.md` and the catalog row above.
5. Format with `swift format --in-place --recursive --configuration .swift-format <paths>`, then build
   and test the package: `xcodebuild test -scheme <Kit> -destination 'platform=iOS Simulator,name=<device>'`
   (use `<Kit>-Package` for packages that also ship an `Interface` product).

For CI or sharing an app repo, vendor a copy instead of the symlink:
`python3 ~/.claude/skills/jarvis/scripts/arch.py link-core --app <repo> --vendor`.
