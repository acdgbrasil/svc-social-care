import Foundation

public enum PatientError: Error, Sendable, Equatable {
    case initialIdIsRequired
    case initialPersonIdIsRequired
    case initialDiagnosesCantBeEmpty
    case familyMemberAlreadyExists(memberId: String)
    case familyMemberNotFound(personId: String)
    case referralTargetOutsideBoundary(targetId: String)
    case violationTargetOutsideBoundary(targetId: String)
    
    // Versão 2.0 - Regras de PR e Ciclo de Vida
    case mustHaveExactlyOnePrimaryReference
    case multiplePrimaryReferencesNotAllowed
    case incompatiblePlacementSituation
    case incompatibleGuardianshipSituation

    // Versão 2.1 - Desligamento e Readmissão
    case alreadyDischarged
    case alreadyActive
    case patientIsDischarged

    // Versão 2.2 - Lista de Espera
    case cannotAdmitDischarged
    case cannotDischargeWaitlisted
    case cannotReadmitWaitlisted
    case alreadyWaitlisted
    case patientIsWaitlisted
}

extension PatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/patient"
    private static let codePrefix = "PAT"

    public var asAppError: AppError {
        switch self {
        case .initialIdIsRequired:
            return appFailure("001", "ID inicial é obrigatório.")
        case .initialPersonIdIsRequired:
            return appFailure("002", "PersonId inicial é obrigatório.")
        case .initialDiagnosesCantBeEmpty:
            return appFailure("003", "A lista de diagnósticos inicial não pode estar vazia.")
        case .familyMemberAlreadyExists(let memberId):
            return appFailure("004", "Membro familiar já existe: \(memberId).", context: ["memberId": memberId])
        case .familyMemberNotFound(let personId):
            return appFailure("005", "Membro familiar não encontrado para a pessoa: \(personId).", context: ["personId": personId])
        case .referralTargetOutsideBoundary(let targetId):
            return appFailure("006", "O alvo do encaminhamento (\(targetId)) está fora da fronteira do agregado.")
        case .violationTargetOutsideBoundary(let targetId):
            return appFailure("007", "A vítima da violação (\(targetId)) está fora da fronteira do agregado.")
        case .mustHaveExactlyOnePrimaryReference:
            return appFailure("008", "A família deve possuir exatamente uma Pessoa de Referência (código 01).")
        case .multiplePrimaryReferencesNotAllowed:
            return appFailure("009", "Não é permitido ter mais de uma Pessoa de Referência na mesma família.")
        case .incompatiblePlacementSituation:
            return appFailure("010", "A situacao de afastamento informada e incompativel com a composicao etaria da familia.")
        case .incompatibleGuardianshipSituation:
            return appFailure("011", "O relato de guarda de terceiros e incompativel com a composicao etaria da familia.")
        case .alreadyDischarged:
            return AppError(
                code: "\(Self.codePrefix)-012",
                message: "O paciente já está desligado.",
                bc: Self.bc, module: Self.module, kind: "AlreadyDischarged",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-012"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .alreadyActive:
            return AppError(
                code: "\(Self.codePrefix)-013",
                message: "O paciente já está ativo.",
                bc: Self.bc, module: Self.module, kind: "AlreadyActive",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-013"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .patientIsDischarged:
            return AppError(
                code: "\(Self.codePrefix)-014",
                message: "Operação não permitida: o paciente está desligado. Readmita o paciente antes de realizar alterações.",
                bc: Self.bc, module: Self.module, kind: "PatientIsDischarged",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-014"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .cannotAdmitDischarged:
            return AppError(
                code: "\(Self.codePrefix)-015",
                message: "Paciente desligado não pode ser admitido diretamente. Use readmit primeiro.",
                bc: Self.bc, module: Self.module, kind: "CannotAdmitDischarged",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-015"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .cannotDischargeWaitlisted:
            return AppError(
                code: "\(Self.codePrefix)-016",
                message: "Paciente em lista de espera não pode ser desligado. Use withdraw.",
                bc: Self.bc, module: Self.module, kind: "CannotDischargeWaitlisted",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-016"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .cannotReadmitWaitlisted:
            return AppError(
                code: "\(Self.codePrefix)-017",
                message: "Paciente em lista de espera não pode ser readmitido. Use admit.",
                bc: Self.bc, module: Self.module, kind: "CannotReadmitWaitlisted",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-017"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .alreadyWaitlisted:
            return AppError(
                code: "\(Self.codePrefix)-018",
                message: "O paciente já está na lista de espera.",
                bc: Self.bc, module: Self.module, kind: "AlreadyWaitlisted",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-018"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        case .patientIsWaitlisted:
            return AppError(
                code: "\(Self.codePrefix)-019",
                message: "Operação não permitida: o paciente está na lista de espera. Admita o paciente antes de realizar alterações.",
                bc: Self.bc, module: Self.module, kind: "PatientIsWaitlisted",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-019"],
                    tags: ["aggregate": "patient"]
                ),
                http: 409
            )
        }
    }

    private func appFailure(_ subCode: String, _ message: String, context: [String: Any] = [:]) -> AppError {
        return AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: "DomainError",
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["aggregate": "patient"]),
            http: 422
        )
    }
}
