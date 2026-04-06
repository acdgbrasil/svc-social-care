import Foundation
import Logging
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Validates PersonId existence by calling the people-context REST API.
///
/// GET /api/v1/people/:personId
/// - 200 → person exists
/// - 404 → person not found
/// - Other → logs warning, returns true (fail-open to not block registration)
public struct PeopleContextPersonValidator: PersonExistenceValidating, Sendable {
    private let baseURL: String
    private let logger: Logger

    public init(baseURL: String) {
        self.baseURL = baseURL
        self.logger = Logger(label: "people-context-validator")
    }

    public func exists(personId: PersonId) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/v1/people/\(personId.description)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.warning("Invalid response from people-context for PersonId \(personId.description)")
                return true // fail-open
            }

            switch httpResponse.statusCode {
            case 200:
                return true
            case 404:
                return false
            default:
                logger.warning("people-context returned \(httpResponse.statusCode) for PersonId \(personId.description) — fail-open")
                return true // fail-open: don't block registration on infra issues
            }
        } catch {
            logger.warning("people-context unreachable: \(error) — fail-open")
            return true // fail-open
        }
    }
}
