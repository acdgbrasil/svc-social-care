import Foundation
@testable import social_care_s

actor InMemoryPatientRepository: PatientRepository {
    private var storage: [PatientId: Patient] = [:]
    private(set) var saveCallCount = 0

    func save(_ patient: Patient) async throws {
        storage[patient.id] = patient
        saveCallCount += 1
    }

    func exists(byPersonId personId: PersonId) async throws -> Bool {
        storage.values.contains { $0.personId == personId }
    }

    func find(byPersonId personId: PersonId) async throws -> Patient? {
        storage.values.first { $0.personId == personId }
    }

    func find(byId id: PatientId) async throws -> Patient? {
        storage[id]
    }

    func find(byCpf cpf: CPF) async throws -> Patient? {
        storage.values.first { $0.civilDocuments?.cpf == cpf }
    }

    func exists(byCpf cpf: CPF) async throws -> Bool {
        storage.values.contains { $0.civilDocuments?.cpf == cpf }
    }

    func updatePersonId(patientId: PatientId, newPersonId: PersonId) async throws {
        guard let existing = storage[patientId] else { return }
        let updated = Patient.reconstitute(
            id: existing.id,
            version: existing.version + 1,
            personId: newPersonId,
            personalData: existing.personalData,
            civilDocuments: existing.civilDocuments,
            address: existing.address,
            diagnoses: existing.diagnoses,
            familyMembers: existing.familyMembers,
            appointments: existing.appointments,
            referrals: existing.referrals,
            violationReports: existing.violationReports,
            housingCondition: existing.housingCondition,
            socioeconomicSituation: existing.socioeconomicSituation,
            workAndIncome: existing.workAndIncome,
            educationalStatus: existing.educationalStatus,
            healthStatus: existing.healthStatus,
            communitySupportNetwork: existing.communitySupportNetwork,
            socialHealthSummary: existing.socialHealthSummary,
            socialIdentity: existing.socialIdentity,
            placementHistory: existing.placementHistory,
            intakeInfo: existing.intakeInfo,
            status: existing.status,
            dischargeInfo: existing.dischargeInfo,
            withdrawInfo: existing.withdrawInfo
        )
        storage[patientId] = updated
    }

    func list(search: String?, status: PatientStatus?, cursor: PatientId?, limit: Int) async throws -> PatientListResult {
        var patients = Array(storage.values)

        // Filtro por status
        if let status {
            patients = patients.filter { $0.status == status }
        }

        // Busca por nome
        if let search, !search.isEmpty {
            let q = search.lowercased()
            patients = patients.filter { p in
                let firstName = p.personalData?.firstName.lowercased() ?? ""
                let lastName = p.personalData?.lastName.lowercased() ?? ""
                return firstName.contains(q) || lastName.contains(q)
            }
        }

        // Ordenar por ID para cursor estável
        patients.sort { $0.id.description < $1.id.description }

        // Cursor: pular até depois do cursor
        if let cursor {
            let cursorStr = cursor.description
            patients = patients.filter { $0.id.description > cursorStr }
        }

        let totalCount = (search != nil || status != nil) ? patients.count : storage.count
        let hasMore = patients.count > limit
        let page = Array(patients.prefix(limit))

        let items = page.map { p in
            PatientSummary(
                patientId: p.id,
                personId: p.personId,
                firstName: p.personalData?.firstName,
                lastName: p.personalData?.lastName,
                primaryDiagnosis: p.diagnoses.first?.description,
                memberCount: p.familyMembers.count,
                status: p.status
            )
        }

        let nextCursor = hasMore ? items.last?.patientId : nil
        return PatientListResult(items: items, totalCount: totalCount, hasMore: hasMore, nextCursor: nextCursor)
    }

    // MARK: - Test Helpers

    func seed(_ patient: Patient) {
        storage[patient.id] = patient
    }

    func stored(byId id: PatientId) -> Patient? {
        storage[id]
    }

    var allPatients: [Patient] {
        Array(storage.values)
    }
}
