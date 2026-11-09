import ContentKit

/// Testler için örnek paket.
enum ContentFixture {
  static let pack = Pack(
    id: "a1", title: "A1", subtitle: "", kind: .level, level: .a1, order: 0, freeCount: 4,
    productId: nil, puzzleIds: (1...12).map { "a1_\($0)" }, wordCount: 40)
}
