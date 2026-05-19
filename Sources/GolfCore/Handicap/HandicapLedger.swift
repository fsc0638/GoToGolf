import Foundation

/// Persisted accepted-score history. The Handicap Index is always derived
/// from the differentials via `WHSEngine`, never stored stale.
public struct HandicapLedger: Codable, Equatable, Sendable {
    public private(set) var differentials: [Double]

    public init(differentials: [Double] = []) {
        self.differentials = differentials
    }

    public var index: Double? {
        WHSEngine.handicapIndex(from: differentials)
    }

    public var acceptedCount: Int {
        differentials.count
    }

    public mutating func record(_ differential: Double) {
        differentials.append(differential)
    }

    // MARK: - Disk persistence

    public static func read(from url: URL) -> HandicapLedger {
        guard let data = try? Data(contentsOf: url),
              let ledger = try? JSONDecoder().decode(HandicapLedger.self, from: data)
        else { return HandicapLedger() }
        return ledger
    }

    public func write(to url: URL) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
