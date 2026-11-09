import DesignKit
import Foundation
import Testing
import UserDataKit
@testable import OnboardingModule

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {

  @Test("Adımlar sırayla ilerler ve geri gider")
  func steps() {
    let sut = OnboardingViewModel(userData: UserDataStore(inMemory: true), onFinish: {})
    sut.next()
    #expect(sut.step == .profile)
    sut.back()
    #expect(sut.step == .welcome)
  }

  @Test("Takma ad 16 karakterle sınırlanır")
  func nicknameLimit() {
    let sut = OnboardingViewModel(userData: UserDataStore(inMemory: true), onFinish: {})
    sut.setNickname(String(repeating: "a", count: 30))
    #expect(sut.nickname.count == 16)
  }

  @Test("Bitince profil kaydedilir ve akış kapanır")
  func complete() async {
    let store = UserDataStore(inMemory: true)
    var finished = false
    let sut = OnboardingViewModel(userData: store, onFinish: { finished = true })
    sut.setNickname("Deniz")
    sut.reminderOn = false
    sut.useICloud = false
    await sut.complete()
    #expect(finished)
    #expect(store.profile?.nickname == "Deniz")
  }
}
