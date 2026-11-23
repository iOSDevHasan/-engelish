import DesignKit
import Foundation
import UserDataKit

/// Rozet ızgarasında gösterilen tek rozet: kazanılma durumu, ilerleme ve açıklamalar.
struct BadgeItem: Identifiable, Equatable {
  /// Rozet türü.
  let kind: BadgeKind
  /// Kazanılma tarihi; kazanılmadıysa nil.
  let earnedAt: Date?
  /// Sayaçlı rozetin ilerlemesi (mevcut, hedef); anlık rozetlerde nil.
  let counter: Counter?

  /// Sayaçlı rozetin ilerlemesi.
  struct Counter: Equatable {
    /// Şu anki değer (hedefle sınırlı).
    let current: Int
    /// Hedef değer.
    let target: Int
  }

  /// Izgaradaki kimlik.
  var id: String { kind.rawValue }

  /// Rozet adı.
  var title: String { kind.title }

  /// SF Symbol.
  var symbol: String { kind.symbol }

  /// Rozet kazanıldı mı.
  var isEarned: Bool { earnedAt != nil }

  /// Halka için 0…1 tamamlanma; kazanılan rozet 1, anlık rozetler 0.
  var progress: Double {
    if isEarned { return 1 }
    guard let counter else { return 0 }
    return min(1, Double(counter.current) / Double(max(counter.target, 1)))
  }

  /// Halkada çizilen kısım: kazanılmayan rozet asla tamamlanmış görünmez (en fazla %93).
  var ringFraction: Double {
    isEarned ? 1 : min(progress, Self.maxRingFraction)
  }

  /// "7/10" ya da anlık rozetler için "Tek bulmacada kazanılır".
  var progressText: String {
    guard let counter else { return "Tek bulmacada kazanılır" }
    return "\(counter.current)/\(counter.target)"
  }

  /// Rozetin ne anlama geldiği.
  var meaning: String { kind.meaning }

  /// Nasıl kazanıldığı ("10 bulmaca bitir").
  var requirement: String { kind.detail }

  /// Rozetle gelen ödül; yoksa nil.
  var reward: String? { kind.reward }

  /// Halkanın en fazla dolduğu oran; yuvarlak uçlar %97 civarında halkayı kapatır.
  static let maxRingFraction = 0.93

  /// Rozeti kazanılma tarihi ve sayaçlarla oluşturur.
  static func make(
    _ kind: BadgeKind, earnedAt: Date?, snapshot: AchievementSnapshot
  ) -> BadgeItem {
    let counter = kind.progress(snapshot).map { Counter(current: $0.current, target: $0.target) }
    return BadgeItem(kind: kind, earnedAt: earnedAt, counter: counter)
  }

  /// Kazanılanlar (kazanılma sırasıyla), ardından hedefe en yakın kazanılmayanlar.
  static func all(badges: [BadgeKind: Date], snapshot: AchievementSnapshot) -> [BadgeItem] {
    let items = BadgeKind.allCases.map { make($0, earnedAt: badges[$0], snapshot: snapshot) }
    let earned = items.filter(\.isEarned).sorted { ($0.earnedAt ?? .now) < ($1.earnedAt ?? .now) }
    // Sayaçsız rozetler sayaçlıların arkasına düşer; eşitlikte katalog sırası korunur.
    let upcoming = items.filter { !$0.isEarned }.enumerated()
      .sorted { lhs, rhs in
        let left = lhs.element.sortKey
        let right = rhs.element.sortKey
        return left == right ? lhs.offset < rhs.offset : left > right
      }
      .map(\.element)
    return earned + upcoming
  }

  /// Sıralama anahtarı: sayaçlı rozetlerde tamamlanma, anlık rozetlerde -1.
  private var sortKey: Double { counter == nil ? -1 : progress }
}

extension BadgeKind {
  /// Rozetin oyuncu hakkında söyledikleri (ipucu balonundaki açıklama).
  var meaning: String {
    switch self {
    case .firstPuzzle: "Çengel yolculuğuna ilk adımı attın."
    case .puzzles10: "Bulmaca çözmek artık senin için bir alışkanlık."
    case .puzzles50: "Izgaraların arasında yolunu bulan gerçek bir bulmaca kurdusun."
    case .streak7: "Bir hafta boyunca her gün kalemi eline aldın."
    case .streak30: "Bir ay boyunca hiç ara vermedin; azmin göz dolduruyor."
    case .words100: "Yüz İngilizce kelimeyi doğru yazdın; kelime dağarcığın büyüyor."
    case .words500: "Beş yüz kelimeyle sağlam bir kelime hazinesi kurdun."
    case .perfect: "İpucuna başvurmadan, tek hata yapmadan bir bulmacayı bitirdin."
    case .perfect10: "On bulmacada bütün kelimeleri doğru yazdın; dikkatin kusursuz."
    case .nightOwl: "Gece geç saatte bile kelimelerin peşindesin."
    case .earlyBird: "Güne bir bulmacayla başlayanlardansın."
    case .speed: "Bir bulmacayı üç dakikanın altında bitirecek kadar hızlısın."
    case .yds10: "YDS hazırlığında on bulmacayı geride bıraktın."
    case .daily7: "Günün Bulmacası'nı yedi kez çözdün; günlük rutinin oturdu."
    case .learned25: "Defterindeki 25 kelimeyi tekrarlarla kalıcı olarak öğrendin."
    }
  }
}
