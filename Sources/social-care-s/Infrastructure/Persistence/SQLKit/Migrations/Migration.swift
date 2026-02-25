import SQLKit

/// Protocolo base para migrações utilizando SQLKit.
public protocol Migration: Sendable {
    /// O nome único da migração para controle de execução.
    var name: String { get }
    
    /// Executa as alterações de schema (UP).
    func prepare(on db: any SQLDatabase) async throws
    
    /// Reverte as alterações de schema (DOWN).
    func revert(on db: any SQLDatabase) async throws
}
