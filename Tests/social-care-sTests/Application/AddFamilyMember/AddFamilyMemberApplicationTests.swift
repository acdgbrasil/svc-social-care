import Testing
@testable import social_care_s
import Foundation

@Suite("AddFamilyMember Application")
struct AddFamilyMemberApplicationTests {

    enum RepoFailure: Error, Sendable {
        case boom
    }

    enum BusFailure: Error, Sendable {
        case down
    }

    actor PatientRepositorySpy: PatientRepository {
        enum FindBehavior: Sendable {
            case success(Patient?)
            case failureGeneric
        }

        enum SaveBehavior: Sendable {
            case success
            case failureGeneric
        }

        struct Snapshot: Sendable {
            let findCalls: Int
            let saveCalls: Int
            let savedPatient: Patient?
        }

        private let findBehavior: FindBehavior
        private let saveBehavior: SaveBehavior
        private var findCalls = 0
        private var saveCalls = 0
        private var savedPatients: [Patient] = []

        init(findBehavior: FindBehavior, saveBehavior: SaveBehavior = .success) {
            self.findBehavior = findBehavior
            self.saveBehavior = saveBehavior
        }

        func save(_ patient: Patient) async throws {
            saveCalls += 1
            if saveBehavior == .failureGeneric {
                throw RepoFailure.boom
            }
            savedPatients.append(patient)
        }

        func exists(byPersonId personId: PersonId) async throws -> Bool {
            _ = personId
            return false
        }

        func find(byPersonId personId: PersonId) async throws -> Patient? {
            _ = personId
            findCalls += 1
            switch findBehavior {
            case .success(let patient):
                return patient
            case .failureGeneric:
                throw RepoFailure.boom
            }
        }

        func find(byId id: UUID) async throws -> Patient? {
            _ = id
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
        enum Behavior: Sendable {
            case success
            case failureGeneric
        }

        struct Snapshot: Sendable {
            let publishCalls: Int
            let lastPublishedCount: Int
        }

        private let behavior: Behavior
        private var publishCalls = 0
        private var lastPublishedCount = 0

        init(behavior: Behavior = .success) {
            self.behavior = behavior
        }

        func publish(_ events: [DomainEvent]) async throws {
            publishCalls += 1
            lastPublishedCount = events.count
            if behavior == .failureGeneric {
                throw BusFailure.down
            }
        }

        func snapshot() -> Snapshot {
            Snapshot(
                publishCalls: publishCalls,
                lastPublishedCount: lastPublishedCount
            )
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
            version: 2,
            personId: personId,
            diagnoses: [diagnosis],
            familyMembers: familyMembers
        )
    }

    @Test("AddFamilyMemberError mapeia códigos e metadados")
    func addFamilyMemberErrorAsAppErrorMapping() {
        #expect(AddFamilyMemberError.useCaseNotImplemented.asAppError.code == "APP-001")
        #expect(AddFamilyMemberError.repositoryNotAvailable.asAppError.code == "APP-002")
        #expect(AddFamilyMemberError.personIdAlreadyExists.asAppError.code == "APP-003")
        #expect(AddFamilyMemberError.invalidDiagnosisListFormat.asAppError.code == "APP-004")
        #expect(AddFamilyMemberError.invalidPersonIdFormat.asAppError.code == "APP-005")
        #expect(AddFamilyMemberError.patientNotFound.asAppError.code == "APP-007")
    }

    @Test("AddFamilyMemberError.persistenceMappingFailure resolve issueCount e contexto")
    func addFamilyMemberPersistenceMappingFailureContext() {
        let unknownCount = AddFamilyMemberError.persistenceMappingFailure()
        #expect(unknownCount.asAppError.code == "APP-006")
        #expect(unknownCount.asAppError.message.contains("(? erro(s))"))
        #expect(unknownCount.asAppError.context.isEmpty)

        let issuesDerived = AddFamilyMemberError.persistenceMappingFailure(
            patientId: "patient-1",
            issues: ["i1", "i2"]
        )
        #expect(issuesDerived.asAppError.message.contains("(2 erro(s))"))
        #expect(issuesDerived.asAppError.context["patientId"]?.value as? String == "patient-1")
        #expect(issuesDerived.asAppError.context["issueCount"]?.value as? Int == 2)
        #expect((issuesDerived.asAppError.context["issues"]?.value as? [String])?.count == 2)

        let explicitCount = AddFamilyMemberError.persistenceMappingFailure(
            patientId: "patient-2",
            issues: ["a", "b"],
            issueCount: 9
        )
        #expect(explicitCount.asAppError.message.contains("(9 erro(s))"))
        #expect(explicitCount.asAppError.context["issueCount"]?.value as? Int == 9)
    }

    @Test("execute falha com patientPersonId inválido")
    func executeFailsWithInvalidPatientPersonId() async {
        let repo = PatientRepositorySpy(findBehavior: .success(nil))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: "invalid",
            memberPersonId: "550e8400-e29b-41d4-a716-446655440001",
            relationship: "Irmão",
            isResiding: true,
            isCaregiver: false
        )

        await #expect(throws: AddFamilyMemberError.invalidPersonIdFormat) {
            try await sut.execute(command: command)
        }
    }

    @Test("execute falha com memberPersonId inválido")
    func executeFailsWithInvalidMemberPersonId() async {
        let repo = PatientRepositorySpy(findBehavior: .success(nil))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: "550e8400-e29b-41d4-a716-446655440000",
            memberPersonId: "invalid-member",
            relationship: "Irmã",
            isResiding: true,
            isCaregiver: false
        )

        await #expect(throws: AddFamilyMemberError.invalidPersonIdFormat) {
            try await sut.execute(command: command)
        }
    }

    @Test("execute falha quando paciente não existe")
    func executeFailsWhenPatientNotFound() async {
        let repo = PatientRepositorySpy(findBehavior: .success(nil))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: "550e8400-e29b-41d4-a716-446655440000",
            memberPersonId: "550e8400-e29b-41d4-a716-446655440001",
            relationship: "Mãe",
            isResiding: true,
            isCaregiver: true
        )

        await #expect(throws: AddFamilyMemberError.patientNotFound) {
            try await sut.execute(command: command)
        }
    }

    @Test("execute falha quando membro já existe")
    func executeFailsWhenPersonIdAlreadyExists() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let memberPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        let existingMember = try FamilyMember(
            personId: memberPersonId,
            relationship: "Pai",
            isPrimaryCaregiver: false,
            residesWithPatient: true
        )
        let patient = try makePatient(personId: patientPersonId, familyMembers: [existingMember])

        let repo = PatientRepositorySpy(findBehavior: .success(patient))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: patientPersonId.description,
            memberPersonId: memberPersonId.description,
            relationship: "Pai",
            isResiding: true,
            isCaregiver: false
        )

        await #expect(throws: AddFamilyMemberError.personIdAlreadyExists) {
            try await sut.execute(command: command)
        }
    }

    @Test("execute mapeia erro de validação de FamilyMember")
    func executeMapsFamilyMemberValidationError() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        let repo = PatientRepositorySpy(findBehavior: .success(patient))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: patientPersonId.description,
            memberPersonId: "550e8400-e29b-41d4-a716-446655440001",
            relationship: "   ",
            isResiding: true,
            isCaregiver: false
        )

        do {
            try await sut.execute(command: command)
            #expect(Bool(false), "Deveria lançar erro")
        } catch let error {
            guard case .persistenceMappingFailure(let patientId, let issues, let issueCount) = error else {
                #expect(Bool(false), "Tipo de erro inesperado: \(error)")
                return
            }
            #expect(patientId == patientPersonId.description)
            #expect(issueCount == 1)
        }
    }

    @Test("execute mapeia falha de save do repositório")
    func executeMapsRepositorySaveFailure() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        let repo = PatientRepositorySpy(findBehavior: .success(patient), saveBehavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: patientPersonId.description,
            memberPersonId: "550e8400-e29b-41d4-a716-446655440001",
            relationship: "Irmã",
            isResiding: true,
            isCaregiver: false
        )

        do {
            try await sut.execute(command: command)
            #expect(Bool(false), "Deveria lançar erro")
        } catch let error {
            guard case .persistenceMappingFailure(let patientId, let issues, let issueCount) = error else {
                #expect(Bool(false), "Tipo de erro inesperado: \(error)")
                return
            }
            #expect(patientId == patientPersonId.description)
            #expect(issueCount == 1)
        }
    }

    @Test("execute persiste e publica no fluxo feliz")
    func executePersistsAndPublishesOnSuccess() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        let repo = PatientRepositorySpy(findBehavior: .success(patient))
        let bus = EventBusSpy()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus)

        let command = AddFamilyMemberCommand(
            patientPersonId: patientPersonId.description,
            memberPersonId: "550e8400-e29b-41d4-a716-446655440001",
            relationship: "Esposa",
            isResiding: true,
            isCaregiver: true
        )

        try await sut.execute(command: command)

        let repoSnapshot = await repo.snapshot()
        #expect(repoSnapshot.findCalls == 1)
        #expect(repoSnapshot.saveCalls == 1)
        #expect(repoSnapshot.savedPatient?.familyMembers.count == 1)
        #expect(repoSnapshot.savedPatient?.familyMembers.first?.relationship == "Esposa")

        let busSnapshot = await bus.snapshot()
        #expect(busSnapshot.publishCalls == 1)
        #expect(busSnapshot.lastPublishedCount > 0)
    }
}
