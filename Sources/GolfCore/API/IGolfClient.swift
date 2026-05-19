import Foundation

public struct IGolfConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String

    public init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
}

/// Client for iGolf course geography.
///
/// `courseLayout` pulls the full vector package (polygons → Mapbox) once at
/// round start; `simpleGPS` pulls the few-KB key-point package for the watch
/// and offline play.
public struct IGolfClient {
    private let config: IGolfConfig
    private let core: APIClientCore

    public init(config: IGolfConfig, transport: HTTPTransport = URLSessionTransport()) {
        self.config = config
        self.core = APIClientCore(transport: transport)
    }

    private func url(path: String) throws -> URL {
        guard var components = URLComponents(
            url: config.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw GolfAPIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]
        guard let url = components.url else { throw GolfAPIError.invalidURL }
        return url
    }

    private var authHeaders: [String: String] {
        ["Authorization": "Bearer \(config.apiKey)", "Accept": "application/json"]
    }

    public func courseLayout(courseID: String) async throws -> Course {
        let safeID = courseID.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? courseID
        let url = try url(path: "courses/\(safeID)/layout")
        let dto: CourseLayoutDTO = try await core.get(url, headers: authHeaders)
        return dto.toDomain()
    }

    public func simpleGPS(courseID: String) async throws -> Course {
        let safeID = courseID.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? courseID
        let url = try url(path: "courses/\(safeID)/simple-gps")
        let dto: SimpleGPSCourseDTO = try await core.get(url, headers: authHeaders)
        return dto.toDomain()
    }
}
