import Foundation

/// Value Object que representa os dados de ingresso e atendimento inicial.
public struct IngressInfo: Codable, Equatable, Sendable {

    /// Identificador do tipo de ingresso (FK para dominio_tipo_ingresso).
    public let ingressTypeId: LookupId
    public let originName: String?
    public let originContact: String?
    /// Motivo do atendimento. Obrigatorio e nao pode ser vazio.
    public let serviceReason: String
    public let linkedSocialPrograms: [ProgramLink]

    /// Inicializa um IngressInfo validado.
    ///
    /// - Throws: `IngressInfoError.emptyServiceReason` se o motivo estiver vazio.
    public init(
        ingressTypeId: LookupId,
        originName: String?,
        originContact: String?,
        serviceReason: String,
        linkedSocialPrograms: [ProgramLink]
    ) throws {
        let trimmedReason = serviceReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else {
            throw IngressInfoError.emptyServiceReason
        }

        self.ingressTypeId = ingressTypeId
        self.originName = originName
        self.originContact = originContact
        self.serviceReason = trimmedReason
        self.linkedSocialPrograms = linkedSocialPrograms
    }
}

public enum IngressInfoError: Error, Sendable, Equatable {
    case emptyServiceReason
}

extension IngressInfoError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/ingress-info"
    private static let codePrefix = "ING"

    public var asAppError: AppError {
        switch self {
        case .emptyServiceReason:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O motivo do atendimento nao pode estar vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyServiceReason",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "ingress_info"]),
                http: 422
            )
        }
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
