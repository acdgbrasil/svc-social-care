import Foundation

extension Patient {
    
    // MARK: - Family Management

    public mutating func addFamilyMember(_ member: FamilyMember, now: Date = Date()) throws {
        let exists = familyMembers.contains { $0.personId == member.personId }
        
        guard !exists else {
            throw PatientError.familyMemberAlreadyExists(memberId: member.personId.description)
        }

        self.familyMembers.append(member)
        
        self.recordEvent(FamilyMemberAddedEvent(
            memberId: member.personId.description,
            patientId: id.description,
            relationship: member.relationship,
            occurredAt: now
        ))
    }

    public mutating func removeFamilyMember(personId: PersonId, now: Date = Date()) throws {
        guard let index = familyMembers.firstIndex(where: { $0.personId == personId }) else {
            throw PatientError.familyMemberNotFound(personId: personId.description)
        }

        let removed = self.familyMembers.remove(at: index)
        
        self.recordEvent(FamilyMemberRemovedEvent(
            memberId: removed.personId.description,
            patientId: id.description,
            occurredAt: now
        ))
    }

    public mutating func assignPrimaryCaregiver(personId: PersonId, now: Date = Date()) throws {
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
            occurredAt: now
        ))
    }
}
