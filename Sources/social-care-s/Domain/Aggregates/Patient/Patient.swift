import Foundation

/// O Agregado Patient como um tipo puro e imutável (Value Type).
public struct Patient: EventSourcedAggregate, EventSourcedAggregateInternal {
    
    // MARK: - EventSourcedAggregate Conformance
    
    public let id: PatientId
    public internal(set) var version: Int
    public internal(set) var uncommittedEvents: [any DomainEvent] = []

    // MARK: - Domain Properties (Encapsulated)
    
    public let personId: PersonId
    public internal(set) var diagnoses: [Diagnosis]
    public internal(set) var familyMembers: [FamilyMember] = []
    public internal(set) var appointments: [SocialCareAppointment] = []
    public internal(set) var referrals: [Referral] = []
    public internal(set) var violationReports: [RightsViolationReport] = []
    
    public internal(set) var housingCondition: HousingCondition?
    public internal(set) var socioeconomicSituation: SocioEconomicSituation?
    public internal(set) var communitySupportNetwork: CommunitySupportNetwork?
    public internal(set) var socialHealthSummary: SocialHealthSummary?

    // MARK: - Internal Initializer
    
    internal init(
        id: PatientId,
        version: Int = 0,
        personId: PersonId,
        diagnoses: [Diagnosis]
    ) {
        self.id = id
        self.version = version
        self.personId = personId
        self.diagnoses = diagnoses
    }

    // MARK: - Internal Mutation (Outbox)
    
    public mutating func addEvent(_ event: any DomainEvent) {
        self.uncommittedEvents.append(event)
        self.version += 1
    }
    
    public mutating func clearEvents() {
        self.uncommittedEvents.removeAll()
    }
}
