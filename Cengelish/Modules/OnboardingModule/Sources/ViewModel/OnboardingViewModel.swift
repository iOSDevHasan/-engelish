import ContentKit
import DesignKit
import Foundation
import UserDataKit

/// Onboarding adımları.
enum OnboardingStep: Int, CaseIterable {
  case welcome, profile, level, goal, data
}

/// Sınav ve öğrenme amaçları; tema amaçlarının kimliği tema paketiyle aynıdır.
enum LearningGoal: String, CaseIterable, Identifiable {
  case general = "genel"
  case yds, yokdil, lgs, ielts, toefl
  case business = "is"
  case travel = "seyahat"
  case football = "futbol"

  var id: String { rawValue }

  /// Ekranda görünen ad.
  var title: String {
    switch self {
    case .general: "Genel İngilizce"
    case .yds: "YDS"
    case .yokdil: "YÖKDİL"
    case .lgs: "LGS"
    case .ielts: "IELTS"
    case .toefl: "TOEFL"
    case .business: "İş İngilizcesi"
    case .travel: "Seyahat"
    case .football: "Futbol"
    }
  }
}

/// Günlük hedef seçeneği.
struct DailyGoalOption: Identifiable, Equatable {
  /// Günlük bulmaca sayısı.
  let count: Int
  /// Tahmini süre ("10 dk").
  let minutes: String
  /// Tempo adı ("Düzenli").
  let pace: String

  var id: Int { count }

  /// Tasarımdaki üç seçenek.
  static let all = [
    DailyGoalOption(count: 1, minutes: "5 dk", pace: "Rahat"),
    DailyGoalOption(count: 2, minutes: "10 dk", pace: "Düzenli"),
    DailyGoalOption(count: 3, minutes: "15 dk", pace: "Ciddi"),
  ]
}

/// Onboarding durumu ve kullanıcı eylemleri.
@MainActor
final class OnboardingViewModel: ObservableObject {

  // MARK: - Properties

  @Published var step: OnboardingStep = .welcome
  @Published var avatar = AvatarConfig(body: .mint, accessory: .glasses, background: .lilac)
  @Published var nickname = ""
  @Published var level: CEFRLevel? = .a2
  @Published var goals: Set<LearningGoal> = [.general]
  @Published var dailyGoal = 2
  @Published var reminderOn = true
  @Published var reminderHour: Int
  @Published var reminderMinute: Int
  @Published var useICloud = true
  /// Açık seviye testi (sayfa olarak gösterilir).
  @Published var levelTest: LevelTestViewModel?

  /// Takma ad için en fazla karakter.
  let nicknameLimit = 16
  /// Onboarding'de seçilebilen aksesuarlar (kilitsiz olanlar).
  let freeAccessories: [AvatarAccessory] = [.none, .glasses, .cap]
  private let userData: any UserDataStoring
  private let content: any ContentProviding
  private let isPremium: @MainActor () -> Bool
  private let onFinish: @MainActor () -> Void
  private let showPaywall: @MainActor () -> Void

  // MARK: - Init

  init(
    userData: any UserDataStoring, content: any ContentProviding,
    isPremium: @escaping @MainActor () -> Bool = { false },
    onFinish: @escaping @MainActor () -> Void,
    showPaywall: @escaping @MainActor () -> Void = {}
  ) {
    self.userData = userData
    self.content = content
    self.isPremium = isPremium
    self.onFinish = onFinish
    self.showPaywall = showPaywall
    reminderHour = userData.settings.reminderHour
    reminderMinute = userData.settings.reminderMinute
  }

  // MARK: - Intents

  /// Bir sonraki adıma geçer; son adımda profili kaydeder.
  func next() {
    guard let following = OnboardingStep(rawValue: step.rawValue + 1) else {
      Task { await complete() }
      return
    }
    step = following
  }

  /// Bir önceki adıma döner.
  func back() {
    guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
    step = previous
  }

  /// Amacı ekler ya da çıkarır.
  func toggle(_ goal: LearningGoal) {
    if goals.contains(goal) {
      goals.remove(goal)
    } else {
      goals.insert(goal)
    }
  }

  /// Kısa seviye testini açar.
  func openLevelTest() {
    levelTest = LevelTestViewModel(content: content, startLevel: level ?? .a2)
  }

  /// Seviye testinin önerdiği seviyeyi seçer ve testi kapatır.
  func acceptLevel(_ suggested: CEFRLevel) {
    level = suggested
    levelTest = nil
  }

  /// Hatırlatıcı açıklaması ("Her gün 20:00 · Günün bulmacası hazır").
  var reminderDetail: String {
    String(format: "Her gün %02d:%02d · Günün bulmacası hazır", reminderHour, reminderMinute)
  }

  /// Takma adı sınırla günceller.
  func setNickname(_ value: String) {
    nickname = String(value.prefix(nicknameLimit))
  }

  /// Profili, ayarları ve veri tercihini kaydedip akışı bitirir; ardından Çengelish+ paywall'unu
  /// bir kez (kapatılabilir) gösterir.
  func complete() async {
    let profile = UserProfile(
      nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
      avatar: avatar,
      level: (level ?? .a1).rawValue,
      goals: goals.map(\.rawValue).sorted(),
      dailyGoal: dailyGoal
    )
    userData.setICloudBackup(useICloud)
    userData.updateSettings {
      $0.reminderHour = reminderHour
      $0.reminderMinute = reminderMinute
    }
    if reminderOn {
      let granted = await ReminderScheduler.requestPermission()
      userData.updateSettings { $0.reminderEnabled = granted }
      ReminderScheduler.apply(userData.settings)
    }
    userData.createProfile(profile)
    onFinish()
    if !isPremium() { showPaywall() }
  }
}
