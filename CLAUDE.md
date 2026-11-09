# Cengelish iOS

Çengelish — Türkçe ipuçlu, İngilizce cevaplı çengel bulmaca; kutular kalemle (parmak / Apple Pencil) doldurulur, kullanıcı cevap anahtarıyla kendini kontrol eder. Hesap yok: veriler cihazda (SwiftData), isteğe bağlı iCloud; içerik gömülü + Firebase.

Built on the Jarvis modular SPM architecture. Full spec:
`~/.claude/skills/jarvis/references/architecture.md`.

## Architecture Layers

- **`Cengelish/App/`** — App target: `@main`, `AppRootView` (composition root view), deep-link table
- **`Cengelish/Config/`** — `Base` / `Develop` / `Release` xcconfig + partial `Info.plist`
- **`Cengelish/Core/`** — **shared** Core packages (symlink to `~/Desktop/iOS Agent/core-packages`). Never put app-specific code here
- **`Cengelish/AppCore/`** — app-specific infrastructure packages (brand, API clients)
- **`Cengelish/Kits/`** — reusable feature kits (candidates for promotion to shared Core)
- **`Cengelish/Modules/`** — user-facing feature modules
- **`Cengelish/Composition/`** — `AppComposition`: the only package the Xcode target links; DI registration + re-exports

## App-Level Patterns

- **SPM** — every layer is a local Swift package; the app target links only `AppComposition`
- **DI** — `InjectionKit` (`@Inject` + `Injector`); coordinators registered in `Composition/Sources/DependencyRegistration.swift`
- **Coordinator** — each Kit/Module exposes `XxxInterface` (InterfaceSources target) implemented by `XxxCoordinator`; consumers depend on the Interface product only
- **MVVM** — `XxxView` (`@StateObject`) + `XxxViewModel` (`@MainActor ObservableObject`) + `Model` structs
- **Services (DI singletons)** — `ContentProviding` (ContentStore), `UserDataStoring` (UserDataStore), `EntitlementProviding` (EntitlementStore), `Pronouncing` (Pronouncer); registered in `DependencyRegistration.registerKits()`
- **Shell** — `Composition/Sources/Shell/AppShellView.swift`: onboarding vs. 4-tab `TabView` (Liquid Glass), appearance
- **Content** — `tools/content/words.psv` (10 sütun: TR ipucu, US/UK IPA, örnek + Türkçesi, etiketler) → `generate.py` → `ContentKit/Sources/Resources/starter.json` + `tools/content/out/firestore/` (Firebase); `upload_firebase.py` Firestore'a yükler (Storage yok)
- **Widgets** — `CengelishWidgets/` eklenti hedefi (sadece `WidgetBundle`); her şey `AppCore/WidgetBridgeKit`'te; App Group `group.com.hasangurbuz.cengelish`
- **Platforms** — packages `.iOS(.v18)`; app target iOS 18
- **Navigation** — `RouterKit` stack; deep links `cengelish://<path>` registered in `App/DeepLinkRegistration.swift`
- **Shared kits are opt-in** — only InjectionKit + RouterKit are always linked; add others with `arch.py add-dependency` / `arch.py add-brand` when a feature really needs them
- **Concurrency** — Swift Concurrency only (`async/await`, `Task`, actors); `DispatchQueue` is forbidden
- **Style** — `~/.claude/skills/jarvis/code-standarts.md`; format with `swift format --configuration .swift-format`
- **Scaffolding** — `python3 ~/.claude/skills/jarvis/scripts/arch.py new-module <Name> --app .` (see `arch.py --help`)

---

## Shared Core (`Cengelish/Core`)

See `~/Desktop/iOS Agent/core-packages/README.md` for the catalog. Change shared code there
deliberately — every app that links it is affected.

---

## AppCore

| Kit | Purpose | Reference |
|-----|---------|-----------|
| DesignKit | Renk/yazı tokenları (açık+koyu), ortak bileşenler, Kalemo avatarı, rozetler | [reference.md](Cengelish/AppCore/DesignKit/reference.md) |
| UserDataKit | SwiftData ile cihazda profil, ilerleme, defter, seri, rozet; isteğe bağlı iCloud | [reference.md](Cengelish/AppCore/UserDataKit/reference.md) |
| PurchaseKit | StoreKit 2 abonelik ve paket yetkileri | [reference.md](Cengelish/AppCore/PurchaseKit/reference.md) |
| ContentKit | Kelime/bulmaca/paket modelleri, gömülü başlangıç içeriği, Firebase'den paket indirme ve önbellek | [reference.md](Cengelish/AppCore/ContentKit/reference.md) |
| FirebaseContentKit | Firebase (Firestore + App Check) ile uzak içerik kaynağı (paket içerikleri `packContents` belgelerinde); GoogleService-Info.plist yoksa devre dışı | [reference.md](Cengelish/AppCore/FirebaseContentKit/reference.md) |
| WidgetBridgeKit | Widget anlık görüntüsü (App Group) ve widget görünümleri; uygulama yazar, widget okur | [reference.md](Cengelish/AppCore/WidgetBridgeKit/reference.md) |

---

## Kits

| Kit | Purpose | Reference |
|-----|---------|-----------|
| PuzzleKit | Çengel ızgara modeli, temalar ve ızgara görünümleri | [reference.md](Cengelish/Kits/PuzzleKit/reference.md) |
| WordKit | Kelime satırı, kelime detay paneli, telaffuz | [reference.md](Cengelish/Kits/WordKit/reference.md) |

---

## Modules

| Module | Purpose | Reference |
|--------|---------|-----------|
| HomeModule | Ana Sayfa: selamlama, seri kartı (seri dondurma ipucu), Günün Bulmacası, kaldığın yerden devam, günün kelimesi, hatırlatıcı paneli. | [reference.md](Cengelish/Modules/HomeModule/reference.md) |
| OnboardingModule | Karşılama, profil oluşturma (avatar + takma ad), seviye (2 dk seviye testi), amaç/hatırlatıcı, veri tercihi (cihaz / iCloud), sonda bir kez paywall. | [reference.md](Cengelish/Modules/OnboardingModule/reference.md) |
| ExploreModule | Keşfet (seviye, sınav ve tema paketleri, bölüm filtresi, arama), tema listesi, paket detayı (bulmaca kareleri, kilit, paywall). | [reference.md](Cengelish/Modules/ExploreModule/reference.md) |
| PuzzleModule | Bulmaca çözme: PencilKit ile kalem/kurşun/silgi, iki parmakla zoom, odak modu, ipucu ve tema panelleri, cevap anahtarı (✓/✗), bitiş ve paylaşım kartı. | [reference.md](Cengelish/Modules/PuzzleModule/reference.md) |
| NotebookModule | Kelime Defterim: özet, Tümü / Tekrar / Öğrendim, elle kelime ekleme, tekrar bulmacası (Çengelish+), kartla tekrar, kelime detayı. | [reference.md](Cengelish/Modules/NotebookModule/reference.md) |
| ProfileModule | Profil (kapak, avatar, unvan, istatistik, seviye ilerlemesi, seri takvimi, paylaşım kartı), profili düzenle, rozetler (15) ve vitrin. | [reference.md](Cengelish/Modules/ProfileModule/reference.md) |
| SettingsModule | Ayarlar, uygulama görünümü, Bulmaca teması ekranı, veri ve yedekleme (iCloud, dışa/içe aktarma, silme). | [reference.md](Cengelish/Modules/SettingsModule/reference.md) |
| PaywallModule | Çengelish+ paywall: yıllık / aylık / açılan sınav paketi (YDS, YÖKDİL, LGS, IELTS, TOEFL), geri yükleme. | [reference.md](Cengelish/Modules/PaywallModule/reference.md) |

---

## Documentation Update Rules

### When creating a new Kit / Module / AppCore package
1. Create `reference.md` in the package folder with **Layer**, **Purpose**, **Public API**, **Structure**, **Dependencies**.
2. Add a row to the matching table above.

### When updating an existing package
1. Update its `reference.md` (new protocol, dependency, structure).
2. Update the table row if name or purpose changed.

> **Order matters:** `reference.md` first, then `CLAUDE.md`.
