import Foundation
import OSLog

/// Gömülü başlangıç içeriğini ve indirilen paketleri birleştirip sunan içerik deposu.
///
/// İndirilen paketler Application Support altında kalıcı saklanır, böylece oyun
/// internetsiz de çalışır.
public actor ContentStore: ContentProviding {

  // MARK: - Properties

  private let remote: RemoteContentSource?
  private let cacheDirectory: URL
  private let logger = Logger(subsystem: "com.hasangurbuz.cengelish", category: "content")
  private var packsById: [String: Pack] = [:]
  private var puzzlesById: [String: Puzzle] = [:]
  private var wordsById: [String: Word] = [:]
  private var dailies: [String: String] = [:]
  private var transientPuzzles: [String: Puzzle] = [:]
  private var transientWords: [String: Word] = [:]
  private var isLoaded = false

  // MARK: - Init

  /// Depoyu isteğe bağlı uzak kaynak ve önbellek klasörüyle oluşturur.
  public init(remote: RemoteContentSource? = nil, cacheDirectory: URL? = nil) {
    self.remote = remote
    self.cacheDirectory =
      cacheDirectory
      ?? URL.applicationSupportDirectory.appending(path: "Content", directoryHint: .isDirectory)
  }

  // MARK: - ContentProviding

  public func packs() async -> [Pack] {
    loadIfNeeded()
    return packsById.values.sorted { ($0.order, $0.id) < ($1.order, $1.id) }
  }

  public func pack(id: String) async -> Pack? {
    loadIfNeeded()
    return packsById[id]
  }

  public func puzzle(id: String) async -> Puzzle? {
    loadIfNeeded()
    return puzzlesById[id] ?? transientPuzzles[id]
  }

  public func puzzles(inPack packId: String) async -> [Puzzle] {
    loadIfNeeded()
    guard let pack = packsById[packId] else { return [] }
    return pack.puzzleIds.compactMap { puzzlesById[$0] }
  }

  public func words(ids: [String]) async -> [Word] {
    loadIfNeeded()
    var seen = Set<String>()
    return ids.compactMap { id in
      guard seen.insert(id).inserted else { return nil }
      return wordsById[id] ?? transientWords[id]
    }
  }

  public func dailyPuzzle(for date: Date) async -> Puzzle? {
    loadIfNeeded()
    let key = DayKey.string(from: date)
    if let id = dailies[key], let puzzle = puzzlesById[id] {
      return puzzle
    }
    // Takvimde gün yoksa gömülü günlük bulmacalardan tarihe göre sabit bir tanesi seçilir.
    let all = dailies.keys.sorted().compactMap { dailies[$0] }.compactMap { puzzlesById[$0] }
    guard !all.isEmpty else { return nil }
    let dayNumber = Int(date.timeIntervalSince1970 / 86_400)
    return all[((dayNumber % all.count) + all.count) % all.count]
  }

  public func refreshFromRemote(entitledPackIds: Set<String>) async {
    loadIfNeeded()
    guard let remote else { return }
    do {
      for pack in try await remote.fetchManifest() {
        let current = packsById[pack.id]
        let isNewer = (pack.contentVersion ?? 0) > (current?.contentVersion ?? 0)
        let allowed = pack.freeCount > 0 || entitledPackIds.contains(pack.id)
        guard isNewer, allowed, pack.contentPath != nil else { continue }
        let payload = try await remote.downloadPack(pack)
        try save(payload, name: "pack-\(pack.id).json")
        merge(payload)
      }
      let dailyPayloads = try await remote.fetchDailies(from: DayKey.string(from: .now), limit: 7)
      for daily in dailyPayloads {
        try save(daily, name: "daily-\(daily.date).json")
        merge(daily)
      }
    } catch {
      logger.error("Uzak içerik yenilenemedi: \(error.localizedDescription)")
    }
  }

  public func wordPool() async -> [Word] {
    loadIfNeeded()
    return wordsById.values.sorted { $0.id < $1.id }
  }

  public func registerTransient(_ puzzle: Puzzle, words: [Word]) async {
    loadIfNeeded()
    transientPuzzles[puzzle.id] = puzzle
    words.forEach { transientWords[$0.id] = $0 }
  }

  // MARK: - Loading

  /// Gömülü içeriği ve önbellekteki dosyaları belleğe yükler.
  private func loadIfNeeded() {
    guard !isLoaded else { return }
    isLoaded = true
    do {
      let bundle = try Self.loadStarterBundle()
      bundle.words.forEach { wordsById[$0.id] = $0 }
      bundle.packs.forEach { packsById[$0.id] = $0 }
      bundle.puzzles.forEach { puzzlesById[$0.id] = $0 }
      bundle.dailies.forEach { dailies[$0.date] = $0.puzzleId }
    } catch {
      logger.fault("Başlangıç içeriği okunamadı: \(error.localizedDescription)")
    }
    loadCache()
  }

  /// Önbellek klasöründeki paket ve günlük bulmaca dosyalarını okur.
  private func loadCache() {
    let files =
      (try? FileManager.default.contentsOfDirectory(
        at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
    let decoder = JSONDecoder()
    for file in files where file.pathExtension == "json" {
      guard let data = try? Data(contentsOf: file) else { continue }
      if file.lastPathComponent.hasPrefix("pack-"),
        let payload = try? decoder.decode(PackPayload.self, from: data)
      {
        merge(payload)
      } else if file.lastPathComponent.hasPrefix("daily-"),
        let payload = try? decoder.decode(DailyPayload.self, from: data)
      {
        merge(payload)
      }
    }
  }

  /// Paket dosyasını belleğe ekler; aynı kimlikli kayıtların yerini alır.
  private func merge(_ payload: PackPayload) {
    payload.words.forEach { wordsById[$0.id] = $0 }
    payload.puzzles.forEach { puzzlesById[$0.id] = $0 }
    packsById[payload.pack.id] = payload.pack
  }

  /// Günlük bulmaca belgesini belleğe ekler.
  private func merge(_ payload: DailyPayload) {
    payload.words.forEach { wordsById[$0.id] = $0 }
    puzzlesById[payload.puzzle.id] = payload.puzzle
    dailies[payload.date] = payload.puzzle.id
  }

  /// Kodlanabilir bir değeri önbellek klasörüne yazar.
  private func save(_ value: some Encodable, name: String) throws {
    try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    try JSONEncoder().encode(value).write(
      to: cacheDirectory.appending(path: name), options: .atomic)
  }

  /// Paket içine gömülü `starter.json` dosyasını çözer.
  static func loadStarterBundle() throws -> ContentBundle {
    guard let url = Bundle.module.url(forResource: "starter", withExtension: "json") else {
      throw ContentError.missingStarterContent
    }
    return try JSONDecoder().decode(ContentBundle.self, from: Data(contentsOf: url))
  }
}

/// Günlük anahtarları (`yyyy-MM-dd`) için ortak biçimlendirici.
public enum DayKey {
  /// Tarihi cihazın yerel takvimine göre `yyyy-MM-dd` metnine çevirir.
  public static func string(from date: Date, calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }
}
