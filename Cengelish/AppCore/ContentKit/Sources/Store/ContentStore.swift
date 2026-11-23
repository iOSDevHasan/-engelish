import Foundation
import OSLog

/// Uygulamaya gömülü içeriği (tüm paketler, bulmacalar ve günlük bulmaca takvimi) sunan içerik
/// deposu. Ağ kullanmaz; takvimde olmayan günlerin bulmacası cihazda üretilir ve Application
/// Support altında saklanır.
public actor ContentStore: ContentProviding {

  // MARK: - Properties

  private let cacheDirectory: URL
  private let logger = Logger(subsystem: "com.hasangurbuz.cengelish", category: "content")
  private var packsById: [String: Pack] = [:]
  private var puzzlesById: [String: Puzzle] = [:]
  private var wordsById: [String: Word] = [:]
  private var dailies: [String: String] = [:]
  private var transientPuzzles: [String: Puzzle] = [:]
  private var transientWords: [String: Word] = [:]
  /// Takvimde olmayan günlerin bulmacasını üretir; herkeste aynı sonuç için yalnızca gömülü
  /// kelimelerle kurulur.
  private var dailyBuilder: DailyPuzzleBuilder?
  /// Cihazda üretilen günlük bulmacası olan günler (`yyyy-MM-dd`).
  private var generatedDailyDates: Set<String> = []
  private var isLoaded = false
  /// Cihazda üretilip önbelleğe yazılan günlük bulmaca dosyalarının ön eki.
  static let generatedDailyPrefix = "gendaily-"

  // MARK: - Init

  /// Depoyu isteğe bağlı önbellek klasörüyle oluşturur (cihazda üretilen günlük bulmacalar).
  public init(cacheDirectory: URL? = nil) {
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
    // Takvimde gün yoksa bulmaca cihazda, gün anahtarından belirlenimci olarak üretilir.
    if let puzzle = generateDaily(dayKey: key) {
      return puzzle
    }
    // Üretilemezse (havuz yok) gömülü günlük bulmacalardan tarihe göre sabit bir tanesi seçilir.
    let all = dailies.keys.sorted().compactMap { dailies[$0] }.compactMap { puzzlesById[$0] }
    guard !all.isEmpty else { return nil }
    let dayNumber = Int(date.timeIntervalSince1970 / 86_400)
    return all[((dayNumber % all.count) + all.count) % all.count]
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

  // MARK: - On-device dailies

  /// Gün için cihazda günlük bulmaca üretip kaydeder; üretilemezse nil döner.
  ///
  /// Bugün ve geçmiş günlerin bulmacası önbelleğe yazılır; böylece yeni bir uygulama sürümü
  /// (farklı gömülü içerik) gelse de oynanan bulmaca ve ilerlemesi değişmez. Gelecek günler
  /// (widget önizlemesi) sadece bellekte tutulur; yeni bir sürümün gömülü takvimi onların yerini
  /// alabilir.
  private func generateDaily(dayKey: String) -> Puzzle? {
    guard let puzzle = dailyBuilder?.build(dayKey: dayKey) else {
      logger.error("Günlük bulmaca üretilemedi: \(dayKey)")
      return nil
    }
    puzzlesById[puzzle.id] = puzzle
    dailies[dayKey] = puzzle.id
    generatedDailyDates.insert(dayKey)
    if dayKey <= DayKey.string(from: .now) {
      let words = Set(puzzle.wordIds).sorted().compactMap { wordsById[$0] }
      do {
        try save(
          DailyPayload(date: dayKey, puzzle: puzzle, words: words),
          name: "\(Self.generatedDailyPrefix)\(dayKey).json")
      } catch {
        logger.error("Üretilen günlük bulmaca kaydedilemedi: \(error.localizedDescription)")
      }
    }
    return puzzle
  }

  // MARK: - Loading

  /// Gömülü içeriği ve önbellekteki dosyaları belleğe yükler.
  private func loadIfNeeded() {
    guard !isLoaded else { return }
    isLoaded = true
    do {
      let bundle = try Self.loadStarterBundle()
      dailyBuilder = DailyPuzzleBuilder(words: bundle.words)
      bundle.words.forEach { wordsById[$0.id] = $0 }
      bundle.packs.forEach { packsById[$0.id] = $0 }
      bundle.puzzles.forEach { puzzlesById[$0.id] = $0 }
      bundle.dailies.forEach { dailies[$0.date] = $0.puzzleId }
    } catch {
      logger.fault("Başlangıç içeriği okunamadı: \(error.localizedDescription)")
    }
    loadCache()
  }

  /// Önbellek klasöründeki dosyaları okur: cihazda üretilen günlük bulmacalar ve eski
  /// sürümlerin indirdiği paket / günlük bulmaca dosyaları (oynanmış ilerleme bozulmasın diye).
  private func loadCache() {
    let files =
      (try? FileManager.default.contentsOfDirectory(
        at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
    let decoder = JSONDecoder()
    for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    where file.pathExtension == "json" {
      guard let data = try? Data(contentsOf: file) else { continue }
      if file.lastPathComponent.hasPrefix(Self.generatedDailyPrefix),
        let payload = try? decoder.decode(DailyPayload.self, from: data)
      {
        merge(payload)
        generatedDailyDates.insert(payload.date)
      } else if file.lastPathComponent.hasPrefix("pack-"),
        let payload = try? decoder.decode(PackPayload.self, from: data)
      {
        mergeLegacy(payload)
      } else if file.lastPathComponent.hasPrefix("daily-"),
        let payload = try? decoder.decode(DailyPayload.self, from: data)
      {
        mergeLegacy(payload)
      }
    }
  }

  /// Eski sürümün indirdiği paket dosyasından yalnızca gömülü içerikte olmayan kayıtları ekler;
  /// gömülü paketler (daha çok bulmacalı güncel sürüm) eskisiyle ezilmez.
  private func mergeLegacy(_ payload: PackPayload) {
    payload.words.forEach { wordsById[$0.id] = wordsById[$0.id] ?? $0 }
    payload.puzzles.forEach { puzzlesById[$0.id] = puzzlesById[$0.id] ?? $0 }
    packsById[payload.pack.id] = packsById[payload.pack.id] ?? payload.pack
  }

  /// Eski sürümün indirdiği günlük bulmacayı, o gün için gömülü bulmaca yoksa ekler.
  private func mergeLegacy(_ payload: DailyPayload) {
    guard dailies[payload.date] == nil else { return }
    merge(payload)
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
