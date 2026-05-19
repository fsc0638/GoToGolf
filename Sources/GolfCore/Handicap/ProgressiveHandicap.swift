import Foundation

extension WHSEngine {

    /// How the progressive table selects differentials for a given count.
    public struct Selection: Equatable, Sendable {
        public let lowestCount: Int
        public let adjustment: Double
    }

    /// Product-spec progressive table.
    ///
    /// | Rounds | Lowest used | Adjustment |
    /// |--------|-------------|------------|
    /// | 3      | 1           | -2.0       |
    /// | 4...6  | 2           | -1.0       |
    /// | 7...8  | 2           |  0         |
    /// | 9...11 | 3           |  0         |
    /// | 12...14| 4           |  0         |
    /// | 15...16| 5           |  0         |
    /// | 17...18| 6           |  0         |
    /// | 19     | 7           |  0         |
    /// | 20+    | 8           |  0  (rolling, best 8 of last 20) |
    public static func selection(forRoundCount n: Int) -> Selection? {
        switch n {
        case ..<3:      return nil
        case 3:         return Selection(lowestCount: 1, adjustment: -2.0)
        case 4...6:     return Selection(lowestCount: 2, adjustment: -1.0)
        case 7...8:     return Selection(lowestCount: 2, adjustment: 0)
        case 9...11:    return Selection(lowestCount: 3, adjustment: 0)
        case 12...14:   return Selection(lowestCount: 4, adjustment: 0)
        case 15...16:   return Selection(lowestCount: 5, adjustment: 0)
        case 17...18:   return Selection(lowestCount: 6, adjustment: 0)
        case 19:        return Selection(lowestCount: 7, adjustment: 0)
        default:        return Selection(lowestCount: 8, adjustment: 0)
        }
    }

    /// Handicap Index from a player's differential history (any order).
    ///
    /// Returns `nil` until at least 3 acceptable scores exist. For 20+
    /// rounds only the most recent 20 are considered (rolling window),
    /// from which the best 8 are averaged.
    public static func handicapIndex(from differentials: [Double]) -> Double? {
        guard let selection = selection(forRoundCount: differentials.count) else {
            return nil
        }

        let pool: [Double]
        if differentials.count >= 20 {
            pool = Array(differentials.suffix(20))   // most recent 20
        } else {
            pool = differentials
        }

        let lowest = pool.sorted().prefix(selection.lowestCount)
        let average = lowest.reduce(0, +) / Double(lowest.count)
        let index = average + selection.adjustment
        return (index * 10).rounded() / 10
    }
}
