import Foundation
import SQLKit

/// Implementacao concreta de `LookupValidating` utilizando SQLKit.
///
/// Consulta as tabelas de dominio (`dominio_*`) para verificar
/// se um dado `LookupId` existe e esta ativo.
struct SQLKitLookupRepository: LookupValidating {
    private let db: any SQLDatabase

    init(db: any SQLDatabase) {
        self.db = db
    }

    func exists(id: LookupId, in table: String) async throws -> Bool {
        guard let uuid = UUID(uuidString: id.description) else {
            return false
        }

        let count = try await db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all))
            .from(table)
            .where("id", .equal, uuid)
            .where("ativo", .equal, true)
            .first()
            .map { try $0.decode(column: "count", as: Int.self) } ?? 0

        return count > 0
    }
}
