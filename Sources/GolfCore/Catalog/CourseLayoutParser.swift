import Foundation

/// Lightweight identity of a course, decodable from the iGolf layout JSON
/// header alone — used to populate a course picker without parsing every
/// hole.
public struct CourseSummary: Decodable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    private enum CodingKeys: String, CodingKey {
        case id = "courseId"
        case name
    }
}

/// Decodes the iGolf course-data JSON contract straight from `Data`, so the
/// app can load bundled / cached course 圖資 with no network or API key.
/// The real `IGolfClient` parses the same contract, so a bundled course and
/// a fetched one produce identical `Course` values.
public enum CourseLayoutParser {

    public static func course(fromLayoutJSON data: Data) throws -> Course {
        do {
            return try JSONDecoder().decode(CourseLayoutDTO.self, from: data).toDomain()
        } catch {
            throw GolfAPIError.decoding(String(describing: error))
        }
    }

    public static func course(fromSimpleGPSJSON data: Data) throws -> Course {
        do {
            return try JSONDecoder().decode(SimpleGPSCourseDTO.self, from: data).toDomain()
        } catch {
            throw GolfAPIError.decoding(String(describing: error))
        }
    }

    public static func summary(fromLayoutJSON data: Data) throws -> CourseSummary {
        do {
            return try JSONDecoder().decode(CourseSummary.self, from: data)
        } catch {
            throw GolfAPIError.decoding(String(describing: error))
        }
    }
}
