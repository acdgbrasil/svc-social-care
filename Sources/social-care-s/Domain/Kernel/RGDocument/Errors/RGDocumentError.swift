import Foundation

public enum RGDocumentError: Error, Sendable, Equatable {
    case emptyNumber
    case invalidNumberFormat(value: String)
    case invalidCheckDigit(value: String, expected: String, provided: String)
    case invalidIssuingState(value: String)
    case emptyIssuingAgency
    case issueDateInFuture(date: String, now: String)
}

extension RGDocumentError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/rg-document"
    private static let codePrefix = "RGD"

    public var asAppError: AppError {
        switch self {
        case .emptyNumber:
            return AppError(code: "\(Self.codePrefix)-001", message: "O numero do RG nao pode ser vazio.", bc: Self.bc, module: Self.module, kind: "NumberEmpty", context: [:], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "rg_document"]), http: 422)
        case .invalidNumberFormat(let value):
            return AppError(code: "\(Self.codePrefix)-005", message: "Formato do RG invalido.", bc: Self.bc, module: Self.module, kind: "InvalidNumberFormat", context: ["providedValue": AnySendable(value)], safeContext: ["providedValue": AnySendable(value)], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "rg_document"]), http: 422)
        case .invalidCheckDigit(let value, let expected, let provided):
            return AppError(code: "\(Self.codePrefix)-006", message: "Digito verificador do RG invalido.", bc: Self.bc, module: Self.module, kind: "InvalidCheckDigit", context: ["providedValue": AnySendable(value), "expectedDigit": AnySendable(expected), "providedDigit": AnySendable(provided)], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-006"], tags: ["vo": "rg_document"]), http: 422)
        case .invalidIssuingState(let value):
            return AppError(code: "\(Self.codePrefix)-002", message: "UF do RG invalida.", bc: Self.bc, module: Self.module, kind: "InvalidIssuingState", context: ["providedValue": AnySendable(value)], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "rg_document"]), http: 422)
        case .emptyIssuingAgency:
            return AppError(code: "\(Self.codePrefix)-003", message: "O orgao emissor do RG nao pode ser vazio.", bc: Self.bc, module: Self.module, kind: "IssuingAgencyEmpty", context: [:], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "rg_document"]), http: 422)
        case .issueDateInFuture(let date, let now):
            return AppError(code: "\(Self.codePrefix)-004", message: "A data de emissao do RG nao pode estar no futuro.", bc: Self.bc, module: Self.module, kind: "IssueDateInFuture", context: ["date": AnySendable(date), "now": AnySendable(now)], safeContext: [:], observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "rg_document"]), http: 422)
        }
    }
}
