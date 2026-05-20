import Foundation

/// The tees a player can pick. Each carries its own difficulty ratings.
public enum TeeBox: String, Codable, CaseIterable, Sendable {
    case blue, white, red
}

public struct TeeRating: Codable, Hashable, Sendable {
    /// Expected strokes for a scratch golfer, to one decimal (e.g. 72.1).
    public let courseRating: Double
    /// Relative difficulty for the bogey golfer, 55...155.
    public let slopeRating: Int

    public init(courseRating: Double, slopeRating: Int) {
        self.courseRating = courseRating
        self.slopeRating = slopeRating
    }
}

/// A hole as needed for manual scoring + WHS handicap calculation.
/// No geography — the MVP doesn't need tee/green coordinates.
public struct Hole: Codable, Hashable, Identifiable, Sendable {
    public let id: Int          // 1...18
    public let par: Int
    /// Stroke index / handicap order, 1 = hardest hole.
    public let strokeIndex: Int

    public init(id: Int, par: Int, strokeIndex: Int) {
        self.id = id
        self.par = par
        self.strokeIndex = strokeIndex
    }
}

public struct Course: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let holes: [Hole]
    public let ratings: [TeeBox: TeeRating]

    public init(id: String, name: String, holes: [Hole], ratings: [TeeBox: TeeRating]) {
        self.id = id
        self.name = name
        self.holes = holes
        self.ratings = ratings
    }

    public var par: Int { holes.reduce(0) { $0 + $1.par } }

    public func hole(_ number: Int) -> Hole? {
        holes.first { $0.id == number }
    }
}
