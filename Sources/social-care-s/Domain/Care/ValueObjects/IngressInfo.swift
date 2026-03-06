import Foundation

/// Value Object que representa os dados de ingresso e atendimento inicial.
public struct IngressInfo: Codable, Equatable, Sendable {
    
    public let ingressTypeId: LookupId // Tabela domínio
    public let originName: String?
    public let originContact: String?
    public let serviceReason: String
    public let linkedSocialPrograms: [ProgramLink]
    
    public init(
        ingressTypeId: LookupId,
        originName: String?,
        originContact: String?,
        serviceReason: String,
        linkedSocialPrograms: [ProgramLink]
    ) {
        self.ingressTypeId = ingressTypeId
        self.originName = originName
        self.originContact = originContact
        self.serviceReason = serviceReason
        self.linkedSocialPrograms = linkedSocialPrograms
    }
}

public struct ProgramLink: Codable, Equatable, Sendable {
    public let programId: LookupId
    public let observation: String?
    
    public init(programId: LookupId, observation: String?) {
        self.programId = programId
        self.observation = observation
    }
}
