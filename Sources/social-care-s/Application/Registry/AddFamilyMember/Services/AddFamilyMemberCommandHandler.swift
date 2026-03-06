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
            let patientPersonId = try PersonId(command.patientPersonId)
            let memberPersonId = try PersonId(command.memberPersonId)
            let relationshipId = try LookupId(command.relationship)
            let now = TimeStamp.now

            // 2. Lookup Validation
            guard try await lookupValidator.exists(id: relationshipId, in: "dominio_parentesco") else {
                throw AddFamilyMemberError.invalidLookupId(table: "dominio_parentesco", id: relationshipId.description)
            }

            // 3. Localização do Agregado Patient
            guard var patient = try await patientRepository.find(byPersonId: patientPersonId) else {
                throw AddFamilyMemberError.patientNotFound
            }

            // 3. Verificação de unicidade dentro da família
            if patient.familyMembers.contains(where: { $0.personId == memberPersonId }) {
                throw AddFamilyMemberError.memberAlreadyExists(memberPersonId.description)
            }

            // 4. Criação da Entidade de Domínio (Member)
            let docs = command.requiredDocuments.compactMap { RequiredDocument(rawValue: $0) }
            let member = try FamilyMember(
                personId: memberPersonId,
                relationshipId: relationshipId,
                isPrimaryCaregiver: command.isCaregiver,
                residesWithPatient: command.isResiding,
                hasDisability: command.hasDisability,
                requiredDocuments: docs,
                birthDate: try TimeStamp(command.birthDate)
            )

            // 5. Mutação do Agregado
            let prId = try LookupId("00000000-0000-0000-0000-000000000001") // Mock ID para PR
            try patient.addMember(member, at: now, primaryReferenceId: prId)

            // 6. Persistência e Publicação de Eventos
            try await patientRepository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error)
        }
    }
}
