import Foundation

// MARK: - Errors

public enum WithdrawInfoError: Error, Sendable, Equatable {
    case notesRequiredWhenReasonIsOther
    case notesExceedMaxLength(Int)
}

extension WithdrawInfoError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/withdraw-info"
    private static let codePrefix = "WI"

    public var asAppError: AppError {
        switch self {
        case .notesRequiredWhenReasonIsOther:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Observações são obrigatórias quando o motivo da desistência é 'outro'.",
                bc: Self.bc, module: Self.module, kind: "NotesRequiredWhenReasonIsOther",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-001"],
                    tags: ["vo": "withdraw_info"]
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
                    tags: ["vo": "withdraw_info"]
                ),
                http: 422
            )
        }
    }
}

// MARK: - Value Object

/// Informações de desistência/retirada de um paciente da lista de espera, incluindo motivo, observações e dados de auditoria.
///
/// Validações:
/// - Quando `reason == .other`, `notes` deve ser não-vazio.
/// - `notes` não pode exceder 1000 caracteres.
public struct WithdrawInfo: Sendable, Codable, Equatable {
    public let reason: WithdrawReason
    public let notes: String?
    public let withdrawnAt: TimeStamp
    public let withdrawnBy: String

    public init(reason: WithdrawReason, notes: String?, withdrawnAt: TimeStamp, withdrawnBy: String) throws {
        if reason == .other {
            guard let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WithdrawInfoError.notesRequiredWhenReasonIsOther
            }
        }
        if let notes, notes.count > 1000 {
            throw WithdrawInfoError.notesExceedMaxLength(notes.count)
        }
        self.reason = reason
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.withdrawnAt = withdrawnAt
        self.withdrawnBy = withdrawnBy
    }
}
