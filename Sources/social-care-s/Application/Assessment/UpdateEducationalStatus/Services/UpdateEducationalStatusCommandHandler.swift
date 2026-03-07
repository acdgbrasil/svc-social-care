import Foundation

public actor UpdateEducationalStatusCommandHandler: UpdateEducationalStatusUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    private let lookupValidator: any LookupValidating

    public init(repository: any PatientRepository, eventBus: any EventBus, lookupValidator: any LookupValidating) {
        self.repository = repository
        self.eventBus = eventBus
        self.lookupValidator = lookupValidator
    }

    public func handle(_ command: UpdateEducationalStatusCommand) async throws {
        do {
            // 1. Parse
            let personId = try PersonId(command.patientId)

            // 2. Lookup Validation
            for draft in command.memberProfiles {
                let levelId = try LookupId(draft.educationLevelId)
                guard try await lookupValidator.exists(id: levelId, in: "dominio_escolaridade") else {
                    throw UpdateEducationalStatusError.invalidLookupId(table: "dominio_escolaridade", id: levelId.description)
                }
            }
            for draft in command.programOccurrences {
                let effId = try LookupId(draft.effectId)
                guard try await lookupValidator.exists(id: effId, in: "dominio_efeito_condicionalidade") else {
                    throw UpdateEducationalStatusError.invalidLookupId(table: "dominio_efeito_condicionalidade", id: effId.description)
                }
            }

            // 3. Build VOs
            let profiles = try command.memberProfiles.map { draft in
                MemberEducationalProfile(
                    memberId: try PersonId(draft.memberId),
                    canReadWrite: draft.canReadWrite,
                    attendsSchool: draft.attendsSchool,
                    educationLevelId: try LookupId(draft.educationLevelId)
                )
            }

            let occurrences = try command.programOccurrences.map { draft in
                ProgramOccurrence(
                    memberId: try PersonId(draft.memberId),
                    date: try TimeStamp(draft.date),
                    effectId: try LookupId(draft.effectId),
                    isSuspensionRequested: draft.isSuspensionRequested
                )
            }

            // 4. Fetch
            guard var patient = try await repository.find(byPersonId: personId) else {
                throw UpdateEducationalStatusError.patientNotFound
            }

            let status = EducationalStatus(
                familyId: patient.id,
                memberProfiles: profiles,
                programOccurrences: occurrences
            )

            // 5. Domain Logic
            patient.updateEducationalStatus(status, actorId: command.actorId)

            // 6. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
