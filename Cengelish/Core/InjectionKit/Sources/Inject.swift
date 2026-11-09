@MainActor
@propertyWrapper
public final class Inject<Value> {
  private var storedValue: Value?

  public var wrappedValue: Value {
    if let storedValue { return storedValue }
    let value: Value = Injector.resolve()
    storedValue = value
    return value
  }

  public init() {}

  #if DEBUG
  public init(wrappedValue: Value) {
    self.storedValue = wrappedValue
  }
  #endif
}
