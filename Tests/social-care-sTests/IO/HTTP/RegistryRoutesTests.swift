import Testing
import Hummingbird
import HummingbirdTesting
import Foundation
@testable import social_care_s

@Suite("Registry Routes Specification")
struct RegistryRoutesTests {

    @Test("GET /patients/{id}/family-members deve retornar lista e perfil etário")
    func testGetFamilyMembers() async throws {
        let patientId = UUID()
        let personId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        
        let mockPatient = Patient.reconstitute(
            id: try PatientId(patientId.uuidString), 
            version: 1, 
            personId: personId, 
            diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)],
            familyMembers: [try FamilyMember(personId: personId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: try TimeStamp(Date(timeIntervalSince1970: 0)))]
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
                router: router, 
                db: db, 
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
            try await client.execute(uri: "/patients/\(patientId.uuidString)/family-members", method: .get) { response in
                #expect(response.status == .ok)
                let body = try JSONDecoder().decode(StandardResponse<[String: AnySendable]>.self, from: response.body)
                #expect(body.status == "success")
            }
        }
    }
}
