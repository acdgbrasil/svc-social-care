import Foundation

extension Patient {
    
    // MARK: - Assessment Management

    /// Atualiza as condições de moradia do paciente.
    public mutating func updateHousingCondition(_ condition: HousingCondition?) {
        self.housingCondition = condition
        self.version += 1
    }

    /// Atualiza a situação socioeconômica do agregado familiar.
    public mutating func updateSocioEconomicSituation(_ situation: SocioEconomicSituation?) {
        self.socioeconomicSituation = situation
        self.version += 1
    }

    /// Atualiza a rede de apoio comunitário.
    public mutating func updateCommunitySupportNetwork(_ network: CommunitySupportNetwork?) {
        self.communitySupportNetwork = network
        self.version += 1
    }

    /// Atualiza o resumo de saúde social.
    public mutating func updateSocialHealthSummary(_ summary: SocialHealthSummary?) {
        self.socialHealthSummary = summary
        self.version += 1
    }
}
