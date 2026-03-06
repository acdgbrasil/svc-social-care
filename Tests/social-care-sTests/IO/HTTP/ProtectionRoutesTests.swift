import Testing
import Hummingbird
import HummingbirdTesting
import Foundation
@testable import social_care_s

@Suite("Protection Routes Specification")
struct ProtectionRoutesTests {

    @Test("POST /patients/{id}/referrals deve criar encaminhamento")
    func testCreateReferral() async throws {
        let patientId = UUID().uuidString
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
                createReferral: MockReferralUseCase(resultId: "REF-123"), 
                reportViolation: MockViolationUseCase(), 
                updatePlacement: MockPlacementUseCase(), 
                registerAppointment: MockAppointmentUseCase(), 
                registerIntake: MockIntakeInfoUseCase(), 
                repository: MockRepoEmpty()
            )
        }

        let dto = CreateReferralDTO(
            referredPersonId: UUID().uuidString, 
            professionalId: UUID().uuidString, 
            destinationService: "CRAS", 
            reason: "Needs food assistance", 
            date: Date()
        )
        let body = try JSONEncoder().encode(dto)

        try await world.run { client in
            try await client.execute(uri: "/patients/\(patientId)/referrals", method: .post, body: ByteBuffer(data: body)) { response in
                #expect(response.status == .created)
                let res = try JSONDecoder().decode(StandardResponse<ActionConfirmationDTO>.self, from: response.body)
                #expect(res.data.id == "REF-123")
            }
        }
    }
}
