import Foundation

public enum RGDocumentError: Error, Sendable, Equatable {
    case emptyNumber
    case invalidNumberFormat(value: String)
    case invalidIssuingState(value: String)
    case emptyIssuingAgency
    case issueDateInFuture(date: String, now: String)
}

extension RGDocumentError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/rg-document"
    private static let codePrefix = "RGD"

    private static func maskRG(_ rg: String) -> String {
        guard rg.count > 4 else { return "****" }
        return "\(rg.prefix(2))***\(rg.suffix(1))"
    }

    public var asAppError: AppError {
        switch self {
        case .emptyNumber:
            return AppError(code: "\(Self.codePrefix)-001", message: "O numero do RG nao pode ser vazio.", bc: Self.bc, module: Self.module, kind: "NumberEmpty", context: [:], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "rg_document"]), http: 422)
        case .invalidNumberFormat(let value):
            return AppError(code: "\(Self.codePrefix)-005", message: "Formato do RG invalido. Aceito: alfanumerico, 4 a 15 caracteres (pontos, hifens e espacos sao removidos antes da validacao).", bc: Self.bc, module: Self.module, kind: "InvalidNumberFormat", context: ["providedLength": AnySendable(value.count)], safeContext: ["providedValue": AnySendable(Self.maskRG(value))], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "rg_document"]), http: 422)
        case .invalidIssuingState(let value):
            return AppError(code: "\(Self.codePrefix)-002", message: "UF do RG invalida.", bc: Self.bc, module: Self.module, kind: "InvalidIssuingState", context: ["providedValue": AnySendable(value)], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "rg_document"]), http: 422)
        case .emptyIssuingAgency:
            return AppError(code: "\(Self.codePrefix)-003", message: "O orgao emissor do RG nao pode ser vazio.", bc: Self.bc, module: Self.module, kind: "IssuingAgencyEmpty", context: [:], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "rg_document"]), http: 422)
        case .issueDateInFuture(let date, let now):
            return AppError(code: "\(Self.codePrefix)-004", message: "A data de emissao do RG nao pode estar no futuro.", bc: Self.bc, module: Self.module, kind: "IssueDateInFuture", context: ["date": AnySendable(date), "now": AnySendable(now)], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "rg_document"]), http: 422)
        }
    }
}
