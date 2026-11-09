import Testing
import SwiftUI
@testable import RouterKit
import RouterKitInterface

@Suite("AppRouter Tests")
@MainActor
struct RouterKitTests {

  let sut = AppRouter()

  @Test("Push adds view to stack")
  func push_addsViewToStack() {
    // Given
    let view = Text("Test View")

    // When
    sut.push(view)

    // Then
    #expect(sut.navigationPath.count == 1)
  }

  @Test("Push multiple views adds all to stack")
  func push_multipleViews_addsAllToStack() {
    // Given - empty stack

    // When
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))
    sut.push(Text("View 3"))

    // Then
    #expect(sut.navigationPath.count == 3)
  }

  @Test("Pop removes last view from stack")
  func pop_removesLastViewFromStack() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))

    // When
    sut.pop()

    // Then
    #expect(sut.navigationPath.count == 1)
  }

  @Test("Pop on empty stack does nothing")
  func pop_onEmptyStack_doesNothing() {
    // Given - empty stack

    // When
    sut.pop()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("Pop all views empties stack")
  func pop_allViews_emptiesStack() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))

    // When
    sut.pop()
    sut.pop()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("Pop more than stack size empties stack safely")
  func pop_moreThanStackSize_emptiesStackSafely() {
    // Given
    sut.push(Text("View 1"))

    // When
    sut.pop()
    sut.pop()
    sut.pop()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("Pop count removes multiple views")
  func popCount_removesMultipleViews() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))
    sut.push(Text("View 3"))
    sut.push(Text("View 4"))

    // When
    sut.pop(count: 2)

    // Then
    #expect(sut.navigationPath.count == 2)
  }

  @Test("Pop count more than stack size empties safely")
  func popCount_moreThanStackSize_emptiesSafely() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))

    // When
    sut.pop(count: 10)

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("PopToRoot clears all pushed views")
  func popToRoot_clearsAllPushedViews() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))
    sut.push(Text("View 3"))
    sut.push(Text("View 4"))

    // When
    sut.popToRoot()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("PopToRoot with single view clears it")
  func popToRoot_withSingleView_clearsIt() {
    // Given
    sut.push(Text("Only View"))

    // When
    sut.popToRoot()

    // Then - Path is cleared
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("PopToRoot on empty stack does nothing")
  func popToRoot_onEmptyStack_doesNothing() {
    // Given - empty stack

    // When
    sut.popToRoot()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("StackCount returns correct count")
  func stackCount_returnsCorrectCount() {
    // Given
    #expect(sut.stackCount == 0)

    // When
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))

    // Then
    #expect(sut.stackCount == 2)
  }

  @Test("ClearStack removes all views")
  func clearStack_removesAllViews() {
    // Given
    sut.push(Text("View 1"))
    sut.push(Text("View 2"))
    sut.push(Text("View 3"))
    #expect(sut.stackCount == 3)

    // When
    sut.clearStack()

    // Then
    #expect(sut.stackCount == 0)
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("ClearStack on empty stack does nothing")
  func clearStack_onEmptyStack_doesNothing() {
    // Given - empty stack

    // When
    sut.clearStack()

    // Then
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("SetRoot replaces entire stack")
  func setRoot_replacesEntireStack() {
    // Given
    sut.push(Text("Old Root"))
    sut.push(Text("Old View 2"))
    sut.push(Text("Old View 3"))

    // When
    sut.setRoot(Text("New Root"))

    // Then
    #expect(sut.navigationPath.count == 1)
  }

  @Test("SetRoot on empty stack sets root")
  func setRoot_onEmptyStack_setsRoot() {
    // Given - empty stack

    // When
    sut.setRoot(Text("New Root"))

    // Then
    #expect(sut.navigationPath.count == 1)
  }

  @Test("RegisterDeepLink registers handler")
  func registerDeepLink_registersHandler() {
    // Given
    var handlerCalled = false

    // When
    sut.registerDeepLink(.submenu) {
      handlerCalled = true
      return Text("SubMenu")
    }
    let url = URL(string: "app://submenu")!
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(handled)
    #expect(handlerCalled)
  }

  @Test("HandleDeepLink with host navigates to registered view")
  func handleDeepLink_withHost_navigatesToRegisteredView() {
    // Given
    sut.registerDeepLink(.submenu) { Text("SubMenu") }
    let url = URL(string: "myapp://submenu")!

    // When
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(handled)
    #expect(sut.navigationPath.count == 1)
  }

  @Test("HandleDeepLink with path navigates to registered view")
  func handleDeepLink_withPath_navigatesToRegisteredView() {
    // Given
    sut.registerDeepLink(.submenu) { Text("SubMenu") }
    let url = URL(string: "https://example.com/submenu")!

    // When
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(handled)
    #expect(sut.navigationPath.count == 1)
  }

  @Test("HandleDeepLink unregistered path returns false")
  func handleDeepLink_unregisteredPath_returnsFalse() {
    // Given
    let url = URL(string: "myapp://unknown")!

    // When
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(!handled)
    #expect(sut.navigationPath.isEmpty)
  }

  @Test("HandleDeepLink is case insensitive")
  func handleDeepLink_caseInsensitive_works() {
    // Given
    sut.registerDeepLink(.submenu) { Text("SubMenu") }
    let url = URL(string: "myapp://SUBMENU")!

    // When
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(handled)
  }

  @Test("HandleDeepLink replaces existing stack")
  func handleDeepLink_replacesExistingStack() {
    // Given
    sut.push(Text("Existing View 1"))
    sut.push(Text("Existing View 2"))
    sut.registerDeepLink(.submenu) { Text("SubMenu") }
    let url = URL(string: "myapp://submenu")!

    // When
    let handled = sut.handleDeepLink(url)

    // Then
    #expect(handled)
    #expect(sut.navigationPath.count == 1)
  }

  @Test("Full navigation flow works correctly")
  func fullNavigationFlow() {
    // When
    sut.push(Text("View 1"))
    sut.push(Text("Detail"))
    sut.push(Text("Settings"))

    // Then
    #expect(sut.navigationPath.count == 3)

    // When
    sut.pop()

    // Then
    #expect(sut.navigationPath.count == 2)

    // When
    sut.popToRoot()

    // Then
    #expect(sut.navigationPath.isEmpty)

    // When - Set new root
    sut.setRoot(Text("New Root"))

    // Then
    #expect(sut.navigationPath.count == 1)
  }
}

private extension DeepLinkPath {
  static let submenu: Self = "submenu"
}
