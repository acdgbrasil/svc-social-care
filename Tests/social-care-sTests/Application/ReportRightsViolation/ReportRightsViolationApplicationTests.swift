import Testing
@testable import social_care_s
import Foundation

@Suite("ReportRightsViolation Application")
struct ReportRightsViolationApplicationTests {

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
        func publish(_ events: [DomainEvent]) async throws {
            publishCalls += 1
        }
    }

    private func makePatient(personId: PersonId) throws -> Patient {
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
            familyMembers: []
        )
    }

    @Test("Deve registrar um relato de violação com sucesso")
    func executeSuccess() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = ReportRightsViolationService(repository: repo, eventBus: bus)

        let command = ReportRightsViolationCommand(
            patientId: patientPersonId.description,
            victimId: patientPersonId.description,
            violationType: "NEGLECT",
            reportDate: Date(),
            incidentDate: Date().addingTimeInterval(-3600),
            descriptionOfFact: "Negligência observada"
        )

        let reportId = try await sut.execute(command: command)

        #expect(!reportId.isEmpty)
        
        let snapshot = await repo.snapshot()
        #expect(snapshot.saveCalls == 1)
        #expect(snapshot.savedPatient?.violationReports.count == 1)
        #expect(snapshot.savedPatient?.violationReports.first?.id.description == reportId)
        
        let publishCallsCount = await bus.publishCalls
        #expect(publishCallsCount == 1)
    }

    @Test("Deve retornar erro quando o paciente não existe")
    func executePatientNotFound() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .success(nil))
        let bus = EventBusSpy()
        let sut = ReportRightsViolationService(repository: repo, eventBus: bus)

        let command = ReportRightsViolationCommand(
            patientId: patientPersonId.description,
            victimId: patientPersonId.description,
            violationType: "NEGLECT",
            descriptionOfFact: "Teste"
        )

        await #expect(throws: ReportRightsViolationError.patientNotFound) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve falhar se a vítima estiver fora da fronteira do agregado")
    func executeTargetOutsideBoundary() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let outsidePersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = ReportRightsViolationService(repository: repo, eventBus: bus)

        let command = ReportRightsViolationCommand(
            patientId: patientPersonId.description,
            victimId: outsidePersonId.description,
            violationType: "NEGLECT",
            descriptionOfFact: "Teste"
        )

        await #expect(throws: ReportRightsViolationError.targetOutsideBoundary(outsidePersonId.description)) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve mapear erro genérico do repositório")
    func executeRepositoryFailure() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = ReportRightsViolationService(repository: repo, eventBus: bus)

        let command = ReportRightsViolationCommand(
            patientId: patientPersonId.description,
            victimId: patientPersonId.description,
            violationType: "NEGLECT",
            descriptionOfFact: "Teste"
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
        let sut = ReportRightsViolationService(repository: repo, eventBus: bus)

        let command = ReportRightsViolationCommand(
            patientId: "invalid",
            victimId: "invalid",
            violationType: "NEGLECT",
            descriptionOfFact: "Teste"
        )

        await #expect(throws: ReportRightsViolationError.invalidPersonIdFormat("invalid")) {
            try await sut.execute(command: command)
        }
    }
}
