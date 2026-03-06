import Hummingbird
import HummingbirdTesting
import SQLKit
import Foundation
@testable import social_care_s

/// Helper para facilitar testes de integração HTTP.
public struct TestWorld {
    public let router: Router<AppRequestContext>
    public let db: SQLDatabaseMock
    public let app: Application<RouterResponder<AppRequestContext>>

    /// Inicializa o mundo de teste.
    /// - Parameter configure: Closure para registrar rotas e middlewares ANTES da criação do App.
    public init(configure: (Router<AppRequestContext>, SQLDatabaseMock) -> Void) {
        let router = Router(context: AppRequestContext.self)
        let db = SQLDatabaseMock()

        // Configura rotas
        configure(router, db)

        self.router = router
        self.db = db
        self.app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 0))
        )
    }
    
    public func run(_ testBlock: @escaping @Sendable (any TestClientProtocol) async throws -> Void) async throws {
        try await self.app.test(.router) { client in
            try await testBlock(client)
        }
    }
}
