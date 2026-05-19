import Foundation
@testable import GolfCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Canned-response transport for client tests — no real network.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    enum Outcome {
        case success(status: Int, body: Data)
        case failure(Error)
    }

    private let outcome: Outcome
    private(set) var lastRequest: URLRequest?

    init(json: String, status: Int = 200) {
        self.outcome = .success(status: status, body: Data(json.utf8))
    }
    init(status: Int, json: String = "{}") {
        self.outcome = .success(status: status, body: Data(json.utf8))
    }
    init(error: Error) {
        self.outcome = .failure(error)
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        switch outcome {
        case let .success(status, body):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (body, response)
        case let .failure(error):
            throw error
        }
    }
}
