import Testing
@testable import HomeModule

struct HomeViewModelTests {

  @Test("Haftalık gün yapısı eşitlik karşılaştırmasını destekler")
  func weekDayEquality() {
    let day = WeekDay(id: "2026-11-09", label: "Pt", isSolved: true, isToday: true)
    #expect(day == WeekDay(id: "2026-11-09", label: "Pt", isSolved: true, isToday: true))
  }
}
