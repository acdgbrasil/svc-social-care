import Vapor

struct AuthenticatedUser: Sendable {
    let userId: String
    let roles: Set<String>

    func hasRole(_ role: String) -> Bool {
        roles.contains(role)
    }

    func hasAnyRole(_ required: Set<String>) -> Bool {
        !roles.isDisjoint(with: required)
    }
}

private struct AuthenticatedUserKey: StorageKey {
    typealias Value = AuthenticatedUser
}

extension Request {
    var authenticatedUser: AuthenticatedUser? {
        get { storage[AuthenticatedUserKey.self] }
        set { storage[AuthenticatedUserKey.self] = newValue }
    }

    func requireAuthenticatedUser() throws -> AuthenticatedUser {
        guard let user = authenticatedUser else {
            throw Abort(.unauthorized, reason: "Authentication required.")
        }
        return user
    }
}
