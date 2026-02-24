import Testing
@testable import social_care_s
import Foundation

@Suite("RegisterPatient Application")
struct RegisterPatientApplicationTests {

    enum RepoFailure: Error, Sendable {
        case boom
    }

    actor PatientRepositorySpy: PatientRepository {
        enum Behavior: Sendable {
            case success
            case patientAlreadyExists
            case failureGeneric
        }

        struct Snapshot: Sendable {
            let existsCalls: Int
            let saveCalls: Int
            let savedPatient: Patient?
        }

        private let behavior: Behavior
        private var existsCalls = 0
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
            existsCalls += 1
            switch behavior {
            case .patientAlreadyExists:
                return true
            case .failureGeneric:
                throw RepoFailure.boom
            case .success:
                return false
            }
        }

        func find(byPersonId personId: PersonId) async throws -> Patient? {
            return nil
        }

        func find(byId id: UUID) async throws -> Patient? {
            return nil
        }

        func snapshot() -> Snapshot {
            Snapshot(
                existsCalls: existsCalls,
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

    @Test("Deve registrar um novo paciente com sucesso")
    func executeSuccess() async throws {
        let personId = "550e8400-e29b-41d4-a716-446655440000"
        let repo = PatientRepositorySpy(behavior: .success)
        let bus = EventBusSpy()
        let sut = RegisterPatientService(repository: repo, eventBus: bus)

        let command = RegisterPatientCommand(
            personId: personId,
            initialDiagnoses: [
                .init(icdCode: "A00.1", date: Date(), description: "Diagnóstico Inicial")
            ]
        )

        let patientId = try await sut.execute(command: command)

        #expect(!patientId.isEmpty)
        
        let snapshot = await repo.snapshot()
        #expect(snapshot.existsCalls == 1)
        #expect(snapshot.saveCalls == 1)
        #expect(snapshot.savedPatient?.personId.description == personId.lowercased())
        
        let publishCallsCount = await bus.publishCalls
        #expect(publishCallsCount == 1)
    }

    @Test("Deve falhar se o PersonId já existir")
    func executeAlreadyExists() async throws {
        let personId = "550e8400-e29b-41d4-a716-446655440000"
        let repo = PatientRepositorySpy(behavior: .patientAlreadyExists)
        let bus = EventBusSpy()
        let sut = RegisterPatientService(repository: repo, eventBus: bus)

        let command = RegisterPatientCommand(
            personId: personId,
            initialDiagnoses: [
                .init(icdCode: "A00.1", date: Date(), description: "Diagnóstico Inicial")
            ]
        )

        await #expect(throws: RegisterPatientError.personIdAlreadyExists) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve falhar se o PersonId for inválido")
    func executeInvalidPersonId() async throws {
        let repo = PatientRepositorySpy(behavior: .success)
        let bus = EventBusSpy()
        let sut = RegisterPatientService(repository: repo, eventBus: bus)

        let command = RegisterPatientCommand(
            personId: "invalid-uuid",
            initialDiagnoses: []
        )

        await #expect(throws: RegisterPatientError.invalidPersonIdFormat("invalid-uuid")) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve falhar se os diagnósticos forem inválidos (ex: data futura)")
    func executeInvalidDiagnosis() async throws {
        let personId = "550e8400-e29b-41d4-a716-446655440000"
        let repo = PatientRepositorySpy(behavior: .success)
        let bus = EventBusSpy()
        let sut = RegisterPatientService(repository: repo, eventBus: bus)

        let futureDate = Date().addingTimeInterval(10000)
        let command = RegisterPatientCommand(
            personId: personId,
            initialDiagnoses: [
                .init(icdCode: "A00.1", date: futureDate, description: "Futuro")
            ]
        )

        await #expect(throws: RegisterPatientError.self) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve mapear erro genérico do repositório")
    func executeRepositoryFailure() async throws {
        let personId = "550e8400-e29b-41d4-a716-446655440000"
        
        let repo = PatientRepositorySpy(behavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = RegisterPatientService(repository: repo, eventBus: bus)

        let command = RegisterPatientCommand(
            personId: personId,
            initialDiagnoses: [
                .init(icdCode: "A00.1", date: Date(), description: "Teste")
            ]
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
}
