import Foundation

/// A course in the bundled / curated catalog, with display-side metadata
/// (region) attached. The `Course` itself stays geography-free.
public struct CourseListing: Equatable, Sendable, Identifiable {
    public let course: Course
    public let region: String?
    public var id: String { course.id }

    public init(course: Course, region: String?) {
        self.course = course
        self.region = region
    }
}

public enum ScoringCatalogError: Error, Equatable {
    case decoding(String)
}

/// Decodes the scoring-only course catalog JSON used by the App. Schema:
/// ```
/// { "id": "TW-TAMSUI", "name": "...", "region": "新北市",
///   "holes": [ { "number": 1, "par": 4, "strokeIndex": 7 }, ... ],
///   "ratings": { "white": { "courseRating": 70.0, "slopeRating": 122 } } }
/// ```
/// A catalog file is a JSON array of these.
public enum ScoringCatalogParser {

    public static func course(fromCourseJSON data: Data) throws -> Course {
        do { return try JSONDecoder().decode(ScoringCourseDTO.self, from: data).toDomain() }
        catch { throw ScoringCatalogError.decoding(String(describing: error)) }
    }

    public static func listing(fromCourseJSON data: Data) throws -> CourseListing {
        do {
            let dto = try JSONDecoder().decode(ScoringCourseDTO.self, from: data)
            return CourseListing(course: dto.toDomain(), region: dto.region)
        } catch { throw ScoringCatalogError.decoding(String(describing: error)) }
    }

    public static func catalog(fromCatalogJSON data: Data) throws -> [CourseListing] {
        do {
            let dtos = try JSONDecoder().decode([ScoringCourseDTO].self, from: data)
            return dtos.map { CourseListing(course: $0.toDomain(), region: $0.region) }
        } catch { throw ScoringCatalogError.decoding(String(describing: error)) }
    }
}

// MARK: - Internal DTOs

struct ScoringCourseDTO: Decodable {
    let id: String
    let name: String
    let region: String?
    let holes: [ScoringHoleDTO]
    let ratings: [String: TeeRatingDTO]?

    func toDomain() -> Course {
        var mapped: [TeeBox: TeeRating] = [:]
        for (key, value) in ratings ?? [:] {
            if let box = TeeBox(rawValue: key) { mapped[box] = value.domain }
        }
        let domainHoles = holes.enumerated().map { idx, h in
            Hole(id: h.number, par: h.par, strokeIndex: h.strokeIndex ?? (idx + 1))
        }
        return Course(
            id: id, name: name,
            holes: domainHoles.sorted { $0.id < $1.id },
            ratings: mapped
        )
    }
}

struct ScoringHoleDTO: Decodable {
    let number: Int
    let par: Int
    let strokeIndex: Int?
}
