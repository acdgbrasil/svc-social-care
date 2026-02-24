import Testing
@testable import social_care_s
import Foundation

@Suite("CreateReferral Application")
struct CreateReferralApplicationTests {

    enum RepoFailure: Error, Sendable {
        case boom
    }

    actor PatientRepositorySpy: PatientRepository {
        enum Behavior: Sendable {
            case success(Patient?)
            case failureGeneric
        }

        struct Snapshot: Sendable {
            let findCalls: Int
            let saveCalls: Int
            let savedPatient: Patient?
        }

        private let behavior: Behavior
        private var findCalls = 0
        private var saveCalls = 0
        private var savedPatients: [Patient] = []

        init(behavior: Behavior) {
            self.behavior = behavior
        }

        func save(_ patient: Patient) async throws {
            saveCalls += 1
            if case .failureGeneric = behavior {
                throw RepoFailure.boom
            }
            savedPatients.append(patient)
        }

        func exists(byPersonId personId: PersonId) async throws -> Bool {
            return false
        }

        func find(byPersonId personId: PersonId) async throws -> Patient? {
            findCalls += 1
            switch behavior {
            case .success(let patient):
                return patient
            case .failureGeneric:
                throw RepoFailure.boom
            }
        }

        func find(byId id: UUID) async throws -> Patient? {
            return nil
        }

        func snapshot() -> Snapshot {
            Snapshot(
                findCalls: findCalls,
                saveCalls: saveCalls,
                savedPatient: savedPatients.last
            )
        }
    }

    actor EventBusSpy: EventBus {
        private(set) var publishCalls = 0
        private(set) var lastPublishedEvents: [DomainEvent] = []

        func publish(_ events: [DomainEvent]) async throws {
            publishCalls += 1
            lastPublishedEvents = events
        }
    }

    private func makePatient(personId: PersonId, familyMembers: [FamilyMember] = []) throws -> Patient {
        let diagnosis = try Diagnosis(
            id: try ICDCode("A00"),
            date: .now,
            description: "Initial diagnosis",
            now: .now
        )
        return Patient.reconstitute(
            id: PatientId(),
            version: 1,
            personId: personId,
            diagnoses: [diagnosis],
            familyMembers: familyMembers
        )
    }

    @Test("Deve criar um encaminhamento com sucesso")
    func executeSuccess() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = CreateReferralService(repository: repo, eventBus: bus)

        let command = CreateReferralCommand(
            patientId: patientPersonId.description,
            referredPersonId: patientPersonId.description,
            destinationService: "HEALTH_CARE",
            reason: "Necessita acompanhamento psicológico"
        )

        let referralId = try await sut.execute(command: command)

        #expect(!referralId.isEmpty)
        
        let snapshot = await repo.snapshot()
        #expect(snapshot.saveCalls == 1)
        #expect(snapshot.savedPatient?.referrals.count == 1)
        #expect(snapshot.savedPatient?.referrals.first?.id.description == referralId)
        
        let publishCallsCount = await bus.publishCalls
        #expect(publishCallsCount == 1)
    }

    @Test("Deve retornar erro quando o paciente não existe")
    func executePatientNotFound() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .success(nil))
        let bus = EventBusSpy()
        let sut = CreateReferralService(repository: repo, eventBus: bus)

        let command = CreateReferralCommand(
            patientId: patientPersonId.description,
            referredPersonId: patientPersonId.description,
            destinationService: "OTHER",
            reason: "Motivo"
        )

        await #expect(throws: CreateReferralError.patientNotFound) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve falhar se a pessoa encaminhada estiver fora da fronteira do agregado")
    func executeTargetOutsideBoundary() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let outsidePersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = CreateReferralService(repository: repo, eventBus: bus)

        let command = CreateReferralCommand(
            patientId: patientPersonId.description,
            referredPersonId: outsidePersonId.description,
            destinationService: "OTHER",
            reason: "Motivo"
        )

        await #expect(throws: CreateReferralError.targetOutsideBoundary(outsidePersonId.description)) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve mapear erro genérico do repositório")
    func executeRepositoryFailure() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = CreateReferralService(repository: repo, eventBus: bus)

        let command = CreateReferralCommand(
            patientId: patientPersonId.description,
            referredPersonId: patientPersonId.description,
            destinationService: "OTHER",
            reason: "Motivo"
        )

        do {
            try await sut.execute(command: command)
            #expect(Bool(false), "Deveria lançar erro")
        } catch {
            guard case .persistenceMappingFailure = error else {
                #expect(Bool(false), "Tipo de erro inesperado: \(error)")
                return
            }
        }
    }

    @Test("Deve mapear erro de formato de ID")
    func executeInvalidIdFormat() async throws {
        let repo = PatientRepositorySpy(behavior: .success(nil))
        let bus = EventBusSpy()
        let sut = CreateReferralService(repository: repo, eventBus: bus)

        let command = CreateReferralCommand(
            patientId: "invalid",
            referredPersonId: "invalid",
            destinationService: "OTHER",
            reason: "Motivo"
        )

        await #expect(throws: CreateReferralError.invalidPersonIdFormat("invalid")) {
            try await sut.execute(command: command)
        }
    }
}
