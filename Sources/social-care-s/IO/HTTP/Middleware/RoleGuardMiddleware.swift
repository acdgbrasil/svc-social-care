import Vapor

struct RoleGuardMiddleware: AsyncMiddleware {
    let allowed: Set<String>

    init(_ roles: String...) {
        self.allowed = Set(roles)
    }

    init(_ roles: Set<String>) {
        self.allowed = roles
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let user = try request.requireAuthenticatedUser()

        guard user.hasAnyRole(allowed) else {
            throw Abort(.forbidden, reason: "Insufficient permissions.")
        }

        return try await next.respond(to: request)
    }
}
