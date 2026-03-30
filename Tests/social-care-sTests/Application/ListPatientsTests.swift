import Testing
import Foundation
@testable import social_care_s

@Suite("ListPatients Query Handler")
struct ListPatientsTests {

    private static func makePatientWithName(
        firstName: String,
        lastName: String,
        personId: String = UUID().uuidString
    ) throws -> Patient {
        let pid = try PersonId(personId)
        let prId = try LookupId(UUID().uuidString)
        let prMember = FamilyMember(
            personId: pid,
            relationshipId: prId,
            isPrimaryCaregiver: true,
            residesWithPatient: true,
            birthDate: .now
        )
        let personalData = try PersonalData(
            firstName: firstName,
            lastName: lastName,
            motherName: "Mãe",
            nationality: "Brasileira",
            sex: .feminino,
            socialName: nil,
            birthDate: try TimeStamp(iso: "1990-01-01T00:00:00Z"),
            phone: nil
        )
        return try Patient(
            id: PatientId(),
            personId: pid,
            personalData: personalData,
            diagnoses: [PatientFixture.createDiagnosis()],
            familyMembers: [prMember],
            prRelationshipId: prId,
            actorId: "test-actor"
        )
    }

    // MARK: - Lista vazia

    @Test("Deve retornar lista vazia quando nao ha pacientes")
    func emptyList() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let result = try await handler.handle(ListPatientsQuery())

        #expect(result.items.isEmpty)
        #expect(result.totalCount == 0)
        #expect(result.hasMore == false)
        #expect(result.nextCursor == nil)
    }

    // MARK: - Lista com resultados

    @Test("Deve retornar todos os pacientes cadastrados")
    func listAllPatients() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let p1 = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        let p2 = try Self.makePatientWithName(firstName: "João", lastName: "Franklin")
        await repo.seed(p1)
        await repo.seed(p2)

        let result = try await handler.handle(ListPatientsQuery())

        #expect(result.items.count == 2)
        #expect(result.totalCount == 2)
        #expect(result.hasMore == false)
    }

    @Test("Deve retornar fullName composto de firstName e lastName")
    func fullNameComposition() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let patient = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        await repo.seed(patient)

        let result = try await handler.handle(ListPatientsQuery())

        #expect(result.items.first?.fullName == "Maria Costa")
        #expect(result.items.first?.firstName == "Maria")
        #expect(result.items.first?.lastName == "Costa")
    }

    @Test("Deve retornar diagnostico primario e contagem de membros")
    func diagnosisAndMemberCount() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let patient = try Self.makePatientWithName(firstName: "Ana", lastName: "Aderaldo")
        await repo.seed(patient)

        let result = try await handler.handle(ListPatientsQuery())

        #expect(result.items.first?.primaryDiagnosis == "Test diagnosis")
        #expect(result.items.first?.memberCount == 1)
    }

    // MARK: - Busca

    @Test("Deve filtrar pacientes por firstName")
    func searchByFirstName() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let p1 = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        let p2 = try Self.makePatientWithName(firstName: "João", lastName: "Franklin")
        await repo.seed(p1)
        await repo.seed(p2)

        let result = try await handler.handle(ListPatientsQuery(search: "Maria"))

        #expect(result.items.count == 1)
        #expect(result.items.first?.firstName == "Maria")
    }

    @Test("Deve filtrar pacientes por lastName")
    func searchByLastName() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let p1 = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        let p2 = try Self.makePatientWithName(firstName: "João", lastName: "Franklin")
        await repo.seed(p1)
        await repo.seed(p2)

        let result = try await handler.handle(ListPatientsQuery(search: "franklin"))

        #expect(result.items.count == 1)
        #expect(result.items.first?.lastName == "Franklin")
    }

    @Test("Busca case-insensitive deve funcionar")
    func caseInsensitiveSearch() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let patient = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        await repo.seed(patient)

        let result = try await handler.handle(ListPatientsQuery(search: "MARIA"))

        #expect(result.items.count == 1)
    }

    @Test("Busca sem resultados deve retornar lista vazia")
    func searchNoResults() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let patient = try Self.makePatientWithName(firstName: "Maria", lastName: "Costa")
        await repo.seed(patient)

        let result = try await handler.handle(ListPatientsQuery(search: "inexistente"))

        #expect(result.items.isEmpty)
    }

    // MARK: - Paginação

    @Test("Deve respeitar o limite de itens por pagina")
    func respectsLimit() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        for i in 1...5 {
            let patient = try Self.makePatientWithName(firstName: "Paciente\(i)", lastName: "Sobrenome\(i)")
            await repo.seed(patient)
        }

        let result = try await handler.handle(ListPatientsQuery(limit: 2))

        #expect(result.items.count == 2)
        #expect(result.hasMore == true)
        #expect(result.nextCursor != nil)
        #expect(result.totalCount == 5)
    }

    @Test("Deve paginar usando cursor")
    func paginationWithCursor() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        for i in 1...5 {
            let patient = try Self.makePatientWithName(firstName: "P\(i)", lastName: "S\(i)")
            await repo.seed(patient)
        }

        // Primeira página
        let page1 = try await handler.handle(ListPatientsQuery(limit: 2))
        #expect(page1.items.count == 2)
        #expect(page1.hasMore == true)

        // Segunda página usando cursor
        let page2 = try await handler.handle(ListPatientsQuery(cursor: page1.nextCursor, limit: 2))
        #expect(page2.items.count == 2)
        #expect(page2.hasMore == true)

        // Terceira página (última)
        let page3 = try await handler.handle(ListPatientsQuery(cursor: page2.nextCursor, limit: 2))
        #expect(page3.items.count == 1)
        #expect(page3.hasMore == false)
        #expect(page3.nextCursor == nil)

        // Sem duplicatas entre páginas
        let allIds = (page1.items + page2.items + page3.items).map { $0.patientId }
        let uniqueIds = Set(allIds)
        #expect(uniqueIds.count == 5)
    }

    // MARK: - Validação de erros

    @Test("Deve falhar com limite invalido (zero)")
    func invalidLimitZero() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        await #expect(throws: ListPatientsError.self) {
            try await handler.handle(ListPatientsQuery(limit: 0))
        }
    }

    @Test("Deve falhar com limite invalido (acima de 100)")
    func invalidLimitTooHigh() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        await #expect(throws: ListPatientsError.self) {
            try await handler.handle(ListPatientsQuery(limit: 101))
        }
    }

    @Test("Deve falhar com cursor em formato invalido")
    func invalidCursorFormat() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        await #expect(throws: ListPatientsError.self) {
            try await handler.handle(ListPatientsQuery(cursor: "not-a-uuid"))
        }
    }

    // MARK: - Pacientes sem personalData

    @Test("Deve listar pacientes sem personalData com campos nil")
    func patientsWithoutPersonalData() async throws {
        let repo = InMemoryPatientRepository()
        let handler = ListPatientsQueryHandler(repository: repo)

        let patient = try PatientFixture.createMinimal()
        await repo.seed(patient)

        let result = try await handler.handle(ListPatientsQuery())

        #expect(result.items.count == 1)
        #expect(result.items.first?.firstName == nil)
        #expect(result.items.first?.lastName == nil)
        #expect(result.items.first?.fullName == nil)
    }
}
