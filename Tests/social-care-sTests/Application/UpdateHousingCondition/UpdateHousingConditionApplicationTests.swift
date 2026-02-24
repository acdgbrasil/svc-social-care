import Testing
@testable import social_care_s
import Foundation

@Suite("UpdateHousingCondition Application")
struct UpdateHousingConditionApplicationTests {

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
            diagnoses: [diagnosis]
        )
    }

    private func makeValidDraft() -> UpdateHousingConditionCommand.ConditionDraft {
        return .init(
            type: "OWNED",
            wallMaterial: "MASONRY",
            numberOfRooms: 4,
            numberOfBathrooms: 2,
            waterSupply: "PUBLIC_NETWORK",
            electricityAccess: "METERED_CONNECTION",
            sewageDisposal: "PUBLIC_SEWER",
            wasteCollection: "DIRECT_COLLECTION",
            accessibilityLevel: "FULLY_ACCESSIBLE",
            isInGeographicRiskArea: false,
            isInSocialConflictArea: false
        )
    }

    @Test("Deve atualizar condições de moradia com sucesso")
    func executeSuccess() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = UpdateHousingConditionService(repository: repo, eventBus: bus)

        let command = UpdateHousingConditionCommand(
            patientId: patientPersonId.description,
            condition: makeValidDraft()
        )

        try await sut.execute(command: command)

        let snapshot = await repo.snapshot()
        #expect(snapshot.saveCalls == 1)
        #expect(snapshot.savedPatient?.housingCondition?.numberOfRooms == 4)
    }

    @Test("Deve retornar erro quando o paciente não existe")
    func executePatientNotFound() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .success(nil))
        let bus = EventBusSpy()
        let sut = UpdateHousingConditionService(repository: repo, eventBus: bus)

        let command = UpdateHousingConditionCommand(
            patientId: patientPersonId.description,
            condition: makeValidDraft()
        )

        await #expect(throws: UpdateHousingConditionError.patientNotFound) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve falhar se os dados da condição forem inválidos (ex: banheiros > cômodos)")
    func executeInvalidData() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let patient = try makePatient(personId: patientPersonId)
        
        let repo = PatientRepositorySpy(behavior: .success(patient))
        let bus = EventBusSpy()
        let sut = UpdateHousingConditionService(repository: repo, eventBus: bus)

        let invalidDraft = UpdateHousingConditionCommand.ConditionDraft(
            type: "OWNED",
            wallMaterial: "MASONRY",
            numberOfRooms: 2,
            numberOfBathrooms: 5, // Inválido
            waterSupply: "PUBLIC_NETWORK",
            electricityAccess: "METERED_CONNECTION",
            sewageDisposal: "PUBLIC_SEWER",
            wasteCollection: "DIRECT_COLLECTION",
            accessibilityLevel: "FULLY_ACCESSIBLE",
            isInGeographicRiskArea: false,
            isInSocialConflictArea: false
        )

        let command = UpdateHousingConditionCommand(
            patientId: patientPersonId.description,
            condition: invalidDraft
        )

        await #expect(throws: UpdateHousingConditionError.bathroomsExceedRooms) {
            try await sut.execute(command: command)
        }
    }

    @Test("Deve mapear erro genérico do repositório")
    func executeRepositoryFailure() async throws {
        let patientPersonId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        
        let repo = PatientRepositorySpy(behavior: .failureGeneric)
        let bus = EventBusSpy()
        let sut = UpdateHousingConditionService(repository: repo, eventBus: bus)

        let command = UpdateHousingConditionCommand(
            patientId: patientPersonId.description,
            condition: makeValidDraft()
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
        let sut = UpdateHousingConditionService(repository: repo, eventBus: bus)

        let command = UpdateHousingConditionCommand(
            patientId: "invalid",
            condition: makeValidDraft()
        )

        await #expect(throws: UpdateHousingConditionError.invalidPersonIdFormat("invalid")) {
            try await sut.execute(command: command)
        }
    }
}
