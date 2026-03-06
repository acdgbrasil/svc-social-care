import Foundation
import SQLKit

struct CreateLookupTables: Migration {
    let name = "2026_03_05_CreateLookupTables"

    // MARK: - Schema

    private let lookupTables = [
        "dominio_parentesco",
        "dominio_tipo_identidade",
        "dominio_condicao_ocupacao",
        "dominio_escolaridade",
        "dominio_efeito_condicionalidade",
        "dominio_tipo_deficiencia",
        "dominio_tipo_ingresso",
        "dominio_programa_social"
    ]

    func prepare(on db: any SQLDatabase) async throws {
        let uuidType = SQLRaw("UUID")
        let booleanType = SQLRaw("BOOLEAN")

        // 1. Criar as 8 tabelas de dominio com schema identico
        for table in lookupTables {
            try await db.create(table: table)
                .column("id", type: .custom(uuidType), .primaryKey, .notNull)
                .column("codigo", type: .text, .notNull, .unique)
                .column("descricao", type: .text, .notNull)
                .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
                .run()
        }

        // 2. Seed data
        try await seedParentesco(on: db)
        try await seedTipoIdentidade(on: db)
        try await seedCondicaoOcupacao(on: db)
        try await seedEscolaridade(on: db)
        try await seedEfeitoCondicionalidade(on: db)
        try await seedTipoDeficiencia(on: db)
        try await seedTipoIngresso(on: db)
        try await seedProgramaSocial(on: db)
    }

    func revert(on db: any SQLDatabase) async throws {
        for table in lookupTables.reversed() {
            try await db.drop(table: table).run()
        }
    }

    // MARK: - Seed Helpers

    private func insert(
        on db: any SQLDatabase,
        table: String,
        rows: [(codigo: String, descricao: String)]
    ) async throws {
        for row in rows {
            try await db.insert(into: table)
                .columns("id", "codigo", "descricao")
                .values(SQLFunction("gen_random_uuid"), SQLBind(row.codigo), SQLBind(row.descricao))
                .run()
        }
    }

    // MARK: - Parentesco (CadUnico)

    private func seedParentesco(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_parentesco", rows: [
            ("PESSOA_REFERENCIA", "Pessoa de Referencia"),
            ("CONJUGE_COMPANHEIRO", "Conjuge / Companheiro(a)"),
            ("FILHO_FILHA", "Filho(a)"),
            ("ENTEADO_ENTEADA", "Enteado(a)"),
            ("NETO_NETA", "Neto(a)"),
            ("PAI", "Pai"),
            ("MAE", "Mae"),
            ("SOGRO_SOGRA", "Sogro(a)"),
            ("IRMAO_IRMA", "Irmao / Irma"),
            ("GENRO_NORA", "Genro / Nora"),
            ("OUTRO_PARENTE", "Outro Parente"),
            ("NAO_PARENTE", "Nao Parente")
        ])
    }

    // MARK: - Tipo de Identidade Social

    private func seedTipoIdentidade(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_tipo_identidade", rows: [
            ("INDIGENA", "Indigena"),
            ("QUILOMBOLA", "Quilombola"),
            ("CIGANO", "Cigano(a)"),
            ("RIBEIRINHO", "Ribeirinho(a)"),
            ("EXTRATIVISTA", "Extrativista"),
            ("PESCADOR_ARTESANAL", "Pescador(a) Artesanal"),
            ("COMUNIDADE_TERREIRO", "Comunidade de Terreiro"),
            ("ASSENTADO_REFORMA_AGRARIA", "Assentado(a) da Reforma Agraria"),
            ("ACAMPADO", "Acampado(a)"),
            ("SITUACAO_RUA", "Pessoa em Situacao de Rua"),
            ("OUTRAS", "Outras")
        ])
    }

    // MARK: - Condicao de Ocupacao (CBO/MTE)

    private func seedCondicaoOcupacao(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_condicao_ocupacao", rows: [
            ("EMPREGADO_CARTEIRA", "Empregado com Carteira de Trabalho"),
            ("EMPREGADO_SEM_CARTEIRA", "Empregado sem Carteira de Trabalho"),
            ("AUTONOMO_CARTEIRA", "Autonomo com Previdencia Social"),
            ("AUTONOMO_SEM_CARTEIRA", "Autonomo sem Previdencia Social"),
            ("APOSENTADO_PENSIONISTA", "Aposentado(a) / Pensionista"),
            ("NAO_TRABALHA", "Nao Trabalha"),
            ("EMPREGADOR", "Empregador"),
            ("ESTAGIARIO", "Estagiario(a)"),
            ("APRENDIZ", "Aprendiz"),
            ("COOPERATIVADO", "Cooperativado(a)"),
            ("TRABALHO_DOMESTICO", "Trabalhador(a) Domestico(a)"),
            ("TRABALHO_RURAL", "Trabalhador(a) Rural")
        ])
    }

    // MARK: - Escolaridade (IBGE/MEC)

    private func seedEscolaridade(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_escolaridade", rows: [
            ("SEM_INSTRUCAO", "Sem instrucao"),
            ("FUNDAMENTAL_INCOMPLETO", "Ensino Fundamental incompleto"),
            ("FUNDAMENTAL_COMPLETO", "Ensino Fundamental completo"),
            ("MEDIO_INCOMPLETO", "Ensino Medio incompleto"),
            ("MEDIO_COMPLETO", "Ensino Medio completo"),
            ("SUPERIOR_INCOMPLETO", "Ensino Superior incompleto"),
            ("SUPERIOR_COMPLETO", "Ensino Superior completo"),
            ("POS_GRADUACAO", "Pos-graduacao"),
            ("CRECHE", "Creche"),
            ("PRE_ESCOLA", "Pre-escola"),
            ("CLASSE_ALFABETIZACAO", "Classe de Alfabetizacao"),
            ("EJA", "Educacao de Jovens e Adultos (EJA)"),
            ("EDUCACAO_ESPECIAL", "Educacao Especial")
        ])
    }

    // MARK: - Efeito de Condicionalidade (Protocolo PBF/SUAS)

    private func seedEfeitoCondicionalidade(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_efeito_condicionalidade", rows: [
            ("ADVERTENCIA", "Advertencia"),
            ("BLOQUEIO", "Bloqueio"),
            ("SUSPENSAO", "Suspensao"),
            ("CANCELAMENTO", "Cancelamento"),
            ("SEM_EFEITO", "Sem efeito (acompanhamento regular)")
        ])
    }

    // MARK: - Tipo de Deficiencia (OMS/IBGE PcD)

    private func seedTipoDeficiencia(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_tipo_deficiencia", rows: [
            ("FISICA", "Deficiencia Fisica"),
            ("AUDITIVA", "Deficiencia Auditiva"),
            ("VISUAL", "Deficiencia Visual"),
            ("INTELECTUAL", "Deficiencia Intelectual"),
            ("MENTAL_PSICOSSOCIAL", "Deficiencia Mental / Psicossocial"),
            ("MULTIPLA", "Deficiencia Multipla"),
            ("TRANSTORNO_ESPECTRO_AUTISTA", "Transtorno do Espectro Autista (TEA)"),
            ("DOENCA_RARA", "Doenca Rara"),
            ("SINDROME_DOWN", "Sindrome de Down"),
            ("PARALISIA_CEREBRAL", "Paralisia Cerebral"),
            ("ALTA_COMPLEXIDADE", "Alta complexidade / Dependencia total")
        ])
    }

    // MARK: - Tipo de Ingresso (Tipificacao Nacional)

    private func seedTipoIngresso(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_tipo_ingresso", rows: [
            ("DEMANDA_ESPONTANEA", "Demanda espontanea"),
            ("BUSCA_ATIVA", "Busca ativa"),
            ("ENCAMINHAMENTO_CRAS", "Encaminhamento do CRAS"),
            ("ENCAMINHAMENTO_CREAS", "Encaminhamento do CREAS"),
            ("ENCAMINHAMENTO_SAUDE", "Encaminhamento da Saude"),
            ("ENCAMINHAMENTO_EDUCACAO", "Encaminhamento da Educacao"),
            ("ENCAMINHAMENTO_JUSTICA", "Encaminhamento da Justica / Conselho Tutelar"),
            ("ENCAMINHAMENTO_OUTROS", "Encaminhamento de outros orgaos"),
            ("RECONDUZIDO", "Reconduzido (retorno ao servico)")
        ])
    }

    // MARK: - Programas Sociais (MDS)

    private func seedProgramaSocial(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_programa_social", rows: [
            ("BOLSA_FAMILIA", "Programa Bolsa Familia"),
            ("BPC", "Beneficio de Prestacao Continuada (BPC)"),
            ("PETI", "Programa de Erradicacao do Trabalho Infantil (PETI)"),
            ("SCFV", "Servico de Convivencia e Fortalecimento de Vinculos (SCFV)"),
            ("PAIF", "Servico de Protecao e Atendimento Integral a Familia (PAIF)"),
            ("PAEFI", "Servico de Protecao e Atendimento Especializado (PAEFI)"),
            ("ACOLHIMENTO_INSTITUCIONAL", "Servico de Acolhimento Institucional"),
            ("ACOLHIMENTO_FAMILIAR", "Servico de Acolhimento em Familia Acolhedora"),
            ("MEDIDA_SOCIOEDUCATIVA", "Programa de Medidas Socioeducativas"),
            ("CRAS_VOLANTE", "Equipe Volante / CRAS itinerante"),
            ("CRIANCA_FELIZ", "Programa Crianca Feliz"),
            ("AUXILIO_BRASIL", "Auxilio Brasil / Programas de Transferencia de Renda"),
            ("PRONATEC_BSM", "PRONATEC / Brasil Sem Miseria"),
            ("ACESSUAS_TRABALHO", "ACESSUAS Trabalho")
        ])
    }
}
