import Foundation

public struct PatientCreatedEvent: DomainEvent {
    public let id = UUID()
    public let patientId: String
    public let personId: String
    public let occurredAt: Date
}

public struct FamilyMemberAddedEvent: DomainEvent {
    public let id = UUID()
    public let memberId: String
    public let patientId: String
    public let relationship: String
    public let occurredAt: Date
}

public struct FamilyMemberRemovedEvent: DomainEvent {
    public let id = UUID()
    public let memberId: String
    public let patientId: String
    public let occurredAt: Date
}

public struct PrimaryCaregiverAssignedEvent: DomainEvent {
    public let id = UUID()
    public let patientId: String
    public let caregiverId: String
    public let occurredAt: Date
}

public struct ReferralCreatedEvent: DomainEvent {
    public let id = UUID()
    public let patientId: String
    public let referralId: String
    public let referredPersonId: String
    public let destinationService: String
    public let status: String
    public let occurredAt: Date
}

public struct RightsViolationReportedEvent: DomainEvent {
    public let id = UUID()
    public let patientId: String
    public let reportId: String
    public let victimId: String
    public let violationType: String
    public let occurredAt: Date
}

public struct SocialCareAppointmentRegisteredEvent: DomainEvent {
    public let id = UUID()
    public let patientId: String
    public let appointmentId: String
    public let professionalInChargeId: String
    public let type: String
    public let occurredAt: Date
}
