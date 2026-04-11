import Foundation
import SQLKit

struct AddUniqueCpfConstraint: Migration {
    let name = "2026_04_08_AddUniqueCpfConstraint"

    func prepare(on db: any SQLDatabase) async throws {
        // Índice único parcial: garante unicidade de CPF apenas quando preenchido.
        // CPF é opcional no registro, mas quando informado não pode duplicar.
        try await db.execute(sql: SQLRaw("""
            CREATE UNIQUE INDEX idx_patients_cpf_unique
            ON patients (cpf)
            WHERE cpf IS NOT NULL
        """), { _ in }).get()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.drop(index: "idx_patients_cpf_unique").run()
    }
}
