import Foundation
import SQLKit

struct NormalizeSchema: Migration {
    let name = "2026_03_08_NormalizeSchema"

    func prepare(on db: any SQLDatabase) async throws {
        let uuidType = SQLRaw("UUID")
        let booleanType = SQLRaw("BOOLEAN")
        let timestampType = SQLRaw("TIMESTAMP")
        let numericType = SQLRaw("NUMERIC(12,2)")
        let jsonbType = SQLRaw("JSONB")

        // ──────────────────────────────────────────────
        // PARTE 1: Novas Lookup Tables
        // ──────────────────────────────────────────────

        try await db.create(table: "dominio_tipo_beneficio")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("codigo", type: .text, .notNull, .unique)
            .column("descricao", type: .text, .notNull)
            .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
            .column("exige_registro_nascimento", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(false)))
            .column("exige_cpf_falecido", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(false)))
            .run()

        try await db.create(table: "dominio_tipo_violacao")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("codigo", type: .text, .notNull, .unique)
            .column("descricao", type: .text, .notNull)
            .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
            .column("exige_descricao", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(false)))
            .run()

        try await db.create(table: "dominio_servico_vinculo")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("codigo", type: .text, .notNull, .unique)
            .column("descricao", type: .text, .notNull)
            .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
            .run()

        try await db.create(table: "dominio_tipo_medida")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("codigo", type: .text, .notNull, .unique)
            .column("descricao", type: .text, .notNull)
            .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
            .run()

        try await db.create(table: "dominio_unidade_realizacao")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("codigo", type: .text, .notNull, .unique)
            .column("descricao", type: .text, .notNull)
            .column("ativo", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(true)))
            .run()

        // Seed data das novas lookup tables
        try await seedTipoBeneficio(on: db)
        try await seedTipoViolacao(on: db)
        try await seedServicoVinculo(on: db)
        try await seedTipoMedida(on: db)
        try await seedUnidadeRealizacao(on: db)

        // ──────────────────────────────────────────────
        // PARTE 2: Colunas escalares na tabela patients
        // ──────────────────────────────────────────────

        // personal_data
        try await db.alter(table: "patients").column("first_name", type: .text).run()
        try await db.alter(table: "patients").column("last_name", type: .text).run()
        try await db.alter(table: "patients").column("mother_name", type: .text).run()
        try await db.alter(table: "patients").column("nationality", type: .text).run()
        try await db.alter(table: "patients").column("sex", type: .text).run()
        try await db.alter(table: "patients").column("social_name", type: .text).run()
        try await db.alter(table: "patients").column("birth_date", type: .custom(timestampType)).run()
        try await db.alter(table: "patients").column("phone", type: .text).run()

        // civil_documents
        try await db.alter(table: "patients").column("cpf", type: .text).run()
        try await db.alter(table: "patients").column("nis", type: .text).run()
        try await db.alter(table: "patients").column("rg_number", type: .text).run()
        try await db.alter(table: "patients").column("rg_issuing_state", type: .text).run()
        try await db.alter(table: "patients").column("rg_issuing_agency", type: .text).run()
        try await db.alter(table: "patients").column("rg_issue_date", type: .custom(timestampType)).run()

        // address
        try await db.alter(table: "patients").column("address_cep", type: .text).run()
        try await db.alter(table: "patients").column("address_is_shelter", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("address_location", type: .text).run()
        try await db.alter(table: "patients").column("address_street", type: .text).run()
        try await db.alter(table: "patients").column("address_neighborhood", type: .text).run()
        try await db.alter(table: "patients").column("address_number", type: .text).run()
        try await db.alter(table: "patients").column("address_complement", type: .text).run()
        try await db.alter(table: "patients").column("address_state", type: .text).run()
        try await db.alter(table: "patients").column("address_city", type: .text).run()

        // housing_condition
        try await db.alter(table: "patients").column("hc_type", type: .text).run()
        try await db.alter(table: "patients").column("hc_wall_material", type: .text).run()
        try await db.alter(table: "patients").column("hc_number_of_rooms", type: .int).run()
        try await db.alter(table: "patients").column("hc_number_of_bedrooms", type: .int).run()
        try await db.alter(table: "patients").column("hc_number_of_bathrooms", type: .int).run()
        try await db.alter(table: "patients").column("hc_water_supply", type: .text).run()
        try await db.alter(table: "patients").column("hc_has_piped_water", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("hc_electricity_access", type: .text).run()
        try await db.alter(table: "patients").column("hc_sewage_disposal", type: .text).run()
        try await db.alter(table: "patients").column("hc_waste_collection", type: .text).run()
        try await db.alter(table: "patients").column("hc_accessibility_level", type: .text).run()
        try await db.alter(table: "patients").column("hc_is_in_geographic_risk_area", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("hc_has_difficult_access", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("hc_is_in_social_conflict_area", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("hc_has_diagnostic_observations", type: .custom(booleanType)).run()

        // social_identity
        try await db.alter(table: "patients").column("social_identity_type_id", type: .custom(uuidType)).run()
        try await db.alter(table: "patients").column("social_identity_other_desc", type: .text).run()

        // community_support_network
        try await db.alter(table: "patients").column("csn_has_relative_support", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("csn_has_neighbor_support", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("csn_family_conflicts", type: .text).run()
        try await db.alter(table: "patients").column("csn_patient_participates_in_groups", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("csn_family_participates_in_groups", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("csn_patient_has_access_to_leisure", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("csn_faces_discrimination", type: .custom(booleanType)).run()

        // social_health_summary
        try await db.alter(table: "patients").column("shs_requires_constant_care", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("shs_has_mobility_impairment", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("shs_functional_dependencies", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("shs_has_relevant_drug_therapy", type: .custom(booleanType)).run()

        // socioeconomic_situation (escalares)
        try await db.alter(table: "patients").column("ses_total_family_income", type: .custom(numericType)).run()
        try await db.alter(table: "patients").column("ses_income_per_capita", type: .custom(numericType)).run()
        try await db.alter(table: "patients").column("ses_receives_social_benefit", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("ses_main_source_of_income", type: .text).run()
        try await db.alter(table: "patients").column("ses_has_unemployed", type: .custom(booleanType)).run()

        // work_and_income (escalar)
        try await db.alter(table: "patients").column("wi_has_retired_members", type: .custom(booleanType)).run()

        // health_status (escalares)
        try await db.alter(table: "patients").column("hs_food_insecurity", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("hs_constant_care_member_ids", type: .custom(jsonbType)).run()

        // placement_history (escalares)
        try await db.alter(table: "patients").column("ph_home_loss_report", type: .text).run()
        try await db.alter(table: "patients").column("ph_third_party_guard_report", type: .text).run()
        try await db.alter(table: "patients").column("ph_adult_in_prison", type: .custom(booleanType)).run()
        try await db.alter(table: "patients").column("ph_adolescent_in_internment", type: .custom(booleanType)).run()

        // ingress_info (escalares)
        try await db.alter(table: "patients").column("ii_ingress_type_id", type: .custom(uuidType)).run()
        try await db.alter(table: "patients").column("ii_origin_name", type: .text).run()
        try await db.alter(table: "patients").column("ii_origin_contact", type: .text).run()
        try await db.alter(table: "patients").column("ii_service_reason", type: .text).run()

        // ──────────────────────────────────────────────
        // PARTE 3: Novas tabelas filhas (arrays normalizados)
        // ──────────────────────────────────────────────

        try await db.create(table: "member_incomes")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("occupation_id", type: .custom(uuidType))
            .column("has_work_card", type: .custom(booleanType), .notNull)
            .column("monthly_amount", type: .custom(numericType), .notNull)
            .run()

        try await db.create(table: "social_benefits")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("source", type: .text, .notNull)
            .column("benefit_name", type: .text, .notNull)
            .column("amount", type: .custom(numericType), .notNull)
            .column("beneficiary_id", type: .custom(uuidType), .notNull)
            .run()

        try await db.create(table: "member_educational_profiles")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("can_read_write", type: .custom(booleanType), .notNull)
            .column("attends_school", type: .custom(booleanType), .notNull)
            .column("education_level_id", type: .custom(uuidType))
            .run()

        try await db.create(table: "program_occurrences")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("date", type: .custom(timestampType), .notNull)
            .column("effect_id", type: .custom(uuidType))
            .column("is_suspension_requested", type: .custom(booleanType), .notNull)
            .run()

        try await db.create(table: "member_deficiencies")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("deficiency_type_id", type: .custom(uuidType))
            .column("needs_constant_care", type: .custom(booleanType), .notNull)
            .column("responsible_caregiver_name", type: .text)
            .run()

        try await db.create(table: "gestating_members")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("months_gestation", type: .int, .notNull)
            .column("started_prenatal_care", type: .custom(booleanType), .notNull)
            .run()

        try await db.create(table: "placement_registries")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("member_id", type: .custom(uuidType), .notNull)
            .column("start_date", type: .custom(timestampType), .notNull)
            .column("end_date", type: .custom(timestampType))
            .column("reason", type: .text, .notNull)
            .run()

        try await db.create(table: "ingress_linked_programs")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("program_id", type: .custom(uuidType))
            .column("observation", type: .text)
            .run()

        // ──────────────────────────────────────────────
        // PARTE 4: Drop das colunas JSONB antigas
        // ──────────────────────────────────────────────

        try await db.alter(table: "patients").dropColumn("personal_data").run()
        try await db.alter(table: "patients").dropColumn("civil_documents").run()
        try await db.alter(table: "patients").dropColumn("address").run()
        try await db.alter(table: "patients").dropColumn("housing_condition").run()
        try await db.alter(table: "patients").dropColumn("socioeconomic_situation").run()
        try await db.alter(table: "patients").dropColumn("community_support_network").run()
        try await db.alter(table: "patients").dropColumn("social_health_summary").run()
        try await db.alter(table: "patients").dropColumn("social_identity").run()
        try await db.alter(table: "patients").dropColumn("work_and_income").run()
        try await db.alter(table: "patients").dropColumn("educational_status").run()
        try await db.alter(table: "patients").dropColumn("health_status").run()
        try await db.alter(table: "patients").dropColumn("acolhimento_history").run()
        try await db.alter(table: "patients").dropColumn("ingress_info").run()

        // ──────────────────────────────────────────────
        // PARTE 5: Indexes para novas tabelas filhas
        // ──────────────────────────────────────────────

        try await db.create(index: "idx_member_incomes_patient")
            .on("member_incomes").column("patient_id").run()
        try await db.create(index: "idx_social_benefits_patient")
            .on("social_benefits").column("patient_id").run()
        try await db.create(index: "idx_member_educational_profiles_patient")
            .on("member_educational_profiles").column("patient_id").run()
        try await db.create(index: "idx_program_occurrences_patient")
            .on("program_occurrences").column("patient_id").run()
        try await db.create(index: "idx_member_deficiencies_patient")
            .on("member_deficiencies").column("patient_id").run()
        try await db.create(index: "idx_gestating_members_patient")
            .on("gestating_members").column("patient_id").run()
        try await db.create(index: "idx_placement_registries_patient")
            .on("placement_registries").column("patient_id").run()
        try await db.create(index: "idx_ingress_linked_programs_patient")
            .on("ingress_linked_programs").column("patient_id").run()
    }

    func revert(on db: any SQLDatabase) async throws {
        // Drop indexes
        let indexes = [
            "idx_ingress_linked_programs_patient",
            "idx_placement_registries_patient",
            "idx_gestating_members_patient",
            "idx_member_deficiencies_patient",
            "idx_program_occurrences_patient",
            "idx_member_educational_profiles_patient",
            "idx_social_benefits_patient",
            "idx_member_incomes_patient"
        ]
        for idx in indexes { try await db.drop(index: idx).run() }

        // Drop child tables
        let childTables = [
            "ingress_linked_programs", "placement_registries", "gestating_members",
            "member_deficiencies", "program_occurrences", "member_educational_profiles",
            "social_benefits", "member_incomes"
        ]
        for table in childTables { try await db.drop(table: table).run() }

        // Drop lookup tables
        let lookups = [
            "dominio_unidade_realizacao", "dominio_tipo_medida",
            "dominio_servico_vinculo", "dominio_tipo_violacao", "dominio_tipo_beneficio"
        ]
        for table in lookups { try await db.drop(table: table).run() }

        // Restore JSONB columns (simplified — no data migration)
        let jsonbType = SQLRaw("JSONB")
        try await db.alter(table: "patients").column("personal_data", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("civil_documents", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("address", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("housing_condition", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("socioeconomic_situation", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("community_support_network", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("social_health_summary", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("social_identity", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("work_and_income", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("educational_status", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("health_status", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("acolhimento_history", type: .custom(jsonbType)).run()
        try await db.alter(table: "patients").column("ingress_info", type: .custom(jsonbType)).run()

        // Drop scalar columns added in this migration
        let scalarColumns = [
            "first_name", "last_name", "mother_name", "nationality", "sex", "social_name", "birth_date", "phone",
            "cpf", "nis", "rg_number", "rg_issuing_state", "rg_issuing_agency", "rg_issue_date",
            "address_cep", "address_is_shelter", "address_location", "address_street", "address_neighborhood",
            "address_number", "address_complement", "address_state", "address_city",
            "hc_type", "hc_wall_material", "hc_number_of_rooms", "hc_number_of_bedrooms", "hc_number_of_bathrooms",
            "hc_water_supply", "hc_has_piped_water", "hc_electricity_access", "hc_sewage_disposal",
            "hc_waste_collection", "hc_accessibility_level", "hc_is_in_geographic_risk_area",
            "hc_has_difficult_access", "hc_is_in_social_conflict_area", "hc_has_diagnostic_observations",
            "social_identity_type_id", "social_identity_other_desc",
            "csn_has_relative_support", "csn_has_neighbor_support", "csn_family_conflicts",
            "csn_patient_participates_in_groups", "csn_family_participates_in_groups",
            "csn_patient_has_access_to_leisure", "csn_faces_discrimination",
            "shs_requires_constant_care", "shs_has_mobility_impairment",
            "shs_functional_dependencies", "shs_has_relevant_drug_therapy",
            "ses_total_family_income", "ses_income_per_capita", "ses_receives_social_benefit",
            "ses_main_source_of_income", "ses_has_unemployed",
            "wi_has_retired_members",
            "hs_food_insecurity", "hs_constant_care_member_ids",
            "ph_home_loss_report", "ph_third_party_guard_report",
            "ph_adult_in_prison", "ph_adolescent_in_internment",
            "ii_ingress_type_id", "ii_origin_name", "ii_origin_contact", "ii_service_reason"
        ]
        for col in scalarColumns {
            try await db.alter(table: "patients").dropColumn(col).run()
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

    // MARK: - Tipo de Beneficio (MDS / Tipificacao Nacional SUAS)

    private func seedTipoBeneficio(on db: any SQLDatabase) async throws {
        let rows: [(codigo: String, descricao: String, nascimento: Bool, falecido: Bool)] = [
            ("BPC_IDOSO", "Beneficio de Prestacao Continuada - Idoso", false, false),
            ("BPC_DEFICIENCIA", "Beneficio de Prestacao Continuada - Pessoa com Deficiencia", false, false),
            ("BOLSA_FAMILIA", "Programa Bolsa Familia", false, false),
            ("AUXILIO_NATALIDADE", "Auxilio Natalidade", true, false),
            ("AUXILIO_FUNERAL", "Auxilio Funeral", false, true),
            ("AUXILIO_VULNERABILIDADE", "Auxilio por Situacao de Vulnerabilidade Temporaria", false, false),
            ("ALUGUEL_SOCIAL", "Aluguel Social", false, false),
            ("CESTA_BASICA", "Cesta Basica / Auxilio Alimentacao", false, false),
            ("BENEFICIO_EVENTUAL", "Beneficio Eventual (outros)", false, false),
            ("TRANSFERENCIA_RENDA_MUNICIPAL", "Programa de Transferencia de Renda Municipal", false, false),
            ("TRANSFERENCIA_RENDA_ESTADUAL", "Programa de Transferencia de Renda Estadual", false, false)
        ]
        for row in rows {
            try await db.insert(into: "dominio_tipo_beneficio")
                .columns("id", "codigo", "descricao", "exige_registro_nascimento", "exige_cpf_falecido")
                .values(
                    SQLFunction("gen_random_uuid"),
                    SQLBind(row.codigo),
                    SQLBind(row.descricao),
                    SQLBind(row.nascimento),
                    SQLBind(row.falecido)
                )
                .run()
        }
    }

    // MARK: - Tipo de Violacao (ECA / SUAS / Disque 100)

    private func seedTipoViolacao(on db: any SQLDatabase) async throws {
        let rows: [(codigo: String, descricao: String, exigeDescricao: Bool)] = [
            ("VIOLENCIA_FISICA", "Violencia Fisica", false),
            ("VIOLENCIA_PSICOLOGICA", "Violencia Psicologica", false),
            ("VIOLENCIA_SEXUAL", "Violencia Sexual", false),
            ("NEGLIGENCIA_ABANDONO", "Negligencia / Abandono", false),
            ("TRABALHO_INFANTIL", "Exploracao de Trabalho Infantil", false),
            ("TRAFICO_PESSOAS", "Trafico de Pessoas", false),
            ("VIOLENCIA_PATRIMONIAL", "Violencia Patrimonial", false),
            ("DISCRIMINACAO", "Discriminacao (racial, genero, orientacao sexual, deficiencia)", false),
            ("VIOLENCIA_INSTITUCIONAL", "Violencia Institucional", false),
            ("TORTURA", "Tortura", false),
            ("OUTRA", "Outra violacao de direitos", true)
        ]
        for row in rows {
            try await db.insert(into: "dominio_tipo_violacao")
                .columns("id", "codigo", "descricao", "exige_descricao")
                .values(
                    SQLFunction("gen_random_uuid"),
                    SQLBind(row.codigo),
                    SQLBind(row.descricao),
                    SQLBind(row.exigeDescricao)
                )
                .run()
        }
    }

    // MARK: - Servico de Vinculo (Rede SUAS / Rede Intersetorial)

    private func seedServicoVinculo(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_servico_vinculo", rows: [
            ("CRAS", "Centro de Referencia de Assistencia Social (CRAS)"),
            ("CREAS", "Centro de Referencia Especializado de Assistencia Social (CREAS)"),
            ("CENTRO_POP", "Centro de Referencia para Populacao em Situacao de Rua (Centro POP)"),
            ("ACOLHIMENTO_INSTITUCIONAL", "Unidade de Acolhimento Institucional"),
            ("ACOLHIMENTO_FAMILIAR", "Servico de Acolhimento em Familia Acolhedora"),
            ("UBS", "Unidade Basica de Saude (UBS)"),
            ("CAPS", "Centro de Atencao Psicossocial (CAPS)"),
            ("HOSPITAL", "Hospital / Unidade de Emergencia"),
            ("ESCOLA", "Escola / Instituicao de Ensino"),
            ("CONSELHO_TUTELAR", "Conselho Tutelar"),
            ("DEFENSORIA_PUBLICA", "Defensoria Publica"),
            ("MINISTERIO_PUBLICO", "Ministerio Publico"),
            ("VARA_INFANCIA", "Vara da Infancia e Juventude"),
            ("DELEGACIA", "Delegacia de Policia / Delegacia Especializada"),
            ("OUTROS", "Outros servicos da rede")
        ])
    }

    // MARK: - Tipo de Medida (ECA / SINASE / SUAS)

    private func seedTipoMedida(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_tipo_medida", rows: [
            ("ADVERTENCIA", "Advertencia"),
            ("REPARACAO_DANO", "Obrigacao de Reparar o Dano"),
            ("PRESTACAO_SERVICO", "Prestacao de Servicos a Comunidade (PSC)"),
            ("LIBERDADE_ASSISTIDA", "Liberdade Assistida (LA)"),
            ("SEMILIBERDADE", "Regime de Semiliberdade"),
            ("INTERNACAO", "Internacao em Estabelecimento Educacional"),
            ("MEDIDA_PROTETIVA", "Medida Protetiva (Art. 101 ECA)"),
            ("ACOMPANHAMENTO_FAMILIAR", "Acompanhamento Familiar Sistematico"),
            ("INCLUSAO_PROGRAMA", "Inclusao em Programa Comunitario ou Oficial de Auxilio")
        ])
    }

    // MARK: - Unidade de Realizacao (Tipificacao Nacional)

    private func seedUnidadeRealizacao(on db: any SQLDatabase) async throws {
        try await insert(on: db, table: "dominio_unidade_realizacao", rows: [
            ("DOMICILIAR", "Domiciliar (Visita domiciliar)"),
            ("INSTITUCIONAL", "Institucional (Na unidade CRAS/CREAS)"),
            ("COMUNITARIA", "Comunitaria (Espaco comunitario / territorio)"),
            ("ITINERANTE", "Itinerante (Equipe volante / busca ativa)"),
            ("REMOTA", "Remota (Telefone / videoconferencia)")
        ])
    }
}
