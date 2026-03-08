import Vapor
import SQLKit

struct LookupController: RouteCollection {
    private static let allowedTables: Set<String> = [
        "dominio_tipo_identidade",
        "dominio_parentesco",
        "dominio_condicao_ocupacao",
        "dominio_escolaridade",
        "dominio_efeito_condicionalidade",
        "dominio_tipo_deficiencia",
        "dominio_programa_social",
        "dominio_tipo_ingresso",
        "dominio_tipo_beneficio",
        "dominio_tipo_violacao",
        "dominio_servico_vinculo",
        "dominio_tipo_medida",
        "dominio_unidade_realizacao",
    ]

    func boot(routes: any RoutesBuilder) throws {
        let dominios = routes.grouped("api", "v1", "dominios")
            .grouped(RoleGuardMiddleware("social_worker", "owner", "admin"))
        dominios.get(":tableName", use: list)
    }

    @Sendable
    private func list(req: Request) async throws -> StandardResponse<[LookupItemResponse]> {
        let tableName = try req.parameters.require("tableName")

        guard Self.allowedTables.contains(tableName) else {
            throw Abort(.notFound, reason: "Dominio '\(tableName)' not found.")
        }

        let db = req.services.db
        let rows = try await db.select()
            .column("id")
            .column("codigo")
            .column("descricao")
            .from(tableName)
            .where("ativo", .equal, true)
            .orderBy("codigo")
            .all()

        let items = try rows.map { row in
            LookupItemResponse(
                id: try row.decode(column: "id", as: UUID.self).uuidString,
                codigo: try row.decode(column: "codigo", as: String.self),
                descricao: try row.decode(column: "descricao", as: String.self)
            )
        }

        return StandardResponse(data: items)
    }
}
