import Testing
@testable import social_care_s
import Foundation

@Suite("All Application Use Cases Specification")
struct AllApplicationTests {

    class MockRepo: PatientRepository, @unchecked Sendable {
        var savedPatient: Patient?
        var findResult: Patient?
        func save(_ patient: Patient) async throws { self.savedPatient = patient }
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        func find(byPersonId personId: PersonId) async throws -> Patient? { return findResult }
        func find(byId id: UUID) async throws -> Patient? { return nil }
    }

    struct MockBus: EventBus, Sendable {
        func publish(_ events: [any DomainEvent]) async throws {}
    }

    // MARK: - 1. Housing Condition
    @Test("Deve atualizar habitação")
    func updateHousing() async throws {
        let repo = MockRepo()
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
        
        let sut = UpdateHousingConditionService(repository: repo, eventBus: MockBus())
        let command = UpdateHousingConditionCommand(patientId: pId.description, condition: .init(
            type: "OWNED", 
            wallMaterial: "MASONRY", 
            numberOfRooms: 4, 
            numberOfBedrooms: 2,
            numberOfBathrooms: 2, 
            waterSupply: "PUBLIC_NETWORK", 
            hasPipedWater: true,
            electricityAccess: "METERED_CONNECTION", 
            sewageDisposal: "PUBLIC_SEWER", 
            wasteCollection: "DIRECT_COLLECTION", 
            accessibilityLevel: "FULLY_ACCESSIBLE", 
            isInGeographicRiskArea: false, 
            hasDifficultAccess: false,
            isInSocialConflictArea: false,
            hasDiagnosticObservations: false
        ))
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.housingCondition != nil)
    }

    // MARK: - 2. SocioEconomic
    @Test("Deve atualizar situação socioeconômica")
    func updateSocioEconomic() async throws {
        let repo = MockRepo()
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
        
        let sut = UpdateSocioEconomicSituationService(repository: repo, eventBus: MockBus())
        let command = UpdateSocioEconomicSituationCommand(patientId: pId.description, situation: .init(totalFamilyIncome: 3000, incomePerCapita: 1500, receivesSocialBenefit: false, socialBenefits: [], mainSourceOfIncome: "Job", hasUnemployed: false))
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.socioeconomicSituation != nil)
    }

    // MARK: - 3. Referral
    @Test("Deve criar encaminhamento")
    func createReferral() async throws {
        let repo = MockRepo()
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
        
        let sut = CreateReferralService(repository: repo, eventBus: MockBus())
        let command = CreateReferralCommand(patientId: pId.description, referredPersonId: pId.description, professionalId: UUID().uuidString, destinationService: "CRAS", reason: "Need help", date: Date())
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.referrals.count == 1)
    }

    // MARK: - 4. Violation
    @Test("Deve relatar violação")
    func reportViolation() async throws {
        let repo = MockRepo()
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
        
        let sut = ReportRightsViolationService(repository: repo, eventBus: MockBus())
        let command = ReportRightsViolationCommand(patientId: pId.description, victimId: pId.description, violationType: "NEGLECT", reportDate: Date(), incidentDate: nil, descriptionOfFact: "Fact", actionsTaken: "Actions")
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.violationReports.count == 1)
    }

    // MARK: - 5. Appointment
    @Test("Deve registrar atendimento")
    func registerAppointment() async throws {
        let repo = MockRepo()
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
        
        let sut = RegisterAppointmentService(repository: repo, eventBus: MockBus())
        let command = RegisterAppointmentCommand(patientId: pId.description, professionalId: UUID().uuidString, summary: "Sum", actionPlan: "Plan", type: "HOME_VISIT", date: Date())
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.appointments.count == 1)
    }
}

private func createDiagnosis() throws -> Diagnosis {
    return try Diagnosis(id: try ICDCode("B201"), date: .now, description: "Test", now: .now)
}
