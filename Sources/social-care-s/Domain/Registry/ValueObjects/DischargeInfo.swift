import Foundation

// MARK: - Errors

public enum DischargeInfoError: Error, Sendable, Equatable {
    case notesRequiredWhenReasonIsOther
    case notesExceedMaxLength(Int)
}

extension DischargeInfoError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/discharge-info"
    private static let codePrefix = "DI"

    public var asAppError: AppError {
        switch self {
        case .notesRequiredWhenReasonIsOther:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Observações são obrigatórias quando o motivo do desligamento é 'outro'.",
                bc: Self.bc, module: Self.module, kind: "NotesRequiredWhenReasonIsOther",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-001"],
                    tags: ["vo": "discharge_info"]
                ),
                http: 422
            )
        case .notesExceedMaxLength(let length):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "As observações excedem o limite máximo de 1000 caracteres (informado: \(length)).",
                bc: Self.bc, module: Self.module, kind: "NotesExceedMaxLength",
                context: ["length": AnySendable(length)], safeContext: [:],
                observability: .init(
                    category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-002"],
                    tags: ["vo": "discharge_info"]
                ),
                http: 422
            )
        }
    }
}

// MARK: - Value Object

/// Informações de desligamento de um paciente, incluindo motivo, observações e dados de auditoria.
///
/// Validações:
/// - Quando `reason == .other`, `notes` deve ser não-vazio.
/// - `notes` não pode exceder 1000 caracteres.
public struct DischargeInfo: Sendable, Codable, Equatable {
    public let reason: DischargeReason
    public let notes: String?
    public let dischargedAt: TimeStamp
    public let dischargedBy: String

    public init(reason: DischargeReason, notes: String?, dischargedAt: TimeStamp, dischargedBy: String) throws {
        if reason == .other {
            guard let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DischargeInfoError.notesRequiredWhenReasonIsOther
            }
        }
        if let notes, notes.count > 1000 {
            throw DischargeInfoError.notesExceedMaxLength(notes.count)
        }
        self.reason = reason
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dischargedAt = dischargedAt
        self.dischargedBy = dischargedBy
    }
}
