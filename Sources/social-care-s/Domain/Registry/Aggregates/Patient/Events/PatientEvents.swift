import Foundation

public struct PatientCreatedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let personId: String
    public let occurredAt: Date
    
    public init(patientId: String, personId: String, occurredAt: Date) {
        self.id = UUID()
        self.patientId = patientId
        self.personId = personId
        self.occurredAt = occurredAt
    }
}

public struct FamilyMemberAddedEvent: DomainEvent, Codable {
    public let id: UUID
    public let memberId: String
    public let patientId: String
    public let relationship: String
    public let occurredAt: Date
    
    public init(memberId: String, patientId: String, relationship: String, occurredAt: Date) {
        self.id = UUID()
        self.memberId = memberId
        self.patientId = patientId
        self.relationship = relationship
        self.occurredAt = occurredAt
    }
}

public struct FamilyMemberRemovedEvent: DomainEvent, Codable {
    public let id: UUID
    public let memberId: String
    public let patientId: String
    public let occurredAt: Date
    
    public init(memberId: String, patientId: String, occurredAt: Date) {
        self.id = UUID()
        self.memberId = memberId
        self.patientId = patientId
        self.occurredAt = occurredAt
    }
}

public struct PrimaryCaregiverAssignedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let caregiverId: String
    public let occurredAt: Date
    
    public init(patientId: String, caregiverId: String, occurredAt: Date) {
        self.id = UUID()
        self.patientId = patientId
        self.caregiverId = caregiverId
        self.occurredAt = occurredAt
    }
}

public struct ReferralCreatedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let referralId: String
    public let referredPersonId: String
    public let destinationService: String
    public let status: String
    public let occurredAt: Date
    
    public init(patientId: String, referralId: String, referredPersonId: String, destinationService: String, status: String, occurredAt: Date) {
        self.id = UUID()
        self.patientId = patientId
        self.referralId = referralId
        self.referredPersonId = referredPersonId
        self.destinationService = destinationService
        self.status = status
        self.occurredAt = occurredAt
    }
}

public struct RightsViolationReportedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let reportId: String
    public let victimId: String
    public let violationType: String
    public let occurredAt: Date
    
    public init(patientId: String, reportId: String, victimId: String, violationType: String, occurredAt: Date) {
        self.id = UUID()
        self.patientId = patientId
        self.reportId = reportId
        self.victimId = victimId
        self.violationType = violationType
        self.occurredAt = occurredAt
    }
}

public struct SocialCareAppointmentRegisteredEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let appointmentId: String
    public let professionalInChargeId: String
    public let type: String
    public let occurredAt: Date
    
    public init(patientId: String, appointmentId: String, professionalInChargeId: String, type: String, occurredAt: Date) {
        self.id = UUID()
        self.patientId = patientId
        self.appointmentId = appointmentId
        self.professionalInChargeId = professionalInChargeId
        self.type = type
        self.occurredAt = occurredAt
    }
}
