import Testing
@testable import social_care_s
import Foundation

@Suite("RegisterPatient Application Command Handler Specification")
struct RegisterPatientApplicationTests {

    struct MockPatientRepository: PatientRepository, Sendable {
        func save(_ patient: Patient) async throws {}
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        func find(byPersonId personId: PersonId) async throws -> Patient? { return nil }
        func find(byId id: PatientId) async throws -> Patient? { return nil }
    }

    struct MockEventBus: EventBus, Sendable {
        func publish(_ events: [any DomainEvent]) async throws {}
    }

    struct MockLookupValidator: LookupValidating {
        func exists(id: LookupId, in table: String) async throws -> Bool { true }
    }

    @Test("Deve registrar paciente com sucesso usando Command Handler")
    func successfulRegistration() async throws {
        let repo = MockPatientRepository()
        let bus = MockEventBus()
        let sut = RegisterPatientCommandHandler(repository: repo, eventBus: bus, lookupValidator: MockLookupValidator())
        
        let prId = UUID().uuidString
        let command = RegisterPatientCommand(
            personId: UUID().uuidString,
            initialDiagnoses: [.init(icdCode: "B201", date: Date(), description: "Test")],
            personalData: .init(firstName: "John", lastName: "Doe", motherName: "Jane", nationality: "BR", sex: "masculino", socialName: nil, birthDate: Date(), phone: nil),
            prRelationshipId: prId
        )
        
        let result = try await sut.handle(command)
        #expect(result.isEmpty == false)
    }
}
