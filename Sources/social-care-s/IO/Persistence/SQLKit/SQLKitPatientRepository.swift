import Foundation
import SQLKit

/// Implementação do Repositório de Pacientes utilizando SQLKit comTransactional Outbox.
struct SQLKitPatientRepository: PatientRepository {
    private let db: any SQLDatabase
    
    init(db: any SQLDatabase) {
        self.db = db
    }
    
    func save(_ patient: Patient) async throws {
        try await db.transaction { tx in
            let data = try PatientDatabaseMapper.toDatabase(patient)
            let outboxMessages = try PatientDatabaseMapper.toOutbox(patient.uncommittedEvents)
            
            // 1. Upsert do Agregado Root (Patient)
            try await tx.insert(into: "patients")
                .model(data.patient)
                .onConflict(with: "id") { try $0.set(excludedContentOf: data.patient) }
                .run()
                
            let patientId = data.patient.id
            
            // 2. Sincronização de Listas (Delete-and-Insert Pattern)
            try await tx.delete(from: "patient_diagnoses").where("patient_id", .equal, patientId).run()
            for diagnosis in data.diagnoses {
                try await tx.insert(into: "patient_diagnoses").model(diagnosis).run()
            }
            
            try await tx.delete(from: "family_members").where("patient_id", .equal, patientId).run()
            for member in data.familyMembers {
                try await tx.insert(into: "family_members").model(member).run()
            }
            
            try await tx.delete(from: "social_care_appointments").where("patient_id", .equal, patientId).run()
            for appointment in data.appointments {
                try await tx.insert(into: "social_care_appointments").model(appointment).run()
            }
            
            try await tx.delete(from: "referrals").where("patient_id", .equal, patientId).run()
            for referral in data.referrals {
                try await tx.insert(into: "referrals").model(referral).run()
            }
            
            try await tx.delete(from: "rights_violation_reports").where("patient_id", .equal, patientId).run()
            for report in data.reports {
                try await tx.insert(into: "rights_violation_reports").model(report).run()
            }

            // 3. Persistência dos Eventos no Outbox (Transactional Outbox)
            for message in outboxMessages {
                try await tx.insert(into: "outbox_messages")
                    .model(message)
                    .run()
            }
        }
    }
    
    func find(byPersonId personId: PersonId) async throws -> Patient? {
        let personUUID = UUID(uuidString: personId.description)!
        
        guard let patientModel = try await db.select()
            .from("patients")
            .where("person_id", .equal, personUUID)
            .first(decoding: PatientModel.self) else {
            return nil
        }
        
        let patientId = patientModel.id
        let diagnoses = try await db.select().from("patient_diagnoses").where("patient_id", .equal, patientId).all(decoding: DiagnosisModel.self)
        let family = try await db.select().from("family_members").where("patient_id", .equal, patientId).all(decoding: FamilyMemberModel.self)
        let appointments = try await db.select().from("social_care_appointments").where("patient_id", .equal, patientId).all(decoding: AppointmentModel.self)
        let referrals = try await db.select().from("referrals").where("patient_id", .equal, patientId).all(decoding: ReferralModel.self)
        let reports = try await db.select().from("rights_violation_reports").where("patient_id", .equal, patientId).all(decoding: ViolationReportModel.self)
        
        return try PatientDatabaseMapper.toDomain(
            patient: patientModel,
            diagnoses: diagnoses,
            familyMembers: family,
            appointments: appointments,
            referrals: referrals,
            reports: reports
        )
    }
    
    func find(byId id: PatientId) async throws -> Patient? {
        let uuid = UUID(uuidString: id.description)!
        guard let patientModel = try await db.select()
            .from("patients")
            .where("id", .equal, uuid)
            .first(decoding: PatientModel.self) else {
            return nil
        }
        
        let diagnoses = try await db.select().from("patient_diagnoses").where("patient_id", .equal, uuid).all(decoding: DiagnosisModel.self)
        let family = try await db.select().from("family_members").where("patient_id", .equal, uuid).all(decoding: FamilyMemberModel.self)
        let appointments = try await db.select().from("social_care_appointments").where("patient_id", .equal, uuid).all(decoding: AppointmentModel.self)
        let referrals = try await db.select().from("referrals").where("patient_id", .equal, uuid).all(decoding: ReferralModel.self)
        let reports = try await db.select().from("rights_violation_reports").where("patient_id", .equal, uuid).all(decoding: ViolationReportModel.self)
        
        return try PatientDatabaseMapper.toDomain(
            patient: patientModel,
            diagnoses: diagnoses,
            familyMembers: family,
            appointments: appointments,
            referrals: referrals,
            reports: reports
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
}
