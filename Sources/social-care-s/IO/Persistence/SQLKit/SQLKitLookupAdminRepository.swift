import Foundation
import SQLKit

struct SQLKitLookupAdminRepository: LookupRepository {
    private let db: any SQLDatabase

    init(db: any SQLDatabase) {
        self.db = db
    }

    private static let referenceMap: [String: [(table: String, column: String)]] = [
        "dominio_parentesco": [("family_members", "relationship")],
        "dominio_tipo_identidade": [("patients", "social_identity_type_id")],
        "dominio_condicao_ocupacao": [("member_incomes", "occupation_id")],
        "dominio_escolaridade": [("member_educational_profiles", "education_level_id")],
        "dominio_efeito_condicionalidade": [("program_occurrences", "effect_id")],
        "dominio_tipo_deficiencia": [("member_deficiencies", "deficiency_type_id")],
        "dominio_tipo_ingresso": [("patients", "ii_ingress_type_id")],
        "dominio_programa_social": [("ingress_linked_programs", "program_id")],
        "dominio_tipo_beneficio": [],
        "dominio_tipo_violacao": [],
        "dominio_servico_vinculo": [],
        "dominio_tipo_medida": [],
        "dominio_unidade_realizacao": [],
    ]

    func codigoExists(in table: String, codigo: String) async throws -> Bool {
        let count = try await db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
            .from(table)
            .where("codigo", .equal, codigo)
            .first()
            .map { try $0.decode(column: "count", as: Int.self) } ?? 0
        return count > 0
    }

    func itemExists(in table: String, id: UUID) async throws -> Bool {
        let count = try await db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
            .from(table)
            .where("id", .equal, id)
            .first()
            .map { try $0.decode(column: "count", as: Int.self) } ?? 0
        return count > 0
    }

    func isItemReferenced(in table: String, id: UUID) async throws -> Bool {
        guard let refs = Self.referenceMap[table] else { return false }

        for ref in refs {
            let count = try await db.select()
                .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
                .from(ref.table)
                .where(SQLColumn(ref.column), .equal, SQLBind(id.uuidString))
                .first()
                .map { try $0.decode(column: "count", as: Int.self) } ?? 0

            if count > 0 { return true }
        }

        return false
    }

    func createItem(in table: String, id: UUID, codigo: String, descricao: String,
                    metadata: LookupItemMetadata?) async throws {
        if table == "dominio_tipo_beneficio" {
            try await db.insert(into: table)
                .columns("id", "codigo", "descricao", "exige_registro_nascimento", "exige_cpf_falecido")
                .values(
                    SQLBind(id), SQLBind(codigo), SQLBind(descricao),
                    SQLBind(metadata?.exigeRegistroNascimento ?? false),
                    SQLBind(metadata?.exigeCpfFalecido ?? false)
                )
                .run()
        } else if table == "dominio_tipo_violacao" {
            try await db.insert(into: table)
                .columns("id", "codigo", "descricao", "exige_descricao")
                .values(
                    SQLBind(id), SQLBind(codigo), SQLBind(descricao),
                    SQLBind(metadata?.exigeDescricao ?? false)
                )
                .run()
        } else {
            try await db.insert(into: table)
                .columns("id", "codigo", "descricao")
                .values(SQLBind(id), SQLBind(codigo), SQLBind(descricao))
                .run()
        }
    }

    func updateDescription(in table: String, id: UUID, descricao: String) async throws {
        try await db.update(table)
            .set("descricao", to: descricao)
            .where("id", .equal, id)
            .run()
    }

    func toggleActive(in table: String, id: UUID) async throws {
        try await db.raw("""
            UPDATE \(unsafeRaw: table) SET ativo = NOT ativo WHERE id = \(bind: id)
            """).run()
    }
}
