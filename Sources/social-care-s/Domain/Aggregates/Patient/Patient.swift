import Foundation

/// O Agregado Patient como um tipo puro e imutável (Value Type).
/// Centraliza todas as informações de assistência social de um cidadão.
public struct Patient: EventSourcedAggregate, EventSourcedAggregateInternal {
    
    // MARK: - EventSourcedAggregate Conformance
    
    /// O identificador único do prontuário do paciente.
    public let id: PatientId
    
    /// A versão atual do agregado para controle de concorrência e consistência.
    public internal(set) var version: Int
    
    /// Lista de eventos de domínio que ainda não foram persistidos.
    public internal(set) var uncommittedEvents: [any DomainEvent] = []

    // MARK: - Domain Properties (Encapsulated)
    
    /// O identificador global da pessoa associada a este prontuário.
    public let personId: PersonId
    
    /// Lista de diagnósticos clínicos do paciente.
    public internal(set) var diagnoses: [Diagnosis]
    
    /// Membros da família registrados.
    public internal(set) var familyMembers: [FamilyMember] = []
    
    /// Histórico de atendimentos realizados.
    public internal(set) var appointments: [SocialCareAppointment] = []
    
    /// Encaminhamentos para outros serviços.
    public internal(set) var referrals: [Referral] = []
    
    /// Relatórios de violação de direitos registrados.
    public internal(set) var violationReports: [RightsViolationReport] = []
    
    /// Condições de moradia e habitabilidade.
    public internal(set) var housingCondition: HousingCondition?
    
    /// Situação socioeconômica do agregado familiar.
    public internal(set) var socioeconomicSituation: SocioEconomicSituation?
    
    /// Rede de apoio comunitário e social.
    public internal(set) var communitySupportNetwork: CommunitySupportNetwork?
    
    /// Resumo consolidado de saúde social.
    public internal(set) var socialHealthSummary: SocialHealthSummary?

    // MARK: - Internal Mutation (Outbox)
    
    /// Adiciona um evento à lista de não persistidos e incrementa a versão.
    public mutating func addEvent(_ event: any DomainEvent) {
        self.uncommittedEvents.append(event)
        self.version += 1
    }
    
    /// Limpa a lista de eventos pendentes.
    public mutating func clearEvents() {
        self.uncommittedEvents.removeAll()
    }
}
