import ContentKit
import DesignKit
import Foundation
import UserDataKit

/// Onboarding adımları.
enum OnboardingStep: Int, CaseIterable {
  case welcome, profile, level, goal, data
}

/// Sınav ve öğrenme amaçları.
enum LearningGoal: String, CaseIterable, Identifiable {
  case general = "genel"
  case yds, yokdil, lgs, ielts

  var id: String { rawValue }

  /// Ekranda görünen ad.
  var title: String {
    switch self {
    case .general: "Genel İngilizce"
    case .yds: "YDS"
    case .yokdil: "YÖKDİL"
    case .lgs: "LGS"
    case .ielts: "IELTS"
    }
  }
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
  @Published var useICloud = true

  /// Takma ad için en fazla karakter.
  let nicknameLimit = 16
  /// Onboarding'de seçilebilen aksesuarlar (kilitsiz olanlar).
  let freeAccessories: [AvatarAccessory] = [.none, .glasses, .cap]
  private let userData: any UserDataStoring
  private let onFinish: @MainActor () -> Void

  // MARK: - Init

  init(userData: any UserDataStoring, onFinish: @escaping @MainActor () -> Void) {
    self.userData = userData
    self.onFinish = onFinish
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

  /// Takma adı sınırla günceller.
  func setNickname(_ value: String) {
    nickname = String(value.prefix(nicknameLimit))
  }

  /// Profili, ayarları ve veri tercihini kaydedip akışı bitirir.
  func complete() async {
    let profile = UserProfile(
      nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
      avatar: avatar,
      level: (level ?? .a1).rawValue,
      goals: goals.map(\.rawValue).sorted(),
      dailyGoal: dailyGoal
    )
    userData.setICloudBackup(useICloud)
    if reminderOn {
      let granted = await ReminderScheduler.requestPermission()
      userData.updateSettings { $0.reminderEnabled = granted }
      ReminderScheduler.apply(userData.settings)
    }
    userData.createProfile(profile)
    onFinish()
  }
}
