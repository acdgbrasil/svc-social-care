import Vapor

struct AuthenticatedUser: Sendable {
    let userId: String
    let roles: Set<String>

    /// "superadmin" bypasses all role checks.
    var isSuperAdmin: Bool {
        roles.contains("superadmin")
    }

    func hasRole(_ role: String) -> Bool {
        if isSuperAdmin { return true }
        // Supports composite keys: "social-care:worker" satisfies "worker"
        return roles.contains(role) || roles.contains(where: { $0.hasSuffix(":\(role)") })
    }

    func hasAnyRole(_ required: Set<String>) -> Bool {
        if isSuperAdmin { return true }
        return required.contains(where: { hasRole($0) })
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
