import Foundation
import SQLKit

/// Gerencia a execução de migrações e mantém o histórico no banco de dados.
public struct SQLKitMigrationRunner: Sendable {
    private let db: any SQLDatabase
    
    public init(db: any SQLDatabase) {
        self.db = db
    }
    
    /// Executa as migrações fornecidas que ainda não foram aplicadas.
    public func run(_ migrations: [any Migration]) async throws {
        // 1. Cria a tabela de metadados se não existir
        try await ensureMetaTableExists()
        
        // 2. Busca migrações já executadas
        let appliedMigrations = try await db.select()
            .column("name")
            .from("migrations_meta")
            .all()
            .map { try $0.decode(column: "name", as: String.self) }
            
        let appliedSet = Set(appliedMigrations)
        
        // 3. Executa apenas as novas
        for migration in migrations {
            if !appliedSet.contains(migration.name) {
                print("⏳ Applying migration: \(migration.name)...")
                try await migration.prepare(on: db)
                
                try await db.insert(into: "migrations_meta")
                    .columns("name")
                    .values(SQLBind(migration.name))
                    .run()
                print("✅ Applied: \(migration.name)")
            }
        }
    }
    
    private func ensureMetaTableExists() async throws {
        do {
            try await db.create(table: "migrations_meta")
                .column("name", type: .text, .primaryKey, .notNull)
                .run()
        } catch {
            // Se falhar porque a tabela já existe, ignoramos.
        }
    }
}
