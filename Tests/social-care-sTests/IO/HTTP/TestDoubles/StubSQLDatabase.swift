import Foundation
import Logging
import NIOCore
import PostgresKit
import SQLKit

/// `SQLDatabase` de mentira, para que os testes de integração HTTP montem o
/// `ServiceContainer` real **sem** PostgreSQL.
///
/// POR QUÊ: `ServiceContainer.init` só aceita `db: any SQLDatabase` e constrói
/// os repositórios SQLKit por dentro — não há ponto de injeção para fakes de
/// repositório. Sem este stub, qualquer requisição que atravesse o `RoleGuard`
/// e chegue no controller precisaria de um banco de verdade, e o gap G10
/// pararia na porta do controller (justamente o elo que ninguém exercita).
///
/// O que ele NÃO é: um banco. Toda query devolve **zero linhas**. Isso basta
/// para exercitar `rota → middleware → controller → handler → repositório` e
/// observar a resposta HTTP; não serve para testar SQL nem mapeamento de linha
/// (isso é papel dos testes de Application com os fakes in-memory).
///
/// `dialect` é o `PostgresDialect` real de propósito: a serialização que os
/// query builders fazem é a mesma de produção, então um builder que quebre ao
/// serializar quebra aqui também, em vez de passar por um dialect de brinquedo.
final class StubSQLDatabase: SQLDatabase, @unchecked Sendable {

    let logger: Logger
    let eventLoop: any EventLoop
    let dialect: any SQLDialect = PostgresDialect()

    /// Quando presente, toda query falha com este erro — usado para exercitar
    /// o caminho de indisponibilidade (`/ready` → 503).
    private let failure: (any Error)?

    private let lock = NSLock()
    private var _executedSQL: [String] = []

    /// SQL serializado de cada query que passou por aqui, na ordem.
    /// Serve para afirmar que a requisição chegou mesmo no repositório.
    var executedSQL: [String] {
        lock.withLock { _executedSQL }
    }

    init(
        eventLoop: any EventLoop,
        logger: Logger = Logger(label: "test.stub-sql"),
        failure: (any Error)? = nil
    ) {
        self.eventLoop = eventLoop
        self.logger = logger
        self.failure = failure
    }

    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        let (sql, _) = serialize(query)
        lock.withLock { _executedSQL.append(sql) }

        if let failure {
            return eventLoop.makeFailedFuture(failure)
        }
        // Zero linhas: `onRow` nunca é chamado.
        return eventLoop.makeSucceededVoidFuture()
    }
}

/// Erro genérico de indisponibilidade do banco, para o caminho `/ready` → 503.
struct StubDatabaseUnavailable: Error {}
