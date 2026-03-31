import Foundation

public enum CivilDocumentsError: Error, Sendable, Equatable {
    case atLeastOneDocumentRequired
    case cpfMismatchWithCNS
}

extension CivilDocumentsError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/civil-documents"
    private static let codePrefix = "CVD"

    public var asAppError: AppError {
        switch self {
        case .atLeastOneDocumentRequired:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Ao menos um documento civil (CPF, NIS, RG ou CNS) deve ser informado.",
                bc: Self.bc, module: Self.module, kind: "AtLeastOneDocumentRequired",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "civil_documents"]),
                http: 422
            )
        case .cpfMismatchWithCNS:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O CPF informado nao corresponde ao CPF do Cartao do SUS (CNS).",
                bc: Self.bc, module: Self.module, kind: "CpfMismatchWithCNS",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "civil_documents"]),
                http: 422
            )
        }
    }
}
