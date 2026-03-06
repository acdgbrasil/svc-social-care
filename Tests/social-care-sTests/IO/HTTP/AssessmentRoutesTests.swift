import Testing
import Hummingbird
import HummingbirdTesting
import Foundation
@testable import social_care_s

@Suite("Assessment Routes Specification")
struct AssessmentRoutesTests {

    @Test("GET /patients/{id}/housing-condition deve calcular densidade corretamente")
    func testGetHousingDensity() async throws {
        let patientId = UUID()
        let pId = PersonId()
        
        // Setup: 4 membros e 2 dormitórios -> Densidade deve ser 2.0
        let mockPatient = Patient.reconstitute(
            id: try PatientId(patientId.uuidString), 
            version: 1, 
            personId: pId, 
            diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)],
            familyMembers: [
                try FamilyMember(personId: pId, relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now),
                try FamilyMember(personId: PersonId(), relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now),
                try FamilyMember(personId: PersonId(), relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now),
                try FamilyMember(personId: PersonId(), relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now)
            ],
            housingCondition: try HousingCondition(
                type: .owned, 
                wallMaterial: .masonry, 
                numberOfRooms: 4, 
                numberOfBedrooms: 2, 
                numberOfBathrooms: 1, 
                waterSupply: .publicNetwork, 
                hasPipedWater: true, 
                electricityAccess: .meteredConnection, 
                sewageDisposal: .publicSewer, 
                wasteCollection: .directCollection, 
                accessibilityLevel: .fullyAccessible, 
                isInGeographicRiskArea: false, 
                hasDifficultAccess: false, 
                isInSocialConflictArea: false, 
                hasDiagnosticObservations: false
            )
        )
        
        struct MockRepo: PatientRepository {
            let p: Patient
            func find(byId id: UUID) async throws -> Patient? { return p }
            func save(_ patient: Patient) async throws {}
            func exists(byPersonId personId: PersonId) async throws -> Bool { return true }
            func find(byPersonId personId: PersonId) async throws -> Patient? { return p }
        }
        
        let world = TestWorld { router, db in
            RouterBootstrap.configure(
                router: router, db: db, 
                queryOrchestrator: MockIntakeUseCase(), 
                registerPatient: MockRegisterUseCase(), 
                addFamilyMember: MockAddFamilyUseCase(), 
                removeFamilyMember: MockRemoveFamilyUseCase(), 
                updateSocialIdentity: MockUpdateIdentityUseCase(), 
                updateHousing: MockHousingUseCase(), 
                updateSocioEconomic: MockSocioUseCase(), 
                updateEducation: MockEducationUseCase(), 
                updateHealth: MockHealthUseCase(), 
                createReferral: MockReferralUseCase(), 
                reportViolation: MockViolationUseCase(), 
                updatePlacement: MockPlacementUseCase(), 
                registerAppointment: MockAppointmentUseCase(), 
                registerIntake: MockIntakeInfoUseCase(), 
                repository: MockRepo(p: mockPatient)
            )
        }

        try await world.run { client in
            try await client.execute(uri: "/patients/\(patientId.uuidString)/housing-condition", method: .get) { response in
                #expect(response.status == .ok)
                let body = try JSONDecoder().decode(StandardResponse<HousingConditionResponseDTO>.self, from: response.body)
                #expect(body.data.density == 2.0)
            }
        }
    }

    @Test("GET /patients/{id}/socioeconomic-situation deve retornar os 4 indicadores financeiros")
    func testGetSocioEconomicIndicators() async throws {
        let patientId = UUID()
        let pId = PersonId()
        
        // Setup: 2 membros. 
        // Membro 1: 1000.0 renda
        // Benefícios: 200.0 Bolsa Família
        // RTF_S: 1000, RPC_S: 500, RTG: 1200, RPC_G: 600
        let mockPatient = Patient.reconstitute(
            id: try PatientId(patientId.uuidString), 
            version: 1, 
            personId: pId, 
            diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)],
            familyMembers: [
                try FamilyMember(personId: pId, relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now),
                try FamilyMember(personId: PersonId(), relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now)
            ],
            socioeconomicSituation: try SocioEconomicSituation(
                totalFamilyIncome: 1000.0, 
                incomePerCapita: 500.0, 
                receivesSocialBenefit: true, 
                socialBenefits: try SocialBenefitsCollection([
                    try SocialBenefit(benefitName: "Bolsa Familia", amount: 200.0, beneficiaryId: pId)
                ]), 
                mainSourceOfIncome: "Work", 
                hasUnemployed: false
            ),
            workAndIncome: WorkAndIncome(
                familyId: try PatientId(patientId.uuidString), 
                individualIncomes: [
                    WorkIncomeVO(memberId: pId, occupationId: try LookupId(UUID().uuidString), hasWorkCard: true, monthlyAmount: 1000.0)
                ], 
                socialBenefits: [], 
                hasRetiredMembers: false
            )
        )
        
        struct MockRepo: PatientRepository {
            let p: Patient
            func find(byId id: UUID) async throws -> Patient? { return p }
            func save(_ patient: Patient) async throws {}
            func exists(byPersonId personId: PersonId) async throws -> Bool { return true }
            func find(byPersonId personId: PersonId) async throws -> Patient? { return p }
        }

        let world = TestWorld { router, db in
            RouterBootstrap.configure(
                router: router, db: db, 
                queryOrchestrator: MockIntakeUseCase(), 
                registerPatient: MockRegisterUseCase(), 
                addFamilyMember: MockAddFamilyUseCase(), 
                removeFamilyMember: MockRemoveFamilyUseCase(), 
                updateSocialIdentity: MockUpdateIdentityUseCase(), 
                updateHousing: MockHousingUseCase(), 
                updateSocioEconomic: MockSocioUseCase(), 
                updateEducation: MockEducationUseCase(), 
                updateHealth: MockHealthUseCase(), 
                createReferral: MockReferralUseCase(), 
                reportViolation: MockViolationUseCase(), 
                updatePlacement: MockPlacementUseCase(), 
                registerAppointment: MockAppointmentUseCase(), 
                registerIntake: MockIntakeInfoUseCase(), 
                repository: MockRepo(p: mockPatient)
            )
        }

        try await world.run { client in
            try await client.execute(uri: "/patients/\(patientId.uuidString)/socioeconomic-situation", method: .get) { response in
                #expect(response.status == .ok)
                let body = try JSONDecoder().decode(StandardResponse<SocioEconomicSituationResponseDTO>.self, from: response.body)
                #expect(body.data.totalWorkIncome == 1000.0)
                #expect(body.data.perCapitaWorkIncome == 500.0)
                #expect(body.data.totalGlobalIncome == 1200.0)
                #expect(body.data.perCapitaGlobalIncome == 600.0)
            }
        }
    }
}
