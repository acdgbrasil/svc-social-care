import Foundation

public actor UpdateWorkAndIncomeCommandHandler: UpdateWorkAndIncomeUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    private let lookupValidator: any LookupValidating

    public init(repository: any PatientRepository, eventBus: any EventBus, lookupValidator: any LookupValidating) {
        self.repository = repository
        self.eventBus = eventBus
        self.lookupValidator = lookupValidator
    }

    public func handle(_ command: UpdateWorkAndIncomeCommand) async throws {
        do {
            // 1. Parse
            let personId = try PersonId(command.patientId)

            // 2. Lookup Validation
            for draft in command.individualIncomes {
                let occId = try LookupId(draft.occupationId)
                guard try await lookupValidator.exists(id: occId, in: "dominio_condicao_ocupacao") else {
                    throw UpdateWorkAndIncomeError.invalidLookupId(table: "dominio_condicao_ocupacao", id: occId.description)
                }
            }

            // 3. Build VOs
            let incomes = try command.individualIncomes.map { draft in
                try WorkIncomeVO(
                    memberId: try PersonId(draft.memberId),
                    occupationId: try LookupId(draft.occupationId),
                    hasWorkCard: draft.hasWorkCard,
                    monthlyAmount: draft.monthlyAmount
                )
            }

            let benefits = try command.socialBenefits.map { draft in
                try SocialBenefit(
                    benefitName: draft.benefitName,
                    amount: draft.amount,
                    beneficiaryId: try PersonId(draft.beneficiaryId)
                )
            }

            // 4. Fetch
            guard var patient = try await repository.find(byPersonId: personId) else {
                throw UpdateWorkAndIncomeError.patientNotFound
            }

            let workAndIncome = WorkAndIncome(
                familyId: patient.id,
                individualIncomes: incomes,
                socialBenefits: benefits,
                hasRetiredMembers: command.hasRetiredMembers
            )

            // 5. Domain Logic
            patient.updateWorkAndIncome(workAndIncome, actorId: command.actorId)

            // 6. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
