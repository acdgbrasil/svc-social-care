import Foundation

/// Implementação do serviço Maestro para adicionar novos membros à família de um paciente.
public actor AddFamilyMemberCommandHandler: AddFamilyMemberUseCase {
    private let patientRepository: any PatientRepository
    private let eventBus: any EventBus
    private let lookupValidator: any LookupValidating

    public init(patientRepository: any PatientRepository, eventBus: any EventBus, lookupValidator: any LookupValidating) {
        self.patientRepository = patientRepository
        self.eventBus = eventBus
        self.lookupValidator = lookupValidator
    }

    public func handle(_ command: AddFamilyMemberCommand) async throws {
        do {
            // 1. Parse de IDs e instantes
            let patientId = try PatientId(command.patientId)
            let memberPersonId = try PersonId(command.memberPersonId)
            let relationshipId = try LookupId(command.relationship)
            let now = TimeStamp.now

            // 2. Lookup Validation
            guard try await lookupValidator.exists(id: relationshipId, in: "dominio_parentesco") else {
                throw AddFamilyMemberError.invalidLookupId(table: "dominio_parentesco", id: relationshipId.description)
            }

            // 3. Localização do Agregado Patient
            guard var patient = try await patientRepository.find(byId: patientId) else {
                throw AddFamilyMemberError.patientNotFound
            }

            // 4. Verificação de unicidade dentro da família
            if patient.familyMembers.contains(where: { $0.personId == memberPersonId }) {
                throw AddFamilyMemberError.memberAlreadyExists(memberPersonId.description)
            }

            // 5. Criação da Entidade de Domínio (Member)
            let docs = command.requiredDocuments.compactMap { RequiredDocument(rawValue: $0) }
            let member = FamilyMember(
                personId: memberPersonId,
                relationshipId: relationshipId,
                isPrimaryCaregiver: command.isCaregiver,
                residesWithPatient: command.isResiding,
                hasDisability: command.hasDisability,
                requiredDocuments: docs,
                birthDate: try TimeStamp(command.birthDate)
            )

            // 6. Mutação do Agregado
            let prId = try LookupId(command.prRelationshipId)
            try patient.addMember(member, actorId: command.actorId, at: now, primaryReferenceId: prId)

            // 7. Persistência e Publicação de Eventos
            try await patientRepository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error)
        }
    }
}
