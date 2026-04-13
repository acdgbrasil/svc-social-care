import Foundation

/// Erros específicos para o caso de uso de atualização de condições de moradia.
public enum UpdateHousingConditionError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidHousingType(String)
    case invalidWallMaterial(String)
    case invalidWaterSupply(String)
    case invalidElectricityAccess(String)
    case invalidSewageDisposal(String)
    case invalidWasteCollection(String)
    case invalidAccessibilityLevel(String)
    case negativeRooms
    case negativeBedrooms
    case negativeBathrooms
    case bedroomsExceedRooms
    case bathroomsExceedRooms
    case persistenceMappingFailure(issues: [String])
    case patientNotActive(reason: String)
}

extension UpdateHousingConditionError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "UHC"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidHousingType(let value):
            return appFailure("003", kind: "InvalidHousingType", "Tipo de moradia inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidWallMaterial(let value):
            return appFailure("004", kind: "InvalidWallMaterial", "Material de parede inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidWaterSupply(let value):
            return appFailure("005", kind: "InvalidWaterSupply", "Abastecimento de água inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidElectricityAccess(let value):
            return appFailure("006", kind: "InvalidElectricityAccess", "Acesso à eletricidade inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidSewageDisposal(let value):
            return appFailure("007", kind: "InvalidSewageDisposal", "Descarte de esgoto inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidWasteCollection(let value):
            return appFailure("008", kind: "InvalidWasteCollection", "Coleta de lixo inválida: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidAccessibilityLevel(let value):
            return appFailure("009", kind: "InvalidAccessibilityLevel", "Nível de acessibilidade inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .negativeRooms:
            return appFailure("010", kind: "NegativeRooms", "O numero de comodos nao pode ser negativo.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .negativeBedrooms:
            return appFailure("011", kind: "NegativeBedrooms", "O numero de dormitorios nao pode ser negativo.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .negativeBathrooms:
            return appFailure("012", kind: "NegativeBathrooms", "O numero de banheiros nao pode ser negativo.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .bedroomsExceedRooms:
            return appFailure("013", kind: "BedroomsExceedRooms", "O numero de dormitorios nao pode exceder o total de comodos.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .bathroomsExceedRooms:
            return appFailure("014", kind: "BathroomsExceedRooms", "O numero de banheiros nao pode exceder o total de comodos.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .patientNotActive(let reason):
            return appFailure("016", kind: "PatientNotActive", "Operação não permitida: \(reason)", category: .conflict, severity: .warning, http: 409)
        case .persistenceMappingFailure(let issues):
            return appFailure("015", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar as condicoes de moradia.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_housing_condition"]),
            http: http
        )
    }
}
