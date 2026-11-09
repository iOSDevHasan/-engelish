import Combine
import Foundation
import OSLog
import StoreKit

/// StoreKit 2 ile yetkileri cihazda okuyan ve satın alma yapan depo.
@MainActor
public final class EntitlementStore: ObservableObject, EntitlementProviding {

  // MARK: - Properties

  @Published public private(set) var isPremium = false
  @Published public private(set) var ownedProductIds: Set<String> = []
  @Published public private(set) var products: [StoreProduct] = []
  /// Aktif aboneliğin planı ve yenilenme tarihi.
  @Published public private(set) var activeSubscription: ActiveSubscription?
  private var storeProducts: [String: Product] = [:]
  private var updatesTask: Task<Void, Never>?
  private let logger = Logger(subsystem: "com.hasangurbuz.cengelish", category: "store")

  public var changes: AnyPublisher<Void, Never> {
    Publishers.Merge3(
      $isPremium.map { _ in () }, $ownedProductIds.map { _ in () },
      $activeSubscription.map { _ in () }
    )
    .dropFirst(3)
    .eraseToAnyPublisher()
  }

  // MARK: - Init

  /// Depoyu oluşturur ve işlem güncellemelerini dinlemeye başlar.
  public init() {
    updatesTask = Task { [weak self] in
      for await update in Transaction.updates {
        if case .verified(let transaction) = update {
          await transaction.finish()
        }
        await self?.refreshEntitlements()
      }
    }
    Task { await refreshEntitlements() }
  }

  deinit {
    updatesTask?.cancel()
  }

  // MARK: - EntitlementProviding

  public func loadProducts() async {
    do {
      let loaded = try await Product.products(for: ProductID.all)
      storeProducts = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
      products = ProductID.all.compactMap { storeProducts[$0] }.map(Self.makeProduct)
    } catch {
      logger.error("Ürünler yüklenemedi: \(error.localizedDescription)")
    }
  }

  public func purchase(_ productId: String) async -> PurchaseOutcome {
    if storeProducts[productId] == nil { await loadProducts() }
    guard let product = storeProducts[productId] else {
      return .failed("Ürün şu an yüklenemedi. İnternet bağlantını kontrol et.")
    }
    do {
      switch try await product.purchase() {
      case .success(let verification):
        guard case .verified(let transaction) = verification else {
          return .failed("Satın alma doğrulanamadı.")
        }
        await transaction.finish()
        await refreshEntitlements()
        return .purchased
      case .pending:
        return .pending
      case .userCancelled:
        return .cancelled
      @unknown default:
        return .cancelled
      }
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  public func restore() async {
    try? await AppStore.sync()
    await refreshEntitlements()
  }

  // MARK: - Private

  /// Cihazdaki geçerli işlemlerden yetkileri yeniden hesaplar.
  private func refreshEntitlements() async {
    var premium = false
    var owned: Set<String> = []
    var subscription: ActiveSubscription?
    for await result in Transaction.currentEntitlements {
      guard case .verified(let transaction) = result, transaction.revocationDate == nil else {
        continue
      }
      if ProductID.subscriptions.contains(transaction.productID) {
        premium = true
        subscription = await Self.makeSubscription(transaction)
      } else {
        owned.insert(transaction.productID)
      }
    }
    isPremium = premium
    ownedProductIds = owned
    activeSubscription = subscription
  }

  /// Abonelik işleminden plan ve yenilenme bilgisini okur (`SubscriptionInfo.Status`).
  private static func makeSubscription(_ transaction: Transaction) async -> ActiveSubscription {
    var renewalDate = transaction.expirationDate
    var willAutoRenew = true
    if let groupId = transaction.subscriptionGroupID,
      let statuses = try? await Product.SubscriptionInfo.status(for: groupId)
    {
      let current = statuses.first { status in
        guard case .verified(let renewal) = status.renewalInfo else { return false }
        return renewal.currentProductID == transaction.productID
      }
      if let current, case .verified(let renewal) = current.renewalInfo {
        willAutoRenew = renewal.willAutoRenew
        renewalDate = renewal.renewalDate ?? renewalDate
      }
    }
    return ActiveSubscription(
      productId: transaction.productID, renewalDate: renewalDate, willAutoRenew: willAutoRenew)
  }

  /// StoreKit ürününü ekran modeline çevirir.
  private static func makeProduct(_ product: Product) -> StoreProduct {
    let isYearly = product.subscription?.subscriptionPeriod.unit == .year
    let monthly: String? =
      isYearly ? (product.price / 12).formatted(product.priceFormatStyle) : nil
    let trial = product.subscription?.introductoryOffer.flatMap { offer -> String? in
      guard offer.paymentMode == .freeTrial else { return nil }
      return "\(offer.period.value) \(offer.period.unit == .day ? "gün" : "hafta") ücretsiz"
    }
    return StoreProduct(
      id: product.id, title: product.displayName, displayPrice: product.displayPrice,
      monthlyEquivalent: monthly, trialText: trial, isSubscription: product.subscription != nil)
  }
}
