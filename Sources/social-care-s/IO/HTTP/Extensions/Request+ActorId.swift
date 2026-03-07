import Vapor

extension Request {
    /// Extrai o identificador do ator da requisição.
    /// Por enquanto usa o header `X-Actor-Id`. Futuramente será extraído do JWT.
    func extractActorId() throws -> String {
        guard let actorId = headers.first(name: "X-Actor-Id"), !actorId.isEmpty else {
            throw Abort(.badRequest, reason: "Missing required header: X-Actor-Id")
        }
        return actorId
    }
}
