import Foundation

extension Patient {
    
    // MARK: - Family Management

    /// Adiciona um novo membro familiar ao agregado do paciente.
    ///
    /// - Parameters:
    ///   - member: A entidade FamilyMember a ser adicionada.
    ///   - now: O instante da operação para fins de registro de evento.
    /// - Throws: `PatientError.familyMemberAlreadyExists` se a pessoa já estiver registrada na família.
    public mutating func addFamilyMember(_ member: FamilyMember, now: TimeStamp = .now) throws {
        let exists = familyMembers.contains { $0.personId == member.personId }
        
        guard !exists else {
            throw PatientError.familyMemberAlreadyExists(memberId: member.personId.description)
        }

        self.familyMembers.append(member)
        
        self.recordEvent(FamilyMemberAddedEvent(
            memberId: member.personId.description,
            patientId: id.description,
            relationship: member.relationship,
            occurredAt: now.date
        ))
    }

    /// Remove um membro familiar do agregado através do seu PersonId.
    ///
    /// - Parameters:
    ///   - personId: O identificador da pessoa a ser removida.
    ///   - now: O instante da operação.
    /// - Throws: `PatientError.familyMemberNotFound` se o membro não pertencer à família.
    public mutating func removeFamilyMember(personId: PersonId, now: TimeStamp = .now) throws {
        guard let index = familyMembers.firstIndex(where: { $0.personId == personId }) else {
            throw PatientError.familyMemberNotFound(personId: personId.description)
        }

        let removed = self.familyMembers.remove(at: index)
        
        self.recordEvent(FamilyMemberRemovedEvent(
            memberId: removed.personId.description,
            patientId: id.description,
            occurredAt: now.date
        ))
    }

    /// Atribui uma pessoa como cuidador principal, revogando o status dos demais.
    ///
    /// - Parameters:
    ///   - personId: O identificador da pessoa que assumirá o cuidado.
    ///   - now: O instante da operação.
    /// - Throws: `PatientError.familyMemberNotFound` se a pessoa não pertencer à família.
    public mutating func assignPrimaryCaregiver(personId: PersonId, now: TimeStamp = .now) throws {
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
            occurredAt: now.date
        ))
    }
}
