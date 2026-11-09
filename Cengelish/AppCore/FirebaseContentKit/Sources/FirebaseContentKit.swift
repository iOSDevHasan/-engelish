import ContentKit
import FirebaseAppCheck
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
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

/// Firestore'dan paket listesi ve günlük bulmacalar, Storage'dan paket dosyaları.
///
/// Firestore düzeni (`tools/content/upload_firebase.py` ile yüklenir):
/// - `packs/{packId}`: `Pack` alanları + `contentPath`, `contentVersion`
/// - `dailies/{yyyy-MM-dd}`: `date`, `puzzleId`, `puzzle`, `words`
/// - Storage `packs/{packId}_v{n}.json.gz`: `PackPayload`
public struct FirebaseContentSource: RemoteContentSource {

  /// Paket dosyası için en büyük boyut (5 MB).
  private let maxPackBytes: Int64 = 5 * 1024 * 1024

  /// Kaynağı oluşturur. Firebase önceden yapılandırılmış olmalıdır.
  public init() {}

  public func fetchManifest() async throws -> [Pack] {
    let snapshot = try await Firestore.firestore().collection("packs").getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: Pack.self) }
  }

  public func downloadPack(_ pack: Pack) async throws -> PackPayload {
    guard let path = pack.contentPath else { throw ContentError.missingStarterContent }
    let data = try await Storage.storage().reference(withPath: path).data(maxSize: maxPackBytes)
    let json = path.hasSuffix(".gz") ? try Gzip.decompress(data) : data
    return try JSONDecoder().decode(PackPayload.self, from: json)
  }

  public func fetchDailies(from date: String, limit: Int) async throws -> [DailyPayload] {
    let snapshot = try await Firestore.firestore().collection("dailies")
      .whereField("date", isGreaterThanOrEqualTo: date)
      .order(by: "date")
      .limit(to: limit)
      .getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: DailyPayload.self) }
  }
}
