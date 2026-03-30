import Foundation
import SQLKit

struct SQLKitPatientRepository: PatientRepository {
    private let db: any SQLDatabase

    init(db: any SQLDatabase) {
        self.db = db
    }

    func save(_ patient: Patient) async throws {
        try await db.transaction { tx in
            let data = try PatientDatabaseMapper.toDatabase(patient)
            let outboxMessages = try PatientDatabaseMapper.toOutbox(patient.uncommittedEvents)

            // 1. Upsert do Agregado Root
            try await tx.insert(into: "patients")
                .model(data.patient)
                .onConflict(with: "id") { try $0.set(excludedContentOf: data.patient) }
                .run()

            let patientId = data.patient.id

            // 2. Tabelas filhas existentes (Delete-and-Insert)
            try await deleteAndInsert(tx, table: "patient_diagnoses", patientId: patientId, models: data.diagnoses)
            try await deleteAndInsert(tx, table: "family_members", patientId: patientId, models: data.familyMembers)
            try await deleteAndInsert(tx, table: "social_care_appointments", patientId: patientId, models: data.appointments)
            try await deleteAndInsert(tx, table: "referrals", patientId: patientId, models: data.referrals)
            try await deleteAndInsert(tx, table: "rights_violation_reports", patientId: patientId, models: data.reports)

            // 3. Novas tabelas filhas normalizadas (Delete-and-Insert)
            try await deleteAndInsert(tx, table: "member_incomes", patientId: patientId, models: data.memberIncomes)
            try await deleteAndInsert(tx, table: "social_benefits", patientId: patientId, models: data.socialBenefits)
            try await deleteAndInsert(tx, table: "member_educational_profiles", patientId: patientId, models: data.educationalProfiles)
            try await deleteAndInsert(tx, table: "program_occurrences", patientId: patientId, models: data.programOccurrences)
            try await deleteAndInsert(tx, table: "member_deficiencies", patientId: patientId, models: data.memberDeficiencies)
            try await deleteAndInsert(tx, table: "gestating_members", patientId: patientId, models: data.gestatingMembers)
            try await deleteAndInsert(tx, table: "placement_registries", patientId: patientId, models: data.placementRegistries)
            try await deleteAndInsert(tx, table: "ingress_linked_programs", patientId: patientId, models: data.ingressLinkedPrograms)

            // 4. Outbox
            for message in outboxMessages {
                try await tx.insert(into: "outbox_messages").model(message).run()
            }
        }
    }

    func find(byPersonId personId: PersonId) async throws -> Patient? {
        let personUUID = UUID(uuidString: personId.description)!
        guard let patientModel = try await db.select()
            .column("*")
            .from("patients")
            .where("person_id", .equal, personUUID)
            .first(decoding: PatientModel.self) else { return nil }

        return try await loadAggregate(patientModel)
    }

    func find(byId id: PatientId) async throws -> Patient? {
        let uuid = UUID(uuidString: id.description)!
        guard let patientModel = try await db.select()
            .column("*")
            .from("patients")
            .where("id", .equal, uuid)
            .first(decoding: PatientModel.self) else { return nil }

        return try await loadAggregate(patientModel)
    }

    func list(search: String?, cursor: PatientId?, limit: Int) async throws -> PatientListResult {
        // 1. Total count (com filtro de busca se aplicável)
        var countQuery = db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all), as: "count")
            .from("patients")

        if let search, !search.isEmpty {
            let pattern = "%\(search)%"
            countQuery = countQuery.where { group in
                group.where(SQLFunction("LOWER", args: SQLColumn("first_name")), .like, SQLBind(pattern.lowercased()))
                    .orWhere(SQLFunction("LOWER", args: SQLColumn("last_name")), .like, SQLBind(pattern.lowercased()))
                    .orWhere(SQLColumn("cpf"), .like, SQLBind(pattern))
            }
        }

        let totalCount = try await countQuery
            .first()
            .map { try $0.decode(column: "count", as: Int.self) } ?? 0

        // 2. Query principal: projeção leve sem loadAggregate
        var query = db.select()
            .column(SQLColumn("id", table: "patients"))
            .column(SQLColumn("person_id", table: "patients"))
            .column(SQLColumn("first_name", table: "patients"))
            .column(SQLColumn("last_name", table: "patients"))
            .from("patients")

        if let search, !search.isEmpty {
            let pattern = "%\(search)%"
            query = query.where { group in
                group.where(SQLFunction("LOWER", args: SQLColumn("first_name")), .like, SQLBind(pattern.lowercased()))
                    .orWhere(SQLFunction("LOWER", args: SQLColumn("last_name")), .like, SQLBind(pattern.lowercased()))
                    .orWhere(SQLColumn("cpf"), .like, SQLBind(pattern))
            }
        }

        if let cursor {
            let cursorUUID = UUID(uuidString: cursor.description)!
            query = query.where("id", .greaterThan, cursorUUID)
        }

        let fetchLimit = limit + 1
        query = query.orderBy("id").limit(fetchLimit)

        struct PatientListRow: Codable {
            let id: UUID
            let person_id: UUID
            let first_name: String?
            let last_name: String?
        }

        let rows = try await query.all(decoding: PatientListRow.self)

        // 3. Buscar diagnóstico primário e contagem de membros para os pacientes retornados
        let patientIds = rows.prefix(limit).map { $0.id }

        var diagnosisMap: [UUID: String] = [:]
        var memberCountMap: [UUID: Int] = [:]

        if !patientIds.isEmpty {
            struct DiagRow: Codable {
                let patient_id: UUID
                let description: String
            }

            // Diagnóstico: primeiro por patient_id
            let diagRows = try await db.select()
                .column("patient_id")
                .column("description")
                .from("patient_diagnoses")
                .where("patient_id", .in, patientIds)
                .all(decoding: DiagRow.self)

            for row in diagRows {
                if diagnosisMap[row.patient_id] == nil {
                    diagnosisMap[row.patient_id] = row.description
                }
            }

            // Member count por patient_id
            struct CountRow: Codable {
                let patient_id: UUID
                let cnt: Int
            }

            let countRows = try await db.raw("""
                SELECT patient_id, COUNT(*)::int AS cnt
                FROM family_members
                WHERE patient_id IN (\(unsafeRaw: patientIds.map { "'\($0.uuidString)'" }.joined(separator: ",")))
                GROUP BY patient_id
                """).all(decoding: CountRow.self)

            for row in countRows {
                memberCountMap[row.patient_id] = row.cnt
            }
        }

        // 4. Montar resultado
        let hasMore = rows.count > limit
        let items: [PatientSummary] = try rows.prefix(limit).map { row in
            PatientSummary(
                patientId: try PatientId(row.id.uuidString),
                personId: try PersonId(row.person_id.uuidString),
                firstName: row.first_name,
                lastName: row.last_name,
                primaryDiagnosis: diagnosisMap[row.id],
                memberCount: memberCountMap[row.id] ?? 0
            )
        }

        let nextCursor = hasMore ? items.last?.patientId : nil

        return PatientListResult(
            items: items,
            totalCount: totalCount,
            hasMore: hasMore,
            nextCursor: nextCursor
        )
    }

    func exists(byPersonId personId: PersonId) async throws -> Bool {
        let personUUID = UUID(uuidString: personId.description)!
        let count = try await db.select()
            .column(SQLFunction("COUNT", args: SQLLiteral.all))
            .from("patients")
            .where("person_id", .equal, personUUID)
            .first()
            .map { try $0.decode(column: "count", as: Int.self) } ?? 0
        return count > 0
    }

    // MARK: - Private

    private func deleteAndInsert<T: Codable>(
        _ tx: any SQLDatabase,
        table: String,
        patientId: UUID,
        models: [T]
    ) async throws {
        try await tx.delete(from: table).where("patient_id", .equal, patientId).run()
        for model in models {
            try await tx.insert(into: table).model(model).run()
        }
    }

    private func loadAggregate(_ patientModel: PatientModel) async throws -> Patient {
        let id = patientModel.id

        let diagnoses = try await db.select().column("*").from("patient_diagnoses").where("patient_id", .equal, id).all(decoding: DiagnosisModel.self)
        let family = try await db.select().column("*").from("family_members").where("patient_id", .equal, id).all(decoding: FamilyMemberModel.self)
        let appointments = try await db.select().column("*").from("social_care_appointments").where("patient_id", .equal, id).all(decoding: AppointmentModel.self)
        let referrals = try await db.select().column("*").from("referrals").where("patient_id", .equal, id).all(decoding: ReferralModel.self)
        let reports = try await db.select().column("*").from("rights_violation_reports").where("patient_id", .equal, id).all(decoding: ViolationReportModel.self)

        let memberIncomes = try await db.select().column("*").from("member_incomes").where("patient_id", .equal, id).all(decoding: MemberIncomeModel.self)
        let socialBenefits = try await db.select().column("*").from("social_benefits").where("patient_id", .equal, id).all(decoding: SocialBenefitModel.self)
        let educationalProfiles = try await db.select().column("*").from("member_educational_profiles").where("patient_id", .equal, id).all(decoding: MemberEducationalProfileModel.self)
        let programOccurrences = try await db.select().column("*").from("program_occurrences").where("patient_id", .equal, id).all(decoding: ProgramOccurrenceModel.self)
        let memberDeficiencies = try await db.select().column("*").from("member_deficiencies").where("patient_id", .equal, id).all(decoding: MemberDeficiencyModel.self)
        let gestatingMembers = try await db.select().column("*").from("gestating_members").where("patient_id", .equal, id).all(decoding: GestatingMemberModel.self)
        let placementRegistries = try await db.select().column("*").from("placement_registries").where("patient_id", .equal, id).all(decoding: PlacementRegistryModel.self)
        let ingressLinkedPrograms = try await db.select().column("*").from("ingress_linked_programs").where("patient_id", .equal, id).all(decoding: IngressLinkedProgramModel.self)

        return try PatientDatabaseMapper.toDomain(
            patient: patientModel,
            diagnoses: diagnoses,
            familyMembers: family,
            appointments: appointments,
            referrals: referrals,
            reports: reports,
            memberIncomes: memberIncomes,
            socialBenefits: socialBenefits,
            educationalProfiles: educationalProfiles,
            programOccurrences: programOccurrences,
            memberDeficiencies: memberDeficiencies,
            gestatingMembers: gestatingMembers,
            placementRegistries: placementRegistries,
            ingressLinkedPrograms: ingressLinkedPrograms
        )
    }
}
