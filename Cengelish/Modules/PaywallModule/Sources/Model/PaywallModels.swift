import Foundation

/// Paywall'un üstündeki iki sekme: ömür boyu Plus ve tek seferlik sınav paketleri.
enum PaywallTab: String, CaseIterable, Identifiable {
  case plus
  case packs

  /// Sekme kimliği.
  var id: String { rawValue }

  /// Sekme başlığı.
  var title: String {
    switch self {
    case .plus: "Çengelish Plus"
    case .packs: "Sınav paketleri"
    }
  }

  /// Sekme simgesi (SF Symbol).
  var systemImage: String {
    switch self {
    case .plus: "crown.fill"
    case .packs: "graduationcap.fill"
    }
  }
}

/// Paywall'daki bir plan satırı (ömür boyu Plus ya da sınav paketi).
struct PlanOption: Identifiable, Equatable {
  /// Ürün kimliği.
  let id: String
  /// Başlık ("Ömür boyu", "YDS").
  let title: String
  /// Alt satır ("Tek ödeme · tüm bulmacalar ve 5 sınav paketi").
  let detail: String
  /// Fiyat.
  let price: String
  /// Fiyatın birimi ("tek sefer").
  let unit: String?
  /// Köşe rozeti ("Paketlerden %46 ucuz").
  let badge: String?
  /// Önerilen seçenek mi (altın vurgu).
  let isRecommended: Bool
  /// Kullanıcının zaten sahip olduğu ürün mü.
  let isOwned: Bool
}

/// Seçime göre değişen avantaj satırı.
struct Benefit: Identifiable, Equatable {
  /// Kararlı kimlik (animasyonlu geçiş için).
  let id: String
  /// SF Symbol adı.
  let systemImage: String
  /// Başlık.
  let title: String
  /// Açıklama.
  let detail: String
  /// Seçimde dahil mi; `false` ise "Plus'ta var, bu pakette yok" satırıdır.
  let isIncluded: Bool
}

/// Paywall'un gösterdiği aşama: planlar ya da açılmış (üye / yeni satın alınmış) durum.
enum PaywallStage: Equatable {
  /// Planlar ve satın alma.
  case plans
  /// Paywall açıldığında Çengelish Plus zaten aktifti: üyelik durumu gösterilir.
  case member
  /// Çengelish Plus az önce satın alındı ya da geri yüklendi: kutlama ve hoş geldin.
  case welcome
  /// Sınav paketi az önce satın alındı (ürün kimliği).
  case packUnlocked(String)

  /// Az önce satın alma ya da geri yükleme yapıldı mı (kutlama animasyonu ve titreşim).
  var isCelebration: Bool {
    switch self {
    case .welcome, .packUnlocked: true
    case .plans, .member: false
    }
  }
}

/// Üyelik kartındaki bir bilgi satırı ("Plan · Çengelish Plus Ömür Boyu").
struct MembershipFact: Identifiable, Equatable {
  /// Kararlı kimlik.
  let id: String
  /// SF Symbol adı.
  let systemImage: String
  /// Etiket ("Plan").
  let label: String
  /// Değer ("Aktif · süresiz").
  let value: String
}
