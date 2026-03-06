import Foundation

extension Patient {
    
    // MARK: - Assessment & Intelligence Management

    /// Atualiza as condições de moradia do paciente.
    public mutating func updateHousingCondition(_ condition: HousingCondition?) {
        self.housingCondition = condition
        self.version += 1
    }

    /// Atualiza a situação socioeconômica consolidada do agregado.
    public mutating func updateSocioEconomicSituation(_ situation: SocioEconomicSituation?) {
        self.socioeconomicSituation = situation
        self.version += 1
    }

    /// Atualiza o detalhamento de trabalho e rendimento (v2.0).
    public mutating func updateWorkAndIncome(_ data: WorkAndIncome?) {
        self.workAndIncome = data
        self.version += 1
    }

    /// Atualiza o perfil educacional e condicionalidades (v2.0).
    public mutating func updateEducationalStatus(_ status: EducationalStatus?) {
        self.educationalStatus = status
        self.version += 1
    }

    /// Atualiza o estado de saúde, deficiências e gestação (v2.0).
    public mutating func updateHealthStatus(_ status: HealthStatus?) {
        self.healthStatus = status
        self.version += 1
    }

    /// Atualiza a rede de apoio comunitário.
    public mutating func updateCommunitySupportNetwork(_ network: CommunitySupportNetwork?) {
        self.communitySupportNetwork = network
        self.version += 1
    }

    /// Updates the family placement and separation history (v2.0).
    public mutating func updatePlacementHistory(_ history: PlacementHistory?) {
        self.placementHistory = history
        self.version += 1
    }

    /// Updates the intake and initial service information (v2.0).
    public mutating func updateIntakeInfo(_ info: IngressInfo?) {
        self.intakeInfo = info
        self.version += 1
    }

    /// Atualiza o resumo de saúde social.
    public mutating func updateSocialHealthSummary(_ summary: SocialHealthSummary?) {
        self.socialHealthSummary = summary
        self.version += 1
    }

    /// Atualiza a identidade étnica e social da família.
    public mutating func updateSocialIdentity(_ identity: SocialIdentity?) {
        self.socialIdentity = identity
        self.version += 1
    }
}
