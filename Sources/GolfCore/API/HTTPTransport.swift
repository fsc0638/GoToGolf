import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Seam over the network so every client is testable without real I/O:
/// production wraps `URLSession`, tests inject canned responses.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GolfAPIError.nonHTTPResponse
        }
        return (data, http)
    }
}

public enum GolfAPIError: Error, Equatable {
    case invalidURL
    case nonHTTPResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    public static func == (lhs: GolfAPIError, rhs: GolfAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.nonHTTPResponse, .nonHTTPResponse):
            return true
        case let (.httpStatus(a), .httpStatus(b)):
            return a == b
        case let (.decoding(a), .decoding(b)):
            return a == b
        case let (.transport(a), .transport(b)):
            return a == b
        default:
            return false
        }
    }
}

/// Shared GET + decode pipeline. Status and decoding failures are mapped to
/// `GolfAPIError` here — the only place external input is validated.
struct APIClientCore {
    let transport: HTTPTransport
    let decoder: JSONDecoder

    init(transport: HTTPTransport, decoder: JSONDecoder = JSONDecoder()) {
        self.transport = transport
        self.decoder = decoder
    }

    func get<T: Decodable>(_ url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let (data, http): (Data, HTTPURLResponse)
        do {
            (data, http) = try await transport.send(request)
        } catch let error as GolfAPIError {
            throw error
        } catch {
            throw GolfAPIError.transport(String(describing: error))
        }

        guard (200..<300).contains(http.statusCode) else {
            throw GolfAPIError.httpStatus(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GolfAPIError.decoding(String(describing: error))
        }
    }
}
