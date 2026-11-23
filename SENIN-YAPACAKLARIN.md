# Çengelish — Senin yapacakların

Kod, Crashlytics, GitHub Pages ve App Store Connect'in neredeyse tamamı hazır. Aşağıda yalnızca senin
hesabınla ya da yasal beyanınla yapılması gereken birkaç adım kaldı.

## Hazır olanlar (bilgi için)
- **GitHub:** `iOSDevHasan/-engelish` (herkese açık depo). `GoogleService-Info.plist` ve hizmet hesabı
  anahtarları `.gitignore`'da.
- **GitHub Pages:** destek `https://iosdevhasan.github.io/-engelish/`, gizlilik
  `https://iosdevhasan.github.io/-engelish/gizlilik.html` (kaynak: `docs/`).
- **Firebase (`cengelish`):** yalnızca **Crashlytics** (çökme raporu) kullanılıyor; içerik, Firestore,
  App Check ve Analytics yok. Tüm bulmacalar uygulamanın içinde, uygulama içerik için ağa çıkmaz.
  dSYM'ler Release derlemesinde (Archive) "Crashlytics dSYM" adımıyla otomatik yüklenir.
- **App Store Connect (Çengelish, 6832412024):**
  - Ad, alt başlık, kategori, yaş sınırı 4+, açıklama, anahtar kelimeler, tanıtım metni, destek URL'si,
    telif, App Review notu ve iletişim bilgileri girildi.
  - Gizlilik politikası URL'si girildi. App Privacy "Data Not Collected" olarak yayınlandı; Crashlytics
    nedeniyle **güncellenmesi gerekiyor** (aşağıda 1. madde).
  - Ekran görüntüleri yüklendi: iPhone 6.3" (tüm iPhone'larda kullanılır) ve iPad 13", beşer tane.
    Kaynaklar `docs/store/screenshots/`; yeniden üretmek için `tools/store_frame.py`.
  - Fiyat: ücretsiz, 175 ülke. Paid Apps sözleşmesi GolBil'den dolayı zaten aktif.
  - 5 sınav paketi (YDS, YÖKDİL, LGS, IELTS, TOEFL; hepsi 199,99 ₺).
  - **Satış modeli değişti (23 Kasım 2026):** abonelik yok. Plus artık tek seferlik "ömür boyu"
    ürün. Aşağıdaki 0. maddeyi yap.
  - Build 1.0 (1) TestFlight'a yüklendi.

## 0. App Store Connect — abonelikten ömür boyu Plus'a geçiş
- **In-App Purchases → +** → tür **Non-Consumable**, Reference Name "Çengelish Plus Ömür Boyu",
  Product ID `com.hasangurbuz.cengelish.plus.lifetime` (kod bu kimliği kullanıyor, birebir aynı olmalı).
  Fiyat: lansman 999,99 ₺, sonra 1.499,99 ₺ (paywall "Lansmana özel · sonra 1.499,99 ₺" yazar;
  artış ASC'de zamanlanmalı, yoksa bu metin yanıltıcı olur). Türkçe ad + açıklama ve inceleme
  ekran görüntüsü ekle.
- **Subscriptions → Çengelish Plus** grubundaki yıllık ve aylık abonelikleri sürüme ekleme; hiç
  incelemeye gönderilmediyse silebilirsin. (Silinen ürün kimliği bir daha kullanılamaz.)
- Mağaza açıklamasını `docs/store/tr-description.txt`'teki yeni metinle güncelle (abonelik ve
  deneme cümleleri çıkarıldı).
- Paywall ekran görüntüsü yıllık/aylık planları gösteriyorsa yenile.
- Yeni build al ve TestFlight'a yükle (1.0 (1) eski abonelik paywall'unu içeriyor).

## 0b. Mağaza görselleri, video, CPP ve Search Ads — **23 Kasım 2026'da ASC'ye yüklendi**
- Yüklü: iPhone (orta ekran kümesi, 1206×2622'ye ölçekli) 1 video + 7 kare, poster 8,7 sn; iPad 13" 6 kare;
  Header (3840×1646) ve Search Results (3840×2560) görselleri; yeni açıklama ve App Review notu;
  ömür boyu Plus'ın inceleme görseli + notu; 3 CPP (YDS ve YÖKDİL, LGS, IELTS ve TOEFL) "Ready to Submit".
- iPhone Duo (açık iç ekran, 2853×2007) 5 kare + video yüklendi (`docs/store/screenshots/v2/duo/`).
- Build **1.0 (2)** 23 Kasım'da ASC'ye yüklendi (arşiv: `../build-archive/Cengelish-1.0-2.xcarchive`).
- iPhone Duo mürekkep sorunu (23 Kasım): ilk seferde yeni oluşturulmuş bir Duo simülatöründe, açık iç
  ekranda canlı mürekkep görünmedi (çizgiler kaydedildi). Aynı adımlarla (temiz kurulum, kapalıyken açılış,
  menteşeyi açma, bulmaca) 4 denemede tekrar etmedi; kapalı ekranda ve katlama geçişinde de sorun yok.
  Kod değiştirilmedi. TestFlight'ta gerçek Duo'da bir kez kalemle yazıp kontrol et.
- Kalan: işlenince build 1.0 (2)'yi sürüme seçmek; CPP'leri uygulama onaylandıktan sonra incelemeye göndermek;
  Search Ads'te reklam varyasyonlarını CPP'lere bağlamak; 1.499,99 ₺ fiyat artışını zamanlamak.
- **Ürün sayfası (tr):** `docs/store/screenshots/v2/` → iPhone 6,9" 7 kare (`iphone69-*`), iPad 13" 6 kare
  (`ipad13-*`). Sıra bilerek böyle: arama sonucunda video + ilk 2 kare görünür (önizleme:
  `arama-sonucu-onizleme.png`).
- **App Preview:** `docs/store/video/cengelish-onizleme.mp4` (886×1920, 26,5 sn, seslendirme + Puzzle Steps
  müziği). Poster karesi: **8,7 sn** (el yazısıyla HOT). Yalnızca iPhone 6,9" setine eklenir.
- **Özel Ürün Sayfaları (CPP):** `cpp-yds/`, `cpp-lgs/`, `cpp-ielts/` (her biri 5 iPhone karesi). Önerilen
  tanıtım metinleri: YDS/YÖKDİL "YDS ve YÖKDİL kelimelerini bulmacayla çalış", LGS "LGS İngilizcesine
  bulmacayla hazırlan", IELTS/TOEFL "IELTS ve TOEFL kelimelerini bulmacayla öğren". CPP'ler incelemeye
  ayrıca girer.
- **Apple Search Ads:** CPP'ler onaylanınca reklam grupları (YDS/YÖKDİL, LGS, IELTS/TOEFL anahtar
  kelimeleri) için **ad variation** olarak seçilir; reklam görseli ayrıca üretilmez, CPP'nin ilk kareleri
  kullanılır.
- **Yeniden üretmek:** `tools/store_shots/build.py <iphone|ipad> <ham> <çıktı> [main|cpp-yds|cpp-lgs|cpp-ielts]`,
  `tools/store_video/build.py` (ham ekran kaydı: `../build-archive/magaza-video/ekran-kaydi.mp4`).
- **Lisans:** ElevenLabs müzik ve seslendirmesinin ticari kullanımı ücretli planda serbest; planını doğrula.
- IELTS ve TOEFL tescilli markalar; App Review sorarsa içerikle resmi bağlantı olmadığını yaz.

## 1. App Store Connect — senin beyanın gereken adımlar
- **App Privacy → Edit:** "Data Not Collected" yerine "Yes, we collect data" → **Diagnostics**:
  - **Crash Data:** App Functionality; kullanıcıya bağlı değil (Not Linked); izleme yok.
  - **Other Diagnostic Data:** App Functionality + Analytics; kullanıcıya bağlı değil; izleme yok.
  Kaynak: Crashlytics, Firebase Installations ve GoogleDataTransport SDK'larının kendi gizlilik
  manifestleri. Sonra **Publish**. (Gizlilik sayfaları `docs/` altında güncellendi; GitHub'a
  gönderilince yayına girer.)
- **App Information → Content Rights → Set Up:** "No, it does not contain, show, or access
  third-party content" → Done → Save. (Yasal beyan olduğu için ben işaretleyemedim.)

## 2. İncelemeye gönderme
1. Sürüm sayfasında **Build** bölümünden 1.0 (1)'i seç (işlenmesi 10–30 dk sürer).
2. Ömür boyu Plus ve sınav paketlerinin "Ready to Submit" olduğunu kontrol et; ilk sürümde sürümle birlikte
   incelemeye girmeleri için sürüm sayfasındaki **In-App Purchases and Subscriptions** bölümünden ekle.
3. **Add for Review → Submit**.

## 3. Gerçek cihazda dene (TestFlight)
- iCloud yedekleme, widget'lar (Ana Ekran: Günün kelimesi, Seri, Günün Bulmacası; Kilit Ekranı: Seri,
  Günün kelimesi), Sandbox hesabıyla satın alma.
- Crashlytics: TestFlight build'inde uygulama ilk açıldıktan sonra Firebase konsolu → Crashlytics
  panosu etkinleşir. Hata ayıklama (Debug) derlemeleri rapor göndermez.
- İstersen Firebase konsolunda artık kullanılmayan Firestore veritabanını ve App Check kaydını silebilirsin.

## 4. Marka
- TÜRKPATENT'te sınıf 9 ve 41'de "Çengelish" ve "Çengel" araması.
- `cengelish.app` alan adı ve `@cengelish` sosyal hesaplar (paylaşım kartındaki bağlantı
  `https://cengelish.app`).
- IELTS ve TOEFL tescilli markalar; App Review sorarsa resmi bağlantı olmadığını belirt.

## 5. İçerik kontrolü
`tools/content/words.psv` (5.222 kelime; dosyanın sonundaki "Kasım 2026 eki" bölümlerindeki
yaklaşık 4.000 kelime ve 14 Kasım'da eklenen 973 tema kelimesi yapay zekayla yazıldı) bir öğretmene baktırılırsa iyi olur; özellikle Türkçe ipuçları ve IPA. Düzeltme sonrası:
```bash
python3 tools/content/generate.py --start 2026-11-09 --days 365
```

## Not: mağaza görüntüleri
Debug derlemeyi `-screenshotDemo` başlatma argümanıyla açınca (profil yokken) örnek veri yüklenir:
14 günlük seri, biten bulmacalar, defter ve rozetler. Release derlemede bu kod yoktur.
