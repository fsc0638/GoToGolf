import Foundation

/// The tees a beginner can pick. Each carries its own difficulty ratings.
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

public struct GreenPoints: Codable, Hashable, Sendable {
    public let front: GeoCoordinate
    public let center: GeoCoordinate
    public let back: GeoCoordinate

    public init(front: GeoCoordinate, center: GeoCoordinate, back: GeoCoordinate) {
        self.front = front
        self.center = center
        self.back = back
    }
}

public struct Hole: Codable, Hashable, Identifiable, Sendable {
    public let id: Int          // 1...18
    public let par: Int
    /// Stroke index / handicap order, 1 = hardest hole.
    public let strokeIndex: Int
    public let tee: GeoCoordinate
    public let green: GreenPoints
    public let hazards: [GeoCoordinate]

    public init(
        id: Int,
        par: Int,
        strokeIndex: Int,
        tee: GeoCoordinate,
        green: GreenPoints,
        hazards: [GeoCoordinate] = []
    ) {
        self.id = id
        self.par = par
        self.strokeIndex = strokeIndex
        self.tee = tee
        self.green = green
        self.hazards = hazards
    }
}

public struct Course: Codable, Hashable, Identifiable, Sendable {
    public let id: String       // iGolf external id
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
