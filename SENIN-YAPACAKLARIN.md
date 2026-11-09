# Çengelish — Senin yapacakların

Kod, Firebase ve App Store Connect'in büyük kısmı hazır. Aşağıdakiler senin hesabınla, onayınla ya da
yasal beyanınla yapılması gereken adımlar. Sıra önemli.

## Hazır olanlar (bilgi için)
- **GitHub:** `iOSDevHasan/-engelish` (herkese açık depo). `GoogleService-Info.plist` ve hizmet hesabı
  anahtarları `.gitignore`'da, depoya girmez.
- **Firebase (`cengelish`):** iOS uygulaması kayıtlı, plist projede, Firestore (europe-west3) açık,
  kurallar yüklü. Storage kullanılmıyor (ücretli plan istemez).
- **App Store Connect (Çengelish, 6832412024):**
  - Ad, alt başlık, kategori (Eğitim + Oyunlar: Kelime/Bulmaca), yaş sınırı 4+, açıklama, anahtar
    kelimeler, tanıtım metni, destek URL'si, telif ve App Review notu girildi. "Giriş gerekir" işareti
    kaldırıldı.
  - Fiyat: ücretsiz, 175 ülke.
  - "Çengelish+" abonelik grubu:
    - `plus.yearly` 449,99 ₺, 7 gün ücretsiz deneme
    - `plus.monthly` 74,99 ₺
  - Tek seferlik paketler:
    - `pack.yds`, `pack.yokdil`, `pack.ielts`, `pack.toefl`: 199,99 ₺
    - `pack.lgs`: 129,99 ₺
  - Bütün ürünlerin Türkçe adı ve açıklaması var; inceleme görseli olarak paywall ekranı yüklendi.

## 1. GitHub Pages (destek ve gizlilik sayfası) — 1 dakika
Mağazadaki destek URL'si ve paywall'daki gizlilik bağlantısı bu sayfalara gidiyor:
`https://iosdevhasan.github.io/-engelish/` ve `.../gizlilik.html`. Sayfalar `docs/` klasöründe hazır.
Herkese açık bir site yayınlamak senin kararın olduğu için açmadım. Açmak için:
- GitHub → depo → Settings → Pages → Source: `main` / `/docs` → Save.
- Ya da terminalde:
```bash
gh api -X POST repos/iOSDevHasan/-engelish/pages -f "source[branch]=main" -f "source[path]=/docs"
```
`cengelish.app` alan adını alırsan sonra bu adrese taşıyabiliriz.

## 2. App Store Connect — yasal beyanlar ve sözleşme
1. **Paid Apps sözleşmesi + vergi + banka** (Business bölümü). Abonelik ve paket satmak için şart.
2. **App Privacy** (Uygulama Gizliliği): "Veri toplamıyoruz" (Data Not Collected) seçmen yeterli.
   Firebase'e kişisel veri gitmiyor; App Check sadece cihazın gerçek olduğunu doğruluyor.
   Gizlilik politikası URL'si: `https://iosdevhasan.github.io/-engelish/gizlilik.html`
3. **Content Rights** (Uygulama Bilgileri): "No, it does not contain … third-party content".
4. **App Review iletişim bilgileri** (ad, telefon, e-posta) sürüm sayfasında.
5. **Ekran görüntüleri:**
   - Zorunlu: 6.9" iPhone (1320×2868) ve 13" iPad.
   - Bir tasarımcıya yaptırman en iyisi; sıra önerisi `OYUN-PLANI.md` 11.4'te.
   - İstersen simülatörden ham görüntüleri ben de çekip yükleyebilirim.

## 3. Xcode — ilk build ve TestFlight
1. `Cengelish.xcodeproj` → Signing & Capabilities. Takım (D4VYL8Q23D) iki hedefte de seçili. Xcode'un
   şunları Apple Developer'da kaydetmesine izin ver:
   - App Group `group.com.hasangurbuz.cengelish` (uygulama + widget)
   - iCloud/CloudKit `iCloud.com.hasangurbuz.cengelish`
   - Push
2. Product → Archive → Distribute → App Store Connect (TestFlight).
3. Gerçek cihazda dene:
   - iCloud yedekleme
   - Widget'lar (Ana Ekran: Günün kelimesi, Seri, Günün Bulmacası; Kilit Ekranı: Seri, Günün kelimesi)
   - Sandbox hesabıyla satın alma
4. Firebase App Check:
   - Konsolda App Check → iOS uygulaması → App Attest'i kaydet (Team ID: D4VYL8Q23D).
   - Debug çalıştırmada Xcode konsoluna düşen debug token'ı "Manage debug tokens"a ekle.
   - Her şey çalışınca Firestore için "Enforce" yap.

## 4. Firebase içerik yükleme (isteğe bağlı, güncellemesiz yeni içerik için)
Uygulama bütün içeriği gömülü taşıyor (338 bulmaca, 1.000+ kelime), bu adım olmadan da çalışır.
Firestore'a yüklemek için bir kez:
```bash
gcloud auth application-default login
```
```bash
pip install firebase-admin && python3 tools/content/upload_firebase.py --project cengelish
```

## 5. Marka
- TÜRKPATENT'te sınıf 9 ve 41'de "Çengelish" ve "Çengel" araması yap.
- `cengelish.app` alan adını ve `@cengelish` sosyal hesaplarını al. Paylaşım kartındaki bağlantı
  `https://cengelish.app`.
- IELTS (British Council/IDP/Cambridge) ve TOEFL (ETS) tescilli markalar. "IELTS kelimeleri" gibi
  tanımlayıcı kullanım yaygın, ama App Review sorarsa resmi bağlantı olmadığını belirtmek gerekebilir.

## 6. İçerik kontrolü
`tools/content/words.psv` dosyasında 1.229 kelime var:
- İpucu, anlam, ABD ve İngiliz IPA'sı, örnek cümle ve Türkçesi.
- 5 sınav etiketi (yds, yokdil, lgs, ielts, toefl), 6 tema ve C1 seti.

Bir öğretmene baktırman iyi olur. Düzeltme sonrası:
```bash
python3 tools/content/generate.py --start 2026-11-09 --days 60
```
