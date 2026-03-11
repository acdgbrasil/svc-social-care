import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    private static let publicPaths: Set<String> = ["/health", "/ready"]

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if Self.publicPaths.contains(request.url.path) {
            return try await next.respond(to: request)
        }

        let payload: ZitadelJWTPayload
        do {
            payload = try await request.jwt.verify(as: ZitadelJWTPayload.self)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token.")
        }

        var roles = payload.roleNames

        if roles.isEmpty, let introspector = request.application.tokenIntrospector {
            let allowedAccounts = request.application.allowedServiceAccounts
            guard allowedAccounts.contains(payload.sub.value) else {
                throw Abort(.forbidden, reason: "Service account not authorized.")
            }
            let token = request.bearerToken ?? ""
            roles = try await introspector.introspect(token: token, client: request.client)
        }

        request.authenticatedUser = AuthenticatedUser(
            userId: payload.sub.value,
            roles: roles
        )

        return try await next.respond(to: request)
    }
}

private extension Request {
    var bearerToken: String? {
        headers.bearerAuthorization?.token
    }
}
