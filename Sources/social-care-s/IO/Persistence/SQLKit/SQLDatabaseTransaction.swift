import SQLKit
import PostgresKit
import PostgresNIO
import NIO
import Logging

extension SQLDatabase {
    /// Helper para executar transações se o banco de dados suportar.
    /// Esta extensão simplifica o uso comum em repositórios que já recebem um `any SQLDatabase`.
    public func transaction<T: Sendable>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> T) async throws -> T {
        
        // 1. Tentar casting para PostgresDatabase (do PostgresKit)
        // O SQLKit wrapper do PostgresKit também conforma a PostgresDatabase.
        if let postgres = self as? any PostgresDatabase {
            let logger = self.logger
            return try await postgres.withConnection { conn in
                // O PostgresConnection (do PostgresNIO) tem o withTransaction real
                conn.eventLoop.makeFutureWithTask {
                    try await conn.withTransaction(logger: logger) { _ in
                        // Criamos um wrapper SQLDatabase sobre a conexão da transação
                        // O PostgresKit provê .sql() em PostgresDatabase
                        try await closure(conn.sql())
                    }
                }
            }.get()
        }
        
        // 2. Fallback para outros drivers via SQL bruto (menos seguro mas funcional para o MVP)
        return try await self.withSession { session in
            try await session.execute(sql: SQLRaw("BEGIN"), { _ in }).get()
            do {
                let result = try await closure(session)
                try await session.execute(sql: SQLRaw("COMMIT"), { _ in }).get()
                return result
            } catch {
                try await session.execute(sql: SQLRaw("ROLLBACK"), { _ in }).get()
                throw error
            }
        }
    }
}
