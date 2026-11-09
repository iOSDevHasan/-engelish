# Çengelish — Senin yapacakların

Kod, Firebase, GitHub Pages ve App Store Connect'in neredeyse tamamı hazır. Aşağıda yalnızca senin
hesabınla ya da yasal beyanınla yapılması gereken birkaç adım kaldı.

## Hazır olanlar (bilgi için)
- **GitHub:** `iOSDevHasan/-engelish` (herkese açık depo). `GoogleService-Info.plist` ve hizmet hesabı
  anahtarları `.gitignore`'da.
- **GitHub Pages:** destek `https://iosdevhasan.github.io/-engelish/`, gizlilik
  `https://iosdevhasan.github.io/-engelish/gizlilik.html` (kaynak: `docs/`).
- **Firebase (`cengelish`):** iOS uygulaması kayıtlı, plist projede, Firestore (europe-west3) ve
  kurallar hazır.
- **App Store Connect (Çengelish, 6832412024):**
  - Ad, alt başlık, kategori, yaş sınırı 4+, açıklama, anahtar kelimeler, tanıtım metni, destek URL'si,
    telif, App Review notu ve iletişim bilgileri girildi.
  - Gizlilik politikası URL'si girildi; App Privacy "Data Not Collected" olarak yayınlandı.
  - Ekran görüntüleri yüklendi: iPhone 6.3" (tüm iPhone'larda kullanılır) ve iPad 13", beşer tane.
    Kaynaklar `docs/store/screenshots/`; yeniden üretmek için `tools/store_frame.py`.
  - Fiyat: ücretsiz, 175 ülke. Paid Apps sözleşmesi GolBil'den dolayı zaten aktif.
  - "Çengelish+" abonelikleri (yıllık 449,99 ₺ + 7 gün deneme, aylık 74,99 ₺) ve 5 sınav paketi
    (YDS, YÖKDİL, IELTS, TOEFL 199,99 ₺; LGS 129,99 ₺) hazır.
  - Build 1.0 (1) TestFlight'a yüklendi.

## 1. App Store Connect — senin beyanın gereken tek adım
- **App Information → Content Rights → Set Up:** "No, it does not contain, show, or access
  third-party content" → Done → Save. (Yasal beyan olduğu için ben işaretleyemedim.)

## 2. İncelemeye gönderme
1. Sürüm sayfasında **Build** bölümünden 1.0 (1)'i seç (işlenmesi 10–30 dk sürer).
2. Abonelik ve paketlerin "Ready to Submit" olduğunu kontrol et; ilk sürümde sürümle birlikte
   incelemeye girmeleri için sürüm sayfasındaki **In-App Purchases and Subscriptions** bölümünden ekle.
3. **Add for Review → Submit**.

## 3. Gerçek cihazda dene (TestFlight)
- iCloud yedekleme, widget'lar (Ana Ekran: Günün kelimesi, Seri, Günün Bulmacası; Kilit Ekranı: Seri,
  Günün kelimesi), Sandbox hesabıyla satın alma.
- Firebase App Check: konsolda App Check → iOS uygulaması → App Attest'i kaydet (Team ID:
  D4VYL8Q23D); her şey çalışınca Firestore için "Enforce" yap.

## 4. Firebase içerik yükleme (isteğe bağlı)
Uygulama bütün içeriği gömülü taşıyor (338 bulmaca, 1.000+ kelime). Güncellemesiz yeni içerik için:
```bash
gcloud auth application-default login
```
```bash
pip install firebase-admin && python3 tools/content/upload_firebase.py --project cengelish
```

## 5. Marka
- TÜRKPATENT'te sınıf 9 ve 41'de "Çengelish" ve "Çengel" araması.
- `cengelish.app` alan adı ve `@cengelish` sosyal hesaplar (paylaşım kartındaki bağlantı
  `https://cengelish.app`).
- IELTS ve TOEFL tescilli markalar; App Review sorarsa resmi bağlantı olmadığını belirt.

## 6. İçerik kontrolü
`tools/content/words.psv` (1.229 kelime) bir öğretmene baktırılırsa iyi olur. Düzeltme sonrası:
```bash
python3 tools/content/generate.py --start 2026-11-09 --days 60
```

## Not: mağaza görüntüleri
Debug derlemeyi `-screenshotDemo` başlatma argümanıyla açınca (profil yokken) örnek veri yüklenir:
14 günlük seri, biten bulmacalar, defter ve rozetler. Release derlemede bu kod yoktur.
