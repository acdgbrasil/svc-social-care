import Foundation

extension Patient {

    // MARK: - Assessment & Intelligence Management

    /// Atualiza as condições de moradia do paciente.
    public mutating func updateHousingCondition(_ condition: HousingCondition?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.housingCondition
        self.housingCondition = condition
        self.recordEvent(HousingConditionUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: condition, occurredAt: date.date
        ))
    }

    /// Atualiza a situação socioeconômica consolidada do agregado.
    public mutating func updateSocioEconomicSituation(_ situation: SocioEconomicSituation?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.socioeconomicSituation
        self.socioeconomicSituation = situation
        self.recordEvent(SocioEconomicSituationUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: situation, occurredAt: date.date
        ))
    }

    /// Atualiza o detalhamento de trabalho e rendimento (v2.0).
    public mutating func updateWorkAndIncome(_ data: WorkAndIncome?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.workAndIncome
        self.workAndIncome = data
        self.recordEvent(WorkAndIncomeUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: data, occurredAt: date.date
        ))
    }

    /// Atualiza o perfil educacional e condicionalidades (v2.0).
    public mutating func updateEducationalStatus(_ status: EducationalStatus?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.educationalStatus
        self.educationalStatus = status
        self.recordEvent(EducationalStatusUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: status, occurredAt: date.date
        ))
    }

    /// Atualiza o estado de saúde, deficiências e gestação (v2.0).
    public mutating func updateHealthStatus(_ status: HealthStatus?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.healthStatus
        self.healthStatus = status
        self.recordEvent(HealthStatusUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: status, occurredAt: date.date
        ))
    }

    /// Atualiza a rede de apoio comunitário.
    public mutating func updateCommunitySupportNetwork(_ network: CommunitySupportNetwork?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.communitySupportNetwork
        self.communitySupportNetwork = network
        self.recordEvent(CommunitySupportNetworkUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: network, occurredAt: date.date
        ))
    }

    /// Updates the family placement and separation history (v2.0).
    public mutating func updatePlacementHistory(_ history: PlacementHistory?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.placementHistory
        self.placementHistory = history
        self.recordEvent(PlacementHistoryUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: history, occurredAt: date.date
        ))
    }

    /// Updates the intake and initial service information (v2.0).
    public mutating func updateIntakeInfo(_ info: IngressInfo?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.intakeInfo
        self.intakeInfo = info
        self.recordEvent(IntakeInfoUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: info, occurredAt: date.date
        ))
    }

    /// Atualiza o resumo de saúde social.
    public mutating func updateSocialHealthSummary(_ summary: SocialHealthSummary?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.socialHealthSummary
        self.socialHealthSummary = summary
        self.recordEvent(SocialHealthSummaryUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: summary, occurredAt: date.date
        ))
    }

    /// Atualiza a identidade étnica e social da família.
    public mutating func updateSocialIdentity(_ identity: SocialIdentity?, actorId: String, at date: TimeStamp = .now) throws {
        try requireActive()
        let before = self.socialIdentity
        self.socialIdentity = identity
        self.recordEvent(SocialIdentityUpdatedEvent(
            patientId: id.description, actorId: actorId,
            before: before, after: identity, occurredAt: date.date
        ))
    }
}
