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

        request.authenticatedUser = AuthenticatedUser(
            userId: payload.sub.value,
            roles: payload.roleNames
        )

        return try await next.respond(to: request)
    }
}
