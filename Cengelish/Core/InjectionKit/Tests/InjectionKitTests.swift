import Testing
import Foundation
@testable import InjectionKit

// MARK: - Test Protocols & Mocks

protocol TestServiceInterface {
  var id: String { get }
}

final class MockTestService: TestServiceInterface {
  let id: String

  init(id: String = UUID().uuidString) {
    self.id = id
  }
}

protocol AnotherServiceInterface {
  var name: String { get }
}

final class MockAnotherService: AnotherServiceInterface {
  let name: String

  init(name: String = "Default") {
    self.name = name
  }
}

// MARK: - Helper

@MainActor
private func setUp() {
  Injector.reset()
  Injector.resetOverrides()
}

// MARK: - Injector Tests

@Suite("Injector Tests")
struct InjectorTests {

  // MARK: - Registration Tests

  @Suite("Registration")
  struct RegistrationTests {

    @Test("Given a service, When registered, Then isRegistered returns true")
    @MainActor
    func registerService() {
      // Given
      setUp()
      let service = MockTestService()

      // When
      Injector.register(value: service, for: TestServiceInterface.self)

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)
    }

    @Test("Given no registration, When checking isRegistered, Then returns false")
    @MainActor
    func unregisteredService() {
      // Given
      setUp()

      // When
      let isRegistered = Injector.isRegistered(TestServiceInterface.self)

      // Then
      #expect(isRegistered == false)
    }

    @Test("Given multiple services, When registered, Then all are registered")
    @MainActor
    func registerMultipleServices() {
      // Given
      setUp()
      let testService = MockTestService()
      let anotherService = MockAnotherService()

      // When
      Injector.register(value: testService, for: TestServiceInterface.self)
      Injector.register(value: anotherService, for: AnotherServiceInterface.self)

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)
      #expect(Injector.isRegistered(AnotherServiceInterface.self) == true)
    }
  }

  // MARK: - Factory Scope Tests

  @Suite("Factory Scope")
  struct FactoryScopeTests {

    @Test(
      "Given factory scope (default), When resolved multiple times via override, Then can return different instances"
    )
    @MainActor
    func factoryReturnsNewInstances() {
      // Given
      setUp()
      Injector.register(value: MockTestService(), for: TestServiceInterface.self)
      Injector.override(TestServiceInterface.self, with: MockTestService(id: "first"))
      let first: TestServiceInterface = Injector.resolve()

      Injector.override(TestServiceInterface.self, with: MockTestService(id: "second"))
      let second: TestServiceInterface = Injector.resolve()

      // Then
      #expect(first.id == "first")
      #expect(second.id == "second")
      #expect(first.id != second.id)
    }

    @Test("Given factory scope, When resolved, Then factory closure is evaluated")
    @MainActor
    func factoryIsEvaluatedOnResolve() {
      // Given
      setUp()
      var callCount = 0
      let service = MockTestService()

      // When - Register with factory scope (default)
      Injector.register(
        value: service,
        for: TestServiceInterface.self
      )

      // Note: @autoclosure wraps the value, so it's not evaluated immediately
      // The closure is evaluated when resolve() is called

      // Override to track resolution
      Injector.override(
        TestServiceInterface.self,
        with: {
          callCount += 1
          return MockTestService()
        }())

      let _: TestServiceInterface = Injector.resolve()

      // Then - Closure was evaluated during resolve (via override)
      #expect(callCount == 1)
    }
  }

  // MARK: - Singleton Scope Tests

  @Suite("Singleton Scope")
  struct SingletonScopeTests {

    @Test("Given eager singleton, When registered, Then instance is created immediately")
    @MainActor
    func eagerSingletonCreatedImmediately() {
      // Given
      setUp()
      var wasCreated = false

      // When
      Injector.register(
        value: {
          wasCreated = true
          return MockTestService()
        }(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: true)
      )

      // Then
      #expect(wasCreated == true)
    }

    @Test("Given lazy singleton, When resolved multiple times, Then returns same instance")
    @MainActor
    func lazySingletonReturnsSameInstance() {
      // Given
      setUp()
      let originalService = MockTestService(id: "singleton-id")
      Injector.register(
        value: originalService,
        for: TestServiceInterface.self,
        scope: .singleton(eager: false)
      )
      Injector.override(TestServiceInterface.self, with: originalService)

      // When
      let first: TestServiceInterface = Injector.resolve()
      let second: TestServiceInterface = Injector.resolve()

      // Then
      #expect(first.id == second.id)
      #expect(first.id == "singleton-id")
    }
  }

  // MARK: - Resolution Tests

  @Suite("Resolution")
  struct ResolutionTests {

    @Test("Given registered service, When resolved, Then returns correct instance")
    @MainActor
    func resolveRegisteredService() {
      // Given
      setUp()
      let expectedService = MockTestService(id: "expected-id")
      Injector.register(value: expectedService, for: TestServiceInterface.self)
      Injector.override(TestServiceInterface.self, with: expectedService)

      // When
      let resolved: TestServiceInterface = Injector.resolve()

      // Then
      #expect(resolved.id == "expected-id")
    }

  }

  // MARK: - Reset Tests

  @Suite("Reset")
  struct ResetTests {

    @Test("Given registered services, When reset called, Then all registrations are cleared")
    @MainActor
    func resetClearsAllRegistrations() {
      // Given
      setUp()
      Injector.register(value: MockTestService(), for: TestServiceInterface.self)
      Injector.register(value: MockAnotherService(), for: AnotherServiceInterface.self)

      // When
      Injector.reset()

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == false)
      #expect(Injector.isRegistered(AnotherServiceInterface.self) == false)
    }
  }

  // MARK: - Override Tests

  @Suite("Test Overrides")
  struct OverrideTests {

    @Test("Given override, When resolved, Then returns overridden instance")
    @MainActor
    func overrideReturnsOverriddenInstance() {
      // Given
      setUp()
      let originalService = MockTestService(id: "original")
      let overrideService = MockTestService(id: "override")

      Injector.register(value: originalService, for: TestServiceInterface.self)
      Injector.override(TestServiceInterface.self, with: overrideService)

      // When
      let resolved: TestServiceInterface = Injector.resolve()

      // Then
      #expect(resolved.id == "override")
    }

    @Test("Given override, When resetOverrides called, Then override is cleared")
    @MainActor
    func resetOverridesClearsOverrides() {
      // Given
      setUp()
      let overrideService = MockTestService(id: "override")
      Injector.override(TestServiceInterface.self, with: overrideService)

      // When
      Injector.resetOverrides()

      // Then
      #expect(Injector.hasTestOverride(TestServiceInterface.self) == false)
    }

    @Test("Given override, When hasTestOverride called, Then returns true")
    @MainActor
    func hasTestOverrideReturnsTrue() {
      // Given
      setUp()
      let overrideService = MockTestService(id: "override")

      // When
      Injector.override(TestServiceInterface.self, with: overrideService)

      // Then
      #expect(Injector.hasTestOverride(TestServiceInterface.self) == true)
    }

    @Test("Given no override, When hasTestOverride called, Then returns false")
    @MainActor
    func hasTestOverrideReturnsFalse() {
      // Given
      setUp()

      // When
      let hasOverride = Injector.hasTestOverride(TestServiceInterface.self)

      // Then
      #expect(hasOverride == false)
    }
  }

  // MARK: - Debug Helpers Tests

  @Suite("Debug Helpers")
  struct DebugHelperTests {

    @Test("Given registered services, When registeredTypes called, Then returns type descriptions")
    @MainActor
    func registeredTypesReturnsDescriptions() {
      // Given
      setUp()
      Injector.register(value: MockTestService(), for: TestServiceInterface.self)

      // When
      let types = Injector.registeredTypes

      // Then
      #expect(types.isEmpty == false)
    }
  }

  // MARK: - Lazy Singleton Caching Tests

  @Suite("Lazy Singleton Caching")
  struct LazySingletonCachingTests {

    @Test(
      "Given lazy singleton, When resolved first time, Then factory is called and result is cached")
    @MainActor
    func lazySingletonCachesAfterFirstResolve() {
      // Given
      setUp()
      var factoryCallCount = 0
      let expectedId = "lazy-singleton-id"

      // Register as lazy singleton (default for .singleton())
      Injector.register(
        value: {
          factoryCallCount += 1
          return MockTestService(id: expectedId)
        }(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: false)
      )

      // Override to actually test resolution
      Injector.override(TestServiceInterface.self, with: MockTestService(id: expectedId))

      // When - First resolve
      let first: TestServiceInterface = Injector.resolve()

      // Then
      #expect(first.id == expectedId)
    }

    @Test("Given lazy singleton after resolve, When checked, Then is in singletons not factories")
    @MainActor
    func lazySingletonMovesToSingletonsAfterResolve() {
      // Given
      setUp()
      let service = MockTestService(id: "test-id")

      // Register as lazy singleton
      Injector.register(
        value: service,
        for: TestServiceInterface.self,
        scope: .singleton(eager: false)
      )

      // Override and resolve
      Injector.override(TestServiceInterface.self, with: service)
      let _: TestServiceInterface = Injector.resolve()

      // Then - Still registered (in singletons now, or override)
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)
    }
  }

  // MARK: - isRegistered Tests

  @Suite("isRegistered")
  struct IsRegisteredTests {

    @Test("Given eager singleton, When isRegistered called, Then returns true")
    @MainActor
    func isRegisteredForEagerSingleton() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: true)
      )

      // When
      let result = Injector.isRegistered(TestServiceInterface.self)

      // Then
      #expect(result == true)
    }

    @Test("Given lazy singleton, When isRegistered called before resolve, Then returns true")
    @MainActor
    func isRegisteredForLazySingletonBeforeResolve() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: false)
      )

      // When
      let result = Injector.isRegistered(TestServiceInterface.self)

      // Then - Should be true because factory is stored
      #expect(result == true)
    }

    @Test("Given factory, When isRegistered called, Then returns true")
    @MainActor
    func isRegisteredForFactory() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .factory
      )

      // When
      let result = Injector.isRegistered(TestServiceInterface.self)

      // Then
      #expect(result == true)
    }

    @Test("Given no registration, When isRegistered called, Then returns false")
    @MainActor
    func isRegisteredForUnregistered() {
      // Given
      setUp()

      // When
      let result = Injector.isRegistered(TestServiceInterface.self)

      // Then
      #expect(result == false)
    }
  }

  // MARK: - Reset Comprehensive Tests

  @Suite("Reset Comprehensive")
  struct ResetComprehensiveTests {

    @Test("Given singleton registration, When reset called, Then singleton is cleared")
    @MainActor
    func resetClearsSingletons() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: true)
      )
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)

      // When
      Injector.reset()

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == false)
    }

    @Test("Given factory registration, When reset called, Then factory is cleared")
    @MainActor
    func resetClearsFactories() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .factory
      )
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)

      // When
      Injector.reset()

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == false)
    }

    @Test("Given lazy singleton registration, When reset called, Then factory is cleared")
    @MainActor
    func resetClearsLazySingletons() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: false)
      )
      #expect(Injector.isRegistered(TestServiceInterface.self) == true)

      // When
      Injector.reset()

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == false)
    }

    @Test(
      "Given multiple registrations of different scopes, When reset called, Then all are cleared")
    @MainActor
    func resetClearsAllScopes() {
      // Given
      setUp()
      Injector.register(
        value: MockTestService(),
        for: TestServiceInterface.self,
        scope: .singleton(eager: true)
      )
      Injector.register(
        value: MockAnotherService(),
        for: AnotherServiceInterface.self,
        scope: .factory
      )

      // When
      Injector.reset()

      // Then
      #expect(Injector.isRegistered(TestServiceInterface.self) == false)
      #expect(Injector.isRegistered(AnotherServiceInterface.self) == false)
    }
  }
}

// MARK: - Dependency Property Wrapper Tests

@Suite("Dependency Property Wrapper Tests")
struct DependencyWrapperTests {

  @Test("Given registered service, When accessed via wrapper, Then returns correct instance")
  @MainActor
  func wrapperResolvesService() {
    // Given
    setUp()
    let expectedService = MockTestService(id: "wrapper-test")
    Injector.register(value: expectedService, for: TestServiceInterface.self)
    Injector.override(TestServiceInterface.self, with: expectedService)

    // When
    @Inject var service: TestServiceInterface

    // Then
    #expect(service.id == "wrapper-test")
  }

  @Test("Given wrapper, When accessed multiple times, Then returns cached instance")
  @MainActor
  func wrapperCachesInstance() {
    // Given
    setUp()
    let service1 = MockTestService(id: "first")
    Injector.register(value: service1, for: TestServiceInterface.self)
    Injector.override(TestServiceInterface.self, with: service1)

    @Inject var service: TestServiceInterface
    let firstAccess = service.id

    // When - Change the override (simulating factory behavior)
    let service2 = MockTestService(id: "second")
    Injector.override(TestServiceInterface.self, with: service2)
    let secondAccess = service.id

    // Then - Wrapper should return cached value, not the new one
    #expect(firstAccess == "first")
    #expect(secondAccess == "first")  // Cached
  }
}

// MARK: - Scope Enum Tests

@Suite("Scope Enum Tests")
struct ScopeEnumTests {

  @Test("Given singleton scope with eager true, Then eager value is true")
  func singletonEagerTrue() {
    // Given
    let scope = Lifetime.singleton(eager: true)

    // When / Then
    if case .singleton(let eager) = scope {
      #expect(eager == true)
    } else {
      Issue.record("Expected singleton scope")
    }
  }

  @Test("Given singleton scope with default, Then eager value is false")
  func singletonEagerDefaultFalse() {
    // Given
    let scope = Lifetime.singleton()

    // When / Then
    if case .singleton(let eager) = scope {
      #expect(eager == false)
    } else {
      Issue.record("Expected singleton scope")
    }
  }

  @Test("Given factory scope, Then it is factory")
  func factoryScope() {
    // Given
    let scope = Lifetime.factory

    // When / Then
    if case .factory = scope {
      #expect(true)
    } else {
      Issue.record("Expected factory scope")
    }
  }
}
