import Testing
@testable import social_care_s
import Foundation

@Suite("AssignPrimaryCaregiver Application")
struct AssignPrimaryCaregiverApplicationTests {

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

    @Test("Deve trocar o cuidador principal com sucesso")
    func executeSuccess() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let member1PersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        let member2PersonId = try PersonId("550e8400-e29b-41d4-a716-446655440002")

        let m1 = try FamilyMember(personId: member1PersonId, relationship: "SPOUSE", isPrimaryCaregiver: true, residesWithPatient: true)
        let m2 = try FamilyMember(personId: member2PersonId, relationship: "SON", isPrimaryCaregiver: false, residesWithPatient: true)

        let patient = try makePatient(personId: patientPersonId, familyMembers: [m1, m2])
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = AssignPrimaryCaregiverService(repository: repo, eventBus: bus)

        let command = AssignPrimaryCaregiverCommand(
            patientId: patientPersonId.description,
            memberPersonId: member2PersonId.description
        )

        try await sut.execute(command: command)

        let snapshot = await repo.snapshot()
        #expect(snapshot.saveCalls == 1)
        
        let savedPatient = snapshot.savedPatient!
        let savedM1 = savedPatient.familyMembers.first { $0.personId == member1PersonId }!
        let savedM2 = savedPatient.familyMembers.first { $0.personId == member2PersonId }!
        
        #expect(savedM1.isPrimaryCaregiver == false)
        #expect(savedM2.isPrimaryCaregiver == true)
        
        let publishCallsCount = await bus.publishCalls
        #expect(publishCallsCount == 1)
    }

    @Test("Deve retornar erro quando o membro não existe na família")
    func executeMemberNotFound() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let member1PersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        
        let patient = try makePatient(personId: patientPersonId, familyMembers: [])
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = AssignPrimaryCaregiverService(repository: repo, eventBus: bus)

        let command = AssignPrimaryCaregiverCommand(
            patientId: patientPersonId.description,
            memberPersonId: member1PersonId.description
        )

        await #expect(throws: AssignPrimaryCaregiverError.familyMemberNotFound(personId: member1PersonId.description)) {
            try await sut.execute(command: command)
        }
        
        let snapshot = await repo.snapshot()
        #expect(snapshot.saveCalls == 0)
    }

    @Test("Deve retornar erro quando o paciente não existe")
    func executePatientNotFound() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let member1PersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        
        let repo = PatientRepositorySpy(behavior: .success(nil))
        let bus = EventBusSpy()
        let sut = AssignPrimaryCaregiverService(repository: repo, eventBus: bus)

        let command = AssignPrimaryCaregiverCommand(
            patientId: patientPersonId.description,
            memberPersonId: member1PersonId.description
        )

        await #expect(throws: AssignPrimaryCaregiverError.patientNotFound) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve mapear erro genérico do repositório")
    func executeRepositoryFailure() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let member1PersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        
        let repo = PatientRepositorySpy(behavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = AssignPrimaryCaregiverService(repository: repo, eventBus: bus)

        let command = AssignPrimaryCaregiverCommand(
            patientId: patientPersonId.description,
            memberPersonId: member1PersonId.description
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
        let sut = AssignPrimaryCaregiverService(repository: repo, eventBus: bus)

        let command = AssignPrimaryCaregiverCommand(
            patientId: "invalid",
            memberPersonId: "invalid"
        )

        await #expect(throws: AssignPrimaryCaregiverError.invalidPersonIdFormat("invalid")) {
            try await sut.execute(command: command)
        }
    }
}
