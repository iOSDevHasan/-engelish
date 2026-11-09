import Foundation
import OSLog
import SwiftData

/// SwiftData kapsayıcısını, kullanıcının iCloud tercihine göre kurar.
enum ContainerFactory {

  /// iCloud yedekleme anahtarının UserDefaults adı (cihaza özel, senkronlanmaz).
  static let iCloudKey = "cengelish.icloudBackup"
  /// Uygulamanın CloudKit kapsayıcısı.
  static let cloudContainer = "iCloud.com.hasangurbuz.cengelish"

  private static let logger = Logger(subsystem: "com.hasangurbuz.cengelish", category: "data")

  /// iCloud kullanılabilir mi: uygulama CloudKit yetkisiyle derlenmiş ve kullanıcı iCloud'a girmiş.
  ///
  /// Yetki olmadan CloudKit kapsayıcısı açmak uygulamayı çökertir; bu yüzden önce kontrol edilir.
  static var isCloudAvailable: Bool {
    let enabled = Bundle.main.object(forInfoDictionaryKey: "CENGELISH_CLOUDKIT") as? String == "YES"
    return enabled && FileManager.default.ubiquityIdentityToken != nil
  }

  /// Kalıcı kapsayıcıyı oluşturur; CloudKit kurulamazsa sadece cihazda çalışır.
  static func make(inMemory: Bool = false) -> ModelContainer {
    let schema = Schema(UserSchema.models)
    if inMemory {
      return build(schema, ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }
    if UserDefaults.standard.bool(forKey: iCloudKey), isCloudAvailable {
      let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudContainer))
      do {
        return try ModelContainer(for: schema, configurations: cloud)
      } catch {
        logger.error("iCloud kapsayıcısı kurulamadı, cihazda devam: \(error.localizedDescription)")
      }
    }
    return build(schema, ModelConfiguration(schema: schema, cloudKitDatabase: .none))
  }

  /// Verilen ayarla kapsayıcı kurar; başarısız olursa bellekte çalışan bir kapsayıcıya düşer.
  private static func build(_ schema: Schema, _ config: ModelConfiguration) -> ModelContainer {
    do {
      return try ModelContainer(for: schema, configurations: config)
    } catch {
      logger.fault("Veri deposu açılamadı: \(error.localizedDescription)")
      let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      // Bellek içi kapsayıcı sabit şemayla her zaman kurulabilir.
      // swiftlint:disable:next force_try
      return try! ModelContainer(for: schema, configurations: fallback)
    }
  }
}
