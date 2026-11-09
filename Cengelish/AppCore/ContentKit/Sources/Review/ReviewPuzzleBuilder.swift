import Foundation

/// Defterdeki tekrar kelimelerinden cihazda çengel (İsveç tipi) bulmaca kuran üretici.
///
/// `tools/content/generate.py` ile aynı yaklaşımı izler: çift indeksler ipucu kutusu, tek
/// satır/sütunlar harf hattıdır; her hat parçalara bölünür ve ızgara geri izlemeyle doldurulur.
/// Tekrar kelimeleri adaylarda hep öne alınır, kalan kutular aynı seviyedeki kelimelerle dolar.
public struct ReviewPuzzleBuilder: Sendable {

  // MARK: - Constants

  /// Tekrar bulmacalarının paket kimliği.
  public static let packId = "review"
  /// Tekrar bulmacası kimliklerinin ön eki.
  public static let idPrefix = "review_"
  /// Bulmacaya girebilen cevap uzunlukları.
  public static let lengthRange = 3...7
  /// Denenen ızgara boyutları (sütun × satır).
  static let sizes = [(width: 7, height: 7), (width: 7, height: 9)]
  /// Dolgu havuzu bundan küçükse komşu seviyeler de eklenir.
  static let minimumPoolSize = 400
  /// Bir uzunlukta en az bu kadar aday yoksa o uzunlukta parça açılmaz.
  static let minimumWordsPerLength = 4
  /// Izgara boyutu başına doldurma denemesi sınırı.
  static let fillAttempts = 60
  /// Şablon üretme denemesi sınırı.
  static let templateAttempts = 600
  /// Tek doldurmadaki geri izleme düğümü sınırı.
  static let nodeLimit = 1_500
  /// Her düğümde denenen en fazla aday.
  static let branchLimit = 25

  // MARK: - Properties

  private let seed: UInt64

  // MARK: - Init

  /// Üreticiyi tohumla oluşturur; aynı tohum ve kelimeler hep aynı bulmacayı verir.
  public init(seed: UInt64) {
    self.seed = seed
  }

  /// Üreticiyi rastgele tohumla oluşturur.
  public init() {
    self.init(seed: UInt64.random(in: UInt64.min...UInt64.max))
  }

  // MARK: - Building

  /// Tekrar kelimelerini öne alarak bulmaca kurar; kurulamazsa nil döner.
  ///
  /// - Parameters:
  ///   - dueWords: Bugün tekrar edilecek kelimeler (öncelikli).
  ///   - pool: Dolgu için kelime havuzu (tekrar kelimeleriyle aynı seviyeler tercih edilir).
  ///   - now: Bulmaca kimliğindeki zaman damgası.
  public func build(dueWords: [Word], pool: [Word], now: Date = .now) -> Puzzle? {
    var rng = SeededGenerator(seed: seed)
    let candidates = Self.candidates(dueWords: dueWords, pool: pool)
    let dueTarget = candidates.filter(\.isDue).count
    guard candidates.count >= 6 else { return nil }
    // 7 harfli kelimeler yalnızca 9 satırlı ızgaranın sütunlarına sığar.
    let needsTall = dueTarget > 5 || candidates.contains { $0.isDue && $0.letters.count == 7 }
    let sizes = needsTall ? Array(Self.sizes.reversed()) : Self.sizes
    var best: (fill: Fill, size: (width: Int, height: Int))?
    for size in sizes {
      let filler = Filler(candidates: candidates, width: size.width)
      var fillsLeft = Self.fillAttempts
      var templatesLeft = Self.templateAttempts
      while fillsLeft > 0, templatesLeft > 0 {
        templatesLeft -= 1
        let template = Template.random(
          width: size.width, height: size.height, lengths: filler.lengthCounts,
          preferred: filler.dueLengthCounts, rng: &rng)
        guard template.isValid else { continue }
        fillsLeft -= 1
        guard let fill = filler.fill(template, rng: &rng) else { continue }
        if best.map({ fill.isBetter(than: $0.fill) }) ?? true {
          best = (fill, size)
        }
        if fill.dueCount >= dueTarget { break }
      }
      if let best, best.fill.dueCount >= dueTarget { break }
    }
    guard let best, dueTarget == 0 || best.fill.dueCount > 0 else { return nil }
    return makePuzzle(best.fill, size: best.size, dueWords: dueWords, now: now)
  }

  // MARK: - Helpers

  /// Bulmacaya girebilecek adaylar: önce tekrar kelimeleri, sonra seviyeye göre dolgu.
  static func candidates(dueWords: [Word], pool: [Word]) -> [Candidate] {
    var seen = Set<String>()
    var result: [Candidate] = []
    func append(_ word: Word, tier: Int) {
      guard let letters = Candidate.letters(for: word), seen.insert(word.en.uppercased()).inserted
      else { return }
      result.append(Candidate(word: word, letters: letters, tier: tier))
    }
    dueWords.forEach { append($0, tier: 0) }
    let sortedPool = pool.sorted { $0.id < $1.id }
    let levels = Set(dueWords.map(\.level))
    let allLevels = CEFRLevel.allCases
    let nearLevels = Set(
      levels.flatMap { level -> [CEFRLevel] in
        let index = allLevels.firstIndex(of: level) ?? 0
        return allLevels.enumerated().filter { abs($0.offset - index) <= 1 }.map(\.element)
      })
    let tiers: [(CEFRLevel) -> Bool] = [
      { levels.isEmpty || levels.contains($0) },
      { nearLevels.contains($0) },
      { _ in true },
    ]
    for (offset, tier) in tiers.enumerated() {
      sortedPool.filter { tier($0.level) }.forEach { append($0, tier: offset + 1) }
      if result.count >= minimumPoolSize { break }
    }
    return result
  }

  /// Doldurulmuş şablondan `Puzzle` oluşturur.
  private func makePuzzle(
    _ fill: Fill, size: (width: Int, height: Int), dueWords: [Word], now: Date
  ) -> Puzzle {
    let entries = zip(fill.template.slots, fill.words).map { slot, candidate in
      PuzzleEntry(
        wordId: candidate.word.id, answer: candidate.word.en.uppercased(),
        clue: candidate.word.clue, row: slot.cells[0].row, col: slot.cells[0].col,
        dir: slot.direction, clueRow: slot.clue.row, clueCol: slot.clue.col)
    }
    .sorted {
      ($0.dir != .across ? 1 : 0, $0.clueRow, $0.clueCol)
        < ($1.dir != .across ? 1 : 0, $1.clueRow, $1.clueCol)
    }
    let levelSource = dueWords.isEmpty ? fill.words.map(\.word) : dueWords
    let counts = Dictionary(grouping: levelSource, by: \.level).mapValues(\.count)
    let level =
      counts.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key ?? .a1
    return Puzzle(
      id: "\(Self.idPrefix)\(Int(now.timeIntervalSince1970 * 1_000))",
      packId: Self.packId, kind: .pack, level: level, width: size.width,
      height: size.height, entries: entries)
  }
}

extension Puzzle {
  /// Defterden cihazda üretilen tekrar bulmacası mı.
  public var isReview: Bool {
    packId == ReviewPuzzleBuilder.packId || id.hasPrefix(ReviewPuzzleBuilder.idPrefix)
  }
}

// MARK: - Candidate

/// Doldurmada kullanılan kelime ve harf kodları.
struct Candidate: Sendable {
  /// Kelime.
  let word: Word
  /// Büyük harf ASCII kodları.
  let letters: [UInt8]
  /// Öncelik: 0 tekrar kelimesi, 1 aynı seviye, 2 komşu seviye, 3 diğer.
  let tier: Int

  /// Tekrar kelimesi mi.
  var isDue: Bool { tier == 0 }

  /// Kelime sadece A–Z harflerinden oluşuyor ve uzunluğu uygunsa harf kodlarını döner.
  static func letters(for word: Word) -> [UInt8]? {
    let bytes = Array(word.en.uppercased().utf8)
    guard ReviewPuzzleBuilder.lengthRange.contains(bytes.count),
      bytes.allSatisfy({ (65...90).contains($0) })
    else { return nil }
    return bytes
  }
}

// MARK: - Template

/// Izgaradaki tek bir kelime yeri.
struct Slot: Sendable {
  /// İpucu kutusu.
  let clue: GridPoint
  /// Yön.
  let direction: Direction
  /// Harf kutuları.
  let cells: [GridPoint]
}

/// Kelime yerlerinden oluşan boş ızgara.
struct Template: Sendable {
  /// Sütun sayısı.
  let width: Int
  /// Satır sayısı.
  let height: Int
  /// Kelime yerleri.
  let slots: [Slot]

  /// Tek satırları ve sütunları rastgele parçalara bölerek şablon kurar.
  static func random(
    width: Int, height: Int, lengths: [Int: Int], preferred: [Int: Int] = [:],
    rng: inout SeededGenerator
  ) -> Template {
    var slots: [Slot] = []
    for row in stride(from: 1, to: height, by: 2) {
      for (start, length) in segments(
        lineLength: width, lengths: lengths, preferred: preferred, rng: &rng)
      {
        slots.append(
          Slot(
            clue: GridPoint(row: row, col: start - 1), direction: .across,
            cells: (start..<start + length).map { GridPoint(row: row, col: $0) }))
      }
    }
    for col in stride(from: 1, to: width, by: 2) {
      for (start, length) in segments(
        lineLength: height, lengths: lengths, preferred: preferred, rng: &rng)
      {
        slots.append(
          Slot(
            clue: GridPoint(row: start - 1, col: col), direction: .down,
            cells: (start..<start + length).map { GridPoint(row: $0, col: col) }))
      }
    }
    return Template(width: width, height: height, slots: slots)
  }

  /// Bir hat için (başlangıç, uzunluk) parçalarını ağırlıklı rastgele seçer.
  ///
  /// Her parçanın önündeki çift indeksli kutu ipucu kutusu, arkasındaki kutu ise çift indeksli bir
  /// boşluk ya da hat sonudur.
  /// `preferred` uzunluklarındaki (tekrar kelimelerinin uzunlukları) parçalar daha olasıdır.
  static func segments(
    lineLength: Int, lengths: [Int: Int], preferred: [Int: Int] = [:],
    rng: inout SeededGenerator
  ) -> [(start: Int, length: Int)] {
    var options: [[(start: Int, length: Int)]] = []
    var current: [(start: Int, length: Int)] = []
    func walk(_ position: Int) {
      if !current.isEmpty { options.append(current) }
      for clue in stride(from: position, to: lineLength - 1, by: 2) {
        let start = clue + 1
        for end in (start + 2)..<max(start + 2, lineLength) {
          guard end + 1 == lineLength || (end + 1) % 2 == 0 else { continue }
          let length = end - start + 1
          guard ReviewPuzzleBuilder.lengthRange.contains(length),
            lengths[length, default: 0] >= ReviewPuzzleBuilder.minimumWordsPerLength
          else { continue }
          current.append((start, length))
          walk(end + 1)
          current.removeLast()
        }
      }
    }
    walk(0)
    guard !options.isEmpty else { return [] }
    let weights = options.map { option in
      let letters = Double(option.reduce(0) { $0 + $1.length })
      let bonus = option.reduce(0.0) { $0 + (preferred[$1.length, default: 0] > 0 ? 1.5 : 0) }
      return pow(letters, 1.4) / (1 + 0.6 * Double(option.count - 1)) * (1 + bonus)
    }
    var pick = rng.nextUnit() * weights.reduce(0, +)
    for (option, weight) in zip(options, weights) {
      pick -= weight
      if pick < 0 { return option }
    }
    return options[options.count - 1]
  }

  /// İzin verilen boş kesişim sayısı; tekrar kelimelerinin sığabilmesi için paket
  /// bulmacalarından biraz daha seyrek ızgaralara izin verilir.
  static func maximumHoles(width: Int, height: Int) -> Int {
    (width / 2) * (height / 2) / 4
  }

  /// Şablon kullanılabilir mi: ipucu ve harf kutuları çakışmıyor, yeterince kelime ve dolu ızgara.
  var isValid: Bool {
    let clues = Set(slots.map(\.clue))
    let letters = Set(slots.flatMap(\.cells))
    guard clues.isDisjoint(with: letters), clues.count == slots.count else { return false }
    var holes = 0
    for row in stride(from: 1, to: height, by: 2) {
      for col in stride(from: 1, to: width, by: 2)
      where !letters.contains(GridPoint(row: row, col: col)) {
        holes += 1
      }
    }
    return (5...14).contains(slots.count)
      && holes <= Self.maximumHoles(width: width, height: height)
  }
}

// MARK: - Filling

/// Doldurulmuş şablon.
struct Fill: Sendable {
  /// Şablon.
  let template: Template
  /// Her kelime yerine yerleşen aday, şablon sırasıyla.
  let words: [Candidate]

  /// Yerleşen tekrar kelimesi sayısı.
  var dueCount: Int { words.filter(\.isDue).count }

  /// Daha çok tekrar kelimesi, eşitlikte daha çok harf kutusu içeren doldurma daha iyidir.
  func isBetter(than other: Fill) -> Bool {
    let letters = words.reduce(0) { $0 + $1.letters.count }
    let otherLetters = other.words.reduce(0) { $0 + $1.letters.count }
    return (dueCount, letters) > (other.dueCount, otherLetters)
  }
}

/// Geri izlemeli (en kısıtlı yer önce) ızgara doldurucu.
///
/// Sıcak döngüler sözlük ve küme yerine uzunluğa göre dizilerle çalışır; hata ayıklama
/// derlemesinde de hızlı kalsın diye.
struct Filler {

  // MARK: - Properties

  /// Uzunluğa göre adaylar (dizin = uzunluk); tekrar kelimeleri önde.
  private let byLength: [[Candidate]]
  /// Uzunluğa göre adayların harfleri art arda (aday sırası × uzunluk).
  private let lettersByLength: [[UInt8]]
  /// Uzunluğa göre aday sayısı.
  let lengthCounts: [Int: Int]
  /// Uzunluğa göre tekrar kelimesi sayısı.
  let dueLengthCounts: [Int: Int]
  /// Tekrar kelimeleri (uzunluk, sıra), uzundan kısaya.
  private let dueKeys: [(length: Int, index: Int)]
  private let width: Int

  // MARK: - Init

  /// Doldurucuyu adaylar ve ızgara genişliğiyle oluşturur.
  init(candidates: [Candidate], width: Int) {
    let maxLength = ReviewPuzzleBuilder.lengthRange.upperBound
    var lists = Array(repeating: [Candidate](), count: maxLength + 1)
    for candidate in candidates where candidate.letters.count <= maxLength {
      lists[candidate.letters.count].append(candidate)
    }
    byLength = lists
    lettersByLength = lists.map { $0.flatMap(\.letters) }
    var counts: [Int: Int] = [:]
    var dueCounts: [Int: Int] = [:]
    var keys: [(length: Int, index: Int)] = []
    for length in stride(from: maxLength, through: 0, by: -1) where !lists[length].isEmpty {
      counts[length] = lists[length].count
      for (index, candidate) in lists[length].enumerated() where candidate.isDue {
        dueCounts[length, default: 0] += 1
        keys.append((length, index))
      }
    }
    lengthCounts = counts
    dueLengthCounts = dueCounts
    dueKeys = keys
    self.width = width
  }

  // MARK: - Filling

  /// Şablonu doldurur; düğüm sınırı içinde çözüm yoksa nil döner.
  func fill(_ template: Template, rng: inout SeededGenerator) -> Fill? {
    var state = State(
      grid: Array(repeating: 0, count: template.width * template.height),
      assignment: Array(repeating: -1, count: template.slots.count),
      used: byLength.map { Array(repeating: false, count: $0.count) })
    let slotIndices = template.slots.map { slot in
      slot.cells.map { $0.row * width + $0.col }
    }
    guard placeDue(dueKeys[...], slotIndices, &state, rng: &rng) else { return nil }
    var words: [Candidate] = []
    for (index, pick) in state.assignment.enumerated() {
      let list = byLength[template.slots[index].cells.count]
      guard list.indices.contains(pick) else { return nil }
      words.append(list[pick])
    }
    return Fill(template: template, words: words)
  }

  /// Arama durumu.
  private struct State {
    /// Harf kodları (0 = boş).
    var grid: [UInt8]
    /// Her kelime yerine seçilen adayın uzunluk listesindeki sırası (-1 = boş).
    var assignment: [Int]
    /// Kullanılan adaylar (uzunluk → sıra).
    var used: [[Bool]]
    /// Ziyaret edilen düğüm sayısı.
    var nodes = 0
  }

  /// Bir sonraki yeri seçip adayları sırayla dener: tekrar kelimesi sığabilen yerler önce,
  /// yoksa en kısıtlı yer.
  private func solve(
    _ slots: [[Int]], _ state: inout State, rng: inout SeededGenerator
  ) -> Bool {
    state.nodes += 1
    guard state.nodes <= ReviewPuzzleBuilder.nodeLimit else { return false }
    var best: (slot: Int, picks: [Int])?
    var bestDue: (slot: Int, picks: [Int])?
    for (index, cells) in slots.enumerated() where state.assignment[index] < 0 {
      let picks = matches(cells, state)
      if picks.isEmpty { return false }
      if best.map({ picks.count < $0.picks.count }) ?? true { best = (index, picks) }
      let list = byLength[cells.count]
      if list[picks[0]].isDue, bestDue.map({ picks.count < $0.picks.count }) ?? true {
        bestDue = (index, picks)
      }
    }
    guard let best = bestDue ?? best else { return true }
    let cells = slots[best.slot]
    for pick in ordered(best.picks, length: cells.count, rng: &rng)
      .prefix(ReviewPuzzleBuilder.branchLimit)
    {
      let placed = place(pick, in: best.slot, cells: cells, &state)
      if solve(slots, &state, rng: &rng) { return true }
      unplace(pick, from: best.slot, length: cells.count, placed: placed, &state)
    }
    return false
  }

  /// Önce tekrar kelimelerini tek tek uygun yerlere koyar (sığmayanı atlar), sonra kalan
  /// yerleri `solve` ile doldurur.
  private func placeDue(
    _ dues: ArraySlice<(length: Int, index: Int)>, _ slots: [[Int]], _ state: inout State,
    rng: inout SeededGenerator
  ) -> Bool {
    guard let due = dues.first else { return solve(slots, &state, rng: &rng) }
    state.nodes += 1
    guard state.nodes <= ReviewPuzzleBuilder.nodeLimit else { return false }
    var targets = slots.indices.filter { index in
      state.assignment[index] < 0 && slots[index].count == due.length
        && fits(due.index, slots[index], state)
    }
    targets.shuffle(using: &rng)
    for target in targets {
      let placed = place(due.index, in: target, cells: slots[target], &state)
      let consistent = slots.indices.allSatisfy { index in
        state.assignment[index] >= 0 || hasMatch(slots[index], state)
      }
      if consistent, placeDue(dues.dropFirst(), slots, &state, rng: &rng) { return true }
      unplace(due.index, from: target, length: due.length, placed: placed, &state)
    }
    return placeDue(dues.dropFirst(), slots, &state, rng: &rng)
  }

  // MARK: - Helpers

  /// Adayı yere yazar; yeni doldurulan kutuları döner.
  private func place(_ pick: Int, in slot: Int, cells: [Int], _ state: inout State) -> [Int] {
    let letters = lettersByLength[cells.count]
    let base = pick * cells.count
    var placed: [Int] = []
    for offset in 0..<cells.count where state.grid[cells[offset]] == 0 {
      state.grid[cells[offset]] = letters[base + offset]
      placed.append(cells[offset])
    }
    state.assignment[slot] = pick
    state.used[cells.count][pick] = true
    return placed
  }

  /// `place` işlemini geri alır.
  private func unplace(
    _ pick: Int, from slot: Int, length: Int, placed: [Int], _ state: inout State
  ) {
    state.assignment[slot] = -1
    state.used[length][pick] = false
    for cell in placed { state.grid[cell] = 0 }
  }

  /// Aday, kutulardaki harflerle uyuşuyor mu.
  private func fits(_ pick: Int, _ cells: [Int], _ state: State) -> Bool {
    let letters = lettersByLength[cells.count]
    let base = pick * cells.count
    for offset in 0..<cells.count {
      let current = state.grid[cells[offset]]
      if current != 0 && current != letters[base + offset] { return false }
    }
    return true
  }

  /// Kutulara uyan kullanılmamış en az bir aday var mı.
  private func hasMatch(_ cells: [Int], _ state: State) -> Bool {
    !scan(cells, state, firstOnly: true).isEmpty
  }

  /// Kutulardaki harflerle uyuşan, kullanılmamış adayların sıraları.
  private func matches(_ cells: [Int], _ state: State) -> [Int] {
    scan(cells, state, firstOnly: false)
  }

  /// Uyan adayları tarar; `firstOnly` ise ilkinde durur.
  ///
  /// En sık çalışan döngü olduğu için tampon işaretçileri ve `while` kullanır (hata ayıklama
  /// derlemesinde genel yineleyiciler çok yavaştır).
  private func scan(_ cells: [Int], _ state: State, firstOnly: Bool) -> [Int] {
    let length = cells.count
    var result: [Int] = []
    lettersByLength[length].withUnsafeBufferPointer { letters in
      state.grid.withUnsafeBufferPointer { grid in
        cells.withUnsafeBufferPointer { cellIndices in
          state.used[length].withUnsafeBufferPointer { used in
            var pick = 0
            while pick < used.count {
              if !used[pick] {
                let base = pick * length
                var offset = 0
                while offset < length {
                  let current = grid[cellIndices[offset]]
                  if current != 0 && current != letters[base + offset] { break }
                  offset += 1
                }
                if offset == length {
                  result.append(pick)
                  if firstOnly { return }
                }
              }
              pick += 1
            }
          }
        }
      }
    }
    return result
  }

  /// Adayları karıştırır; tekrar kelimeleri önde, sonra aynı seviye, sonra diğerleri.
  private func ordered(_ picks: [Int], length: Int, rng: inout SeededGenerator) -> [Int] {
    let list = byLength[length]
    var groups: [[Int]] = Array(repeating: [], count: 4)
    for pick in picks { groups[min(list[pick].tier, 3)].append(pick) }
    return groups.flatMap { group -> [Int] in
      var group = group
      group.shuffle(using: &rng)
      return group
    }
  }
}
