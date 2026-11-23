# PuzzleModule

**Layer**: Modules
**Purpose**: Bulmaca çözme: PencilKit ile kalem/kurşun/silgi ve klavye modu, sadece harf kutularına yazma, iki parmakla zoom, odak modu, ipucu ve tema panelleri, cevap anahtarı (✓/✗), bitiş (kutlama) ve paylaşım kartı.

## Public API

```swift
@MainActor protocol PuzzleModuleInterface: AnyObject
  func createPuzzleView(puzzleId:) -> AnyView
```

## Structure

```
InterfaceSources/PuzzleModuleInterface.swift
Package.swift
Sources/Canvas/DrawingCanvas.swift      # PencilKit alanı (CanvasContainerView: arkada ızgara, önde
                                        # inkRects ile maskeli çizim); onViewport ile zoom bildirir
Sources/Canvas/KeyboardInput.swift      # Klavye modu: görünmez UIKeyInput, sistem klavyesini açık tutar
Sources/Canvas/StrokeMath.swift         # split / clip (çizgiyi harf kutularına kırpar) / transform
Sources/Model/PuzzleSession.swift
Sources/Model/PuzzlePresentation.swift  # PuzzleLayoutMode, EntryNavigation, TypedInput, HintPicker,
                                        # MarkSummary, ZoomText, ShareText
Sources/PuzzleCoordinator.swift         # bulmaca → anahtar → bitiş → paylaş
Sources/View/AnswerKeyView.swift
Sources/View/FinishView.swift           # konfeti + zıplayan yıldızlar (Hareketi Azalt'ta kapalı)
Sources/View/FocusView.swift            # FocusView + FoldFocusPanel ve ortak parçalar (FocusBoxes…)
Sources/View/PuzzlePanels.swift         # CluePanel (iPad), ZoomOverlay (yüzde, mini harita, ipucu)
Sources/View/PuzzleSheets.swift         # HintSheet, ThemeSheet (appBottomSheet içeriği, kendi
                                        # ScrollView'u yok; dismissAppSheet ile kapanır)
Sources/View/PuzzleView.swift           # telefon / iPad / katlanabilir yerleşimler, PuzzleToolbar
Sources/View/ShareView.swift            # ShareView, ShareCardView, ShareStoryView (9:16)
Sources/ViewModel/AnswerKeyViewModel.swift
Sources/ViewModel/FinishViewModel.swift
Sources/ViewModel/PuzzleViewModel.swift
Sources/ViewModel/ShareViewModel.swift  # ShareCard, PhotoSaving / PhotoLibrarySaver
Sources/ViewModel/ZoomState.swift       # CanvasViewport, tek seferlik zoom ipucu (UserDefaults)
Tests/PuzzleInputTests.swift            # ipucu (#13), klavye, mürekkep kırpma
Tests/PuzzlePresentationTests.swift
Tests/PuzzleViewModelTests.swift
```

## Notes

- Mürekkep sadece açılmamış harf kutularında durur: `PuzzleViewModel.inkRects` (odakta
  `focusInkRects`) çizim katmanını maskeler ve biten her çizgi `StrokeMath.clip` ile kutulara
  kırpılır (kutudan kutuya taşan çizgi kutu başına bölünür, ipucu / blok / ızgara dışı atılır).
  Eski kayıtlı çizimler yüklenirken de kırpılır.
- Klavye modu (araç çubuğunda "Klavye"): kutuya dokunmak kutuyu ve kelimeyi seçer (aynı kutuya
  tekrar dokunmak kesişimde yönü değiştirir); harf yazılır ve sonraki kutuya geçilir, silme
  tuşu kutuyu temizler / geri gider, "Sonraki" sonraki kelimeye geçer. Harfler `typed` olarak
  `PuzzleProgress.typedLetters`'ta saklanır, el yazısı yazı tipiyle (Noteworthy) kalem renginde
  çizilir; ipucu harfleri ayrı (yuvarlak, anahtar rengi). Son yazılan geçerlidir: kutuya harf
  yazmak oradaki mürekkebi, kutuya mürekkep yazmak oradaki harfi siler. Klavye harfleri doluluk
  (iPad ✓ listesi), cevap anahtarı ve odak görünümünde sayılır.
- İpucu: harf ipucu seçili kutuyu (açıksa sonraki kapalı kutuyu) açar ve etkin kutuyu sonraki
  kapalı kutuya taşır; açılan kutudaki mürekkep / harf silinir; kelimede kapalı kutu yoksa hak
  harcanmaz. Hak yetmeyen seçenek pasif, paywall girişi `PlusPromoCard`.
- Klavyeyle kelimenin son harfi yazılınca (otomatik ilerleme açıksa) sıradaki eksik kelime
  seçilir; bulmaca dolunca klavye kapanır ("Bitirdim" görünsün), kutuya dokununca yeniden açılır.
- Bitirme: "Bitirdim" yalnızca tüm harf kutuları (kalem, klavye ya da ipucu) doluyken açılır;
  boş kutu varken basınca ilk boş kutunun kelimesi seçilir ve "N kutu boş" balonu çıkar
  (`finishTapped`, `emptyCells`, `canFinish`). Cevap anahtarının iki amacı vardır
  (`AnswerKeyPurpose`): `.peek` (çözerken "Cevap anahtarı": sadece bakılır, "Bulmacaya dön")
  ve `.finish` ("Bitirdim" sonrası): her kelime ✓ ya da ✗ işaretlenmeden "Sonuçları gör"
  sonuç ekranına geçmez; erken basınca işaretsiz satırlar kırmızı çerçevelenir ve ilkine kaydırılır.
  Bitiş ekranı, kelimelerin hepsi doğru olduğu hâlde ipucu yüzünden yıldız eksikse nedenini yazar.
- "Sonraki bulmaca" (`PuzzleCoordinator.openNext`) bulmaca, cevap anahtarı ve bitiş ekranını
  yığından çıkarıp yerine yeni bulmacayı koyar; altındaki paket ekranı kalır. RouterKit her rotayı
  kendi kimliğiyle çizdiği için yeni bulmaca eskisinin durumunu (view model) devralmaz.
- Bitmiş bulmaca (`progress.finishedAt` dolu) salt okunur açılır (`isCompleted`): tüm kutularda
  doğru cevap görünür, mürekkep ve klavye harfleri gösterilmez, sayaç durur, hiçbir şey
  kaydedilmez. Araç çubuğu, ipucu, odak, "Cevap anahtarı" ve "Bitirdim" yoktur; yerlerinde
  `CompletedNote` ("Bu bulmacayı bitirdin · x/y kelime doğru") durur. Dokunuş yalnızca kelime seçer;
  tuvalde çizim kapalıdır (`isDrawingEnabled`, araçtan sonra kapatılır; gelen çizgi geri alınır).
- Tuval (`ZoomingCanvasView`) PencilKit'in düzenleme menüsünü ("Tümünü Seç", "Boşluk Ekle")
  açmaz ve ilk yanıtlayıcı olmaz; klavye odağı ve ekran yerleşimi korunur.
- Geri al / İleri view model'dedir (`undo()` / `redo()`, `canUndo` / `canRedo`, en fazla 100
  adım): çizgi, silgi, klavye harfi, silme ve temizleme tek geçmişte (`InkSnapshot`: ızgara ve
  odak çizimi + klavye harfleri). Odak modu açılıp kapanınca ve ipucundan sonra geçmiş sıfırlanır.
- Tuval modele yeni çizimi PencilKit'in çiziminden değil, modelin bildiği çizimden kurar
  (`Coordinator.commit`): son görülenden sonra başlamış çizgiler (tarihine göre) eklenir, silgi
  yalnızca modeldeki çizgileri kaldırır. PencilKit geri alınmış çizgileri tuvalde tutup sonraki
  çizgiyle geri getirebildiği için (harfler üst üste biniyordu) bu çizgiler alınmaz ve tuvalden de
  silinir.
- Silgi klavye harflerini de siler: tuvalde silgi seçiliyken bir basılı-tut algılayıcısı geçilen
  noktaları bildirir (`onErase` → `erase(at:)` / `focusErase(at:)`); harf silme geri alınabilir.

- İpucu ve tema panelleri DesignKit `appBottomSheet` ile açılır (PuzzleView; odak modunda
  ipucu paneli FocusView'dan). Kilitli Plus temasına dokunmak paneli kapatıp paywall'u açar.
  Tema paneli açılınca seçili temaya kaydırır.

- Yerleşim: genişlik ≥ 600 ve en/boy 0.8–1.3 → katlanabilir (ızgara + yan odak alanı, yazılar
  ızgaraya anında yansır); değilse regular genişlikte iPad, aksi halde telefon.
- Kaydet (Fotoğraflar) için uygulama Info.plist'inde `NSPhotoLibraryAddUsageDescription` gerekir;
  anahtar yoksa izin istenmez, kullanıcıya "Kaydedilemedi" bildirilir.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PaywallModuleInterface, SettingsModuleInterface
