import Foundation

extension Patient {
    
    // MARK: - Family Management

    /// Adiciona um novo membro familiar ao agregado do paciente.
    ///
    /// - Parameters:
    ///   - member: A entidade FamilyMember a ser adicionada.
    ///   - date: O instante da operação para fins de registro de evento.
    ///   - primaryReferenceId: O ID que identifica a Pessoa de Referência para validação.
    /// - Throws: `PatientError.familyMemberAlreadyExists` se a pessoa já estiver registrada na família.
    public mutating func addMember(_ member: FamilyMember, at date: TimeStamp = .now, primaryReferenceId: LookupId) throws {
        let exists = familyMembers.contains { $0.personId == member.personId }
        
        guard !exists else {
            throw PatientError.familyMemberAlreadyExists(memberId: member.personId.description)
        }

        // Se o novo membro for uma PR, validar se já existe uma
        if member.relationshipId == primaryReferenceId {
            let hasPR = familyMembers.contains { $0.relationshipId == primaryReferenceId }
            if hasPR { throw PatientError.multiplePrimaryReferencesNotAllowed }
        }

        self.familyMembers.append(member)
        
        self.recordEvent(FamilyMemberAddedEvent(
            memberId: member.personId.description,
            patientId: id.description,
            relationship: member.relationshipId.description,
            occurredAt: date.date
        ))
    }

    /// Remove um membro familiar do agregado através do seu PersonId.
    ///
    /// - Parameters:
    ///   - personId: O identificador da pessoa a ser removida.
    ///   - date: O instante da operação.
    /// - Throws: `PatientError.familyMemberNotFound` se o membro não pertencer à família.
    public mutating func removeMember(identifiedBy personId: PersonId, at date: TimeStamp = .now) throws {
        guard let index = familyMembers.firstIndex(where: { $0.personId == personId }) else {
            throw PatientError.familyMemberNotFound(personId: personId.description)
        }

        let removed = self.familyMembers.remove(at: index)
        
        self.recordEvent(FamilyMemberRemovedEvent(
            memberId: removed.personId.description,
            patientId: id.description,
            occurredAt: date.date
        ))
    }

    /// Atribui uma pessoa como cuidador principal, revogando o status dos demais.
    ///
    /// - Parameters:
    ///   - personId: O identificador da pessoa que assumirá o cuidado.
    ///   - date: O instante da operação.
    /// - Throws: `PatientError.familyMemberNotFound` se a pessoa não pertencer à família.
    public mutating func assignPrimaryCaregiver(identifiedBy personId: PersonId, at date: TimeStamp = .now) throws {
        guard familyMembers.contains(where: { $0.personId == personId }) else {
            throw PatientError.familyMemberNotFound(personId: personId.description)
        }

        // Mutação In-Place idiomática
        for index in familyMembers.indices {
            if familyMembers[index].personId == personId {
                familyMembers[index].assignAsPrimaryCaregiver()
            } else {
                familyMembers[index].revokePrimaryCaregiver()
            }
        }
        
        self.recordEvent(PrimaryCaregiverAssignedEvent(
            patientId: id.description,
            caregiverId: personId.description,
            occurredAt: date.date
        ))
    }
}
