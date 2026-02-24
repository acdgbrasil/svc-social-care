import Foundation

/// Erros específicos para o caso de uso de atualização de condições de moradia.
enum UpdateHousingConditionError: Error, Sendable, Equatable {
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
    case negativeBathrooms
    case bathroomsExceedRooms
    case persistenceMappingFailure(issues: [String])
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
            return appFailure("010", kind: "NegativeRooms", "O número de cômodos não pode ser negativo.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .negativeBathrooms:
            return appFailure("011", kind: "NegativeBathrooms", "O número de banheiros não pode ser negativo.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .bathroomsExceedRooms:
            return appFailure("012", kind: "BathroomsExceedRooms", "O número de banheiros não pode exceder o total de cômodos.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("013", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar as condições de moradia.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
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
