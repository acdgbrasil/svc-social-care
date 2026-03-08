import Vapor

extension Request {
    /// Extrai o identificador do ator autenticado via JWT.
    func extractActorId() throws -> String {
        let user = try requireAuthenticatedUser()
        return user.userId
    }
}
