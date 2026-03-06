import Foundation

extension DomainEventRegistry {
    /// Registra todos os eventos de domínio conhecidos do Bounded Context.
    public func bootstrap() async {
        self.register(PatientCreatedEvent.self)
        self.register(FamilyMemberAddedEvent.self)
        self.register(FamilyMemberRemovedEvent.self)
        self.register(PrimaryCaregiverAssignedEvent.self)
        self.register(ReferralCreatedEvent.self)
        self.register(RightsViolationReportedEvent.self)
        self.register(SocialCareAppointmentRegisteredEvent.self)
    }
}
