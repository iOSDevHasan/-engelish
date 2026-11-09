# Çengelish — Senin yapacakların

Kod tarafı hazır ve simülatörde çalışıyor. Aşağıdakiler senin hesaplarınla yapılması gereken adımlar.
Sıra önemli: 1 → 2 → 3, sonra diğerleri.

## 1. Xcode ve Apple Developer
1. `Cengelish/Cengelish.xcodeproj` dosyasını aç → **Cengelish** hedefi → **Signing & Capabilities**.
   - **Team**: kendi takımını seç (projede takım ayarlanmadı).
   - Bundle ID: `com.hasangurbuz.cengelish` (istersen değiştir; değiştirirsen aşağıdaki ürün kimliklerini de değiştir).
2. Aynı ekranda şu yetenekler `Config/Cengelish.entitlements` içinde hazır; Xcode'un bunları Apple Developer'da kaydetmesine izin ver:
   - **iCloud → CloudKit**, kapsayıcı: `iCloud.com.hasangurbuz.cengelish`
   - **Push Notifications** (CloudKit senkronu için)
   - **Background Modes → Remote notifications** (Info.plist'te hazır)
3. Gerçek bir iPhone'da iCloud'a giriş yapılıyken "iCloud ile yedekle"yi dene. (Simülatörde iCloud girişi olmadığı için uygulama sessizce cihazda çalışır.)
4. Yayından önce `Config/Cengelish.entitlements` içindeki `aps-environment` değerini Xcode dağıtımda otomatik `production` yapar; elle bir şey yapma.

## 2. App Store Connect
1. **Uygulama kaydı**: Ad `Çengelish: İngilizce Çengel`, birincil dil Türkçe, Bundle ID yukarıdaki.
   Bu adım ismi senin adına ayırır.
2. **Ürünler** (kimlikler kodda sabit, `PurchaseKit/Sources/ProductID.swift`):
   | Kimlik | Tür | Fiyat (öneri) |
   |---|---|---|
   | `com.hasangurbuz.cengelish.plus.yearly` | Otomatik yenilenen abonelik, grup "Çengelish+", 7 gün ücretsiz deneme | 449,99 ₺ |
   | `com.hasangurbuz.cengelish.plus.monthly` | Otomatik yenilenen abonelik, aynı grup | 74,99 ₺ |
   | `com.hasangurbuz.cengelish.pack.yds` | Tüketilemez (non-consumable) | 199,99 ₺ |
3. **Paid Apps sözleşmesi** ve banka/vergi bilgileri (abonelik satmak için şart).
4. **Gizlilik politikası URL'si**: paywall'daki bağlantı `https://cengelish.app/gizlilik` — bu sayfayı yayınla ya da bağlantıyı `PaywallModule/Sources/View/PaywallView.swift` içindeki `LegalLinks.privacy` ile değiştir.
5. Mağaza metni önerisi: Başlık `Çengelish: İngilizce Çengel`, alt başlık `Kelime öğreten bulmaca oyunu`, anahtar kelimeler `OYUN-PLANI.md` Bölüm 11.4'te.
6. Satın almayı yayından önce denemek için: Xcode'da şemaya bağlı `StoreKit/Cengelish.storekit` hazır (Xcode'dan çalıştırınca paywall gerçek fiyatlarla açılır), sonra TestFlight + Sandbox hesabı.

## 3. Firebase (içerik)
Firebase olmadan da uygulama gömülü içerikle (5 paket, 56 bulmaca, 30 günlük bulmaca) çalışır. Yeni içeriği güncellemesiz göndermek için:
1. Firebase konsolunda proje aç → iOS uygulaması ekle (Bundle ID yukarıdaki).
2. **GoogleService-Info.plist** dosyasını indir ve Xcode'da `Cengelish/App/Resources/` klasörüne sürükle (hedef: Cengelish). Dosya eklenince uygulama Firebase'i kendiliğinden açar.
3. **Firestore** ve **Storage**'ı etkinleştir (bölge: `europe-west1` gibi yakın bir bölge).
4. Güvenlik kurallarını yükle: `firebase/` klasöründe hazır.
   ```
   cd Cengelish/firebase && firebase deploy --only firestore:rules,storage
   ```
5. **App Check**: konsolda App Attest'i aç. Geliştirmede ilk çalıştırmada Xcode konsoluna yazılan *debug token*'ı App Check → Apps → Manage debug tokens'a ekle. Her şey çalışınca Firestore ve Storage için "Enforce" yap.
6. İçeriği yükle: Proje Ayarları → Hizmet hesapları → yeni özel anahtar (JSON) indir. **Bu dosyayı repoya koyma.**
   ```
   pip install firebase-admin
   python3 tools/content/upload_firebase.py --key /güvenli/yol/serviceAccount.json --bucket <proje-id>.firebasestorage.app
   ```
7. Yeni kelime / bulmaca eklemek için: `tools/content/words.psv`'ye kelime ekle → `python3 tools/content/generate.py --start <tarih> --days 30` → 6. adımdaki yükleme.
   (Gömülü içeriği de güncellemek istersen aynı komut `starter.json`'ı yeniler; sonra uygulamayı yeniden derle.)

## 4. Marka ve isim
1. **TÜRKPATENT**: Sınıf 9 ve 41'de "Çengelish" ve "Çengel" içeren markaları ara; uygunsa başvur.
2. **Alan adı**: `cengelish.app` (gizlilik sayfası için de lazım) ve sosyal medya kullanıcı adları (`@cengelish`).

## 5. Görseller
1. **Uygulama ikonu**: `tools/icon/make_icon.py` ile Kalemo'lu bir başlangıç ikonu üretildi. Yayından önce bir tasarımcıya son halini yaptırmanı öneririm (açık / koyu / tinted varyantlarıyla).
2. App Store ekran görüntüleri (6.9" iPhone + 13" iPad).

## 6. İçerik kontrolü
`tools/content/words.psv` dosyasındaki 364 kelimenin Türkçe ipuçlarını, anlamlarını, IPA'larını ve örnek cümlelerini bir kez gözden geçir. Özellikle sınav (YDS) kelimeleri için bir öğretmene baktırmak iyi olur.
