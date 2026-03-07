import Testing
import Foundation
@testable import social_care_s

@Suite("UpdateSocioEconomicSituation Command Handler")
struct UpdateSocioEconomicSituationTests {

    @Test("Deve atualizar situacao socioeconomica com sucesso")
    func successfulUpdate() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try PatientFixture.createMinimal()
        await repo.seed(patient)

        let handler = UpdateSocioEconomicSituationCommandHandler(repository: repo, eventBus: bus)

        try await handler.handle(UpdateSocioEconomicSituationCommand(
            patientId: PatientFixture.defaultPersonId,
            situation: .init(
                totalFamilyIncome: 2500.0,
                incomePerCapita: 1250.0,
                receivesSocialBenefit: true,
                socialBenefits: [
                    .init(benefitName: "Bolsa Familia", amount: 600.0, beneficiaryId: PatientFixture.defaultPersonId)
                ],
                mainSourceOfIncome: "Trabalho informal",
                hasUnemployed: false
            ),
            actorId: "actor-1"
        ))

        let saved = try await repo.find(byPersonId: PersonId(PatientFixture.defaultPersonId))
        #expect(saved?.socioeconomicSituation != nil)
        #expect(saved?.socioeconomicSituation?.totalFamilyIncome == 2500.0)

        let eventCount = await bus.eventCount()
        #expect(eventCount >= 1)
    }

    @Test("Deve atualizar sem beneficios sociais")
    func updateWithoutBenefits() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try PatientFixture.createMinimal()
        await repo.seed(patient)

        let handler = UpdateSocioEconomicSituationCommandHandler(repository: repo, eventBus: bus)

        try await handler.handle(UpdateSocioEconomicSituationCommand(
            patientId: PatientFixture.defaultPersonId,
            situation: .init(
                totalFamilyIncome: 1500.0,
                incomePerCapita: 750.0,
                receivesSocialBenefit: false,
                socialBenefits: [],
                mainSourceOfIncome: "Emprego formal",
                hasUnemployed: false
            ),
            actorId: "actor-1"
        ))

        let saved = try await repo.find(byPersonId: PersonId(PatientFixture.defaultPersonId))
        #expect(saved?.socioeconomicSituation?.receivesSocialBenefit == false)
    }

    @Test("Deve falhar quando paciente nao encontrado")
    func patientNotFound() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let handler = UpdateSocioEconomicSituationCommandHandler(repository: repo, eventBus: bus)

        await #expect(throws: UpdateSocioEconomicSituationError.self) {
            try await handler.handle(UpdateSocioEconomicSituationCommand(
                patientId: UUID().uuidString,
                situation: .init(
                    totalFamilyIncome: 1000.0,
                    incomePerCapita: 500.0,
                    receivesSocialBenefit: false,
                    socialBenefits: [],
                    mainSourceOfIncome: "Trabalho",
                    hasUnemployed: false
                ),
                actorId: "actor-1"
            ))
        }
    }

    @Test("Actor isolation: atualizacoes concorrentes")
    func concurrentUpdates() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()

        let p1 = try PatientFixture.createMinimal(personId: UUID().uuidString)
        let p2 = try PatientFixture.createMinimal(personId: UUID().uuidString)
        await repo.seed(p1)
        await repo.seed(p2)

        let handler = UpdateSocioEconomicSituationCommandHandler(repository: repo, eventBus: bus)

        async let r1: Void = handler.handle(UpdateSocioEconomicSituationCommand(
            patientId: p1.personId.description,
            situation: .init(
                totalFamilyIncome: 3000.0, incomePerCapita: 1500.0,
                receivesSocialBenefit: false, socialBenefits: [],
                mainSourceOfIncome: "Fonte A", hasUnemployed: false
            ),
            actorId: "actor-1"
        ))
        async let r2: Void = handler.handle(UpdateSocioEconomicSituationCommand(
            patientId: p2.personId.description,
            situation: .init(
                totalFamilyIncome: 1000.0, incomePerCapita: 500.0,
                receivesSocialBenefit: false, socialBenefits: [],
                mainSourceOfIncome: "Fonte B", hasUnemployed: true
            ),
            actorId: "actor-2"
        ))

        try await r1
        try await r2

        let saved1 = try await repo.find(byPersonId: p1.personId)
        let saved2 = try await repo.find(byPersonId: p2.personId)
        #expect(saved1?.socioeconomicSituation?.totalFamilyIncome == 3000.0)
        #expect(saved2?.socioeconomicSituation?.totalFamilyIncome == 1000.0)
    }
}
