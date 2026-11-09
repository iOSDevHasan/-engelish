import ContentKit
import FirebaseAppCheck
import FirebaseCore
import FirebaseFirestore
import Foundation

/// Firebase kurulumu. `GoogleService-Info.plist` uygulamada yoksa hiçbir şey yapmaz.
public enum FirebaseBootstrap {

  /// Firebase'i (App Check ile) yapılandırır; dosya yoksa false döner.
  @MainActor
  @discardableResult
  public static func configureIfAvailable() -> Bool {
    if FirebaseApp.app() != nil { return true }
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
      return false
    }
    #if DEBUG
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #else
    AppCheck.setAppCheckProviderFactory(AttestProviderFactory())
    #endif
    FirebaseApp.configure()
    return true
  }

  /// Firebase yapılandırıldı mı.
  public static var isConfigured: Bool { FirebaseApp.app() != nil }
}

/// Gerçek cihazda App Attest ile App Check jetonu üretir.
private final class AttestProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
    AppAttestProvider(app: app)
  }
}

/// Firestore'dan paket listesi, paket içerikleri ve günlük bulmacalar.
///
/// Firestore düzeni (`tools/content/upload_firebase.py` ile yüklenir; ücretsiz Spark planında çalışır):
/// - `packs/{packId}`: `Pack` alanları + `contentPath`, `contentVersion`
/// - `packContents/{packId}_v{n}`: `data` alanında gzip'li `PackPayload` JSON'u (Bytes)
/// - `dailies/{yyyy-MM-dd}`: `date`, `puzzleId`, `puzzle`, `words`
public struct FirebaseContentSource: RemoteContentSource {

  /// Paket içeriklerinin koleksiyonu.
  private static let contentCollection = "packContents"

  /// Kaynağı oluşturur. Firebase önceden yapılandırılmış olmalıdır.
  public init() {}

  /// Firestore'daki paket listesini getirir.
  public func fetchManifest() async throws -> [Pack] {
    let snapshot = try await Firestore.firestore().collection("packs").getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: Pack.self) }
  }

  /// Paketin gzip'li içerik belgesini indirip çözer.
  public func downloadPack(_ pack: Pack) async throws -> PackPayload {
    guard let path = pack.contentPath, path.hasPrefix(Self.contentCollection + "/") else {
      throw ContentError.missingStarterContent
    }
    let document = try await Firestore.firestore().document(path).getDocument()
    guard let data = document.get("data") as? Data else { throw ContentError.missingStarterContent }
    let json = try Gzip.decompress(data)
    return try JSONDecoder().decode(PackPayload.self, from: json)
  }

  /// Başlangıç tarihinden itibaren günlük bulmacaları getirir.
  public func fetchDailies(from date: String, limit: Int) async throws -> [DailyPayload] {
    let snapshot = try await Firestore.firestore().collection("dailies")
      .whereField("date", isGreaterThanOrEqualTo: date)
      .order(by: "date")
      .limit(to: limit)
      .getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: DailyPayload.self) }
  }
}
