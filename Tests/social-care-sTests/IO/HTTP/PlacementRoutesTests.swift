import Testing
import Hummingbird
import HummingbirdTesting
import Foundation
@testable import social_care_s

@Suite("Placement Routes Specification")
struct PlacementRoutesTests {

    @Test("GET /patients/{id}/placement-history deve retornar dados de acolhimento")
    func testGetPlacement() async throws {
        let patientId = UUID()
        let pId = PersonId()
        
        let mockPatient = Patient.reconstitute(
            id: try PatientId(patientId.uuidString), 
            version: 1, 
            personId: pId, 
            diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)],
            placementHistory: PlacementHistory(
                familyId: try PatientId(patientId.uuidString), 
                individualPlacements: [], 
                collectiveSituations: .init(homeLossReport: "Flood", thirdPartyGuardReport: nil), 
                separationChecklist: .init(adultInPrison: false, adolescentInInternment: false)
            )
        )
        
        struct MockRepo: PatientRepository {
            let p: Patient
            func find(byId id: UUID) async throws -> Patient? { return p }
            func save(_ patient: Patient) async throws {}
            func exists(byPersonId personId: PersonId) async throws -> Bool { return true }
            func find(byPersonId personId: PersonId) async throws -> Patient? { return p }
        }
        
        let repo = MockRepo(p: mockPatient)

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
                repository: repo
            )
        }

        try await world.run { client in
            try await client.execute(uri: "/patients/\(patientId.uuidString)/placement-history", method: .get) { response in
                #expect(response.status == .ok)
                let body = try JSONDecoder().decode(StandardResponse<PlacementHistoryResponseDTO>.self, from: response.body)
                #expect(body.data.collectiveSituations.homeLossReport == "Flood")
            }
        }
    }
}
