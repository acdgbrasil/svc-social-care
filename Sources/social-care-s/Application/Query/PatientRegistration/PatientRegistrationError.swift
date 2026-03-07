import Foundation

/// Erros do Query Orchestrator de cadastro. Propaga erros dos use cases internos sem expor detalhes de implementação.
public enum PatientRegistrationError: Error, Sendable, Equatable {
    /// Erro ao registrar o paciente (Parte 1 do formulário).
    case registrationFailed(RegisterPatientError)
    /// Erro ao adicionar um membro familiar.
    case familyMemberFailed(memberPersonId: String, underlying: AddFamilyMemberError)
}

extension PatientRegistrationError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/query"

    public var asAppError: AppError {
        switch self {
        case .registrationFailed(let e):
            return e.asAppError
        case .familyMemberFailed(let memberId, let e):
            var base = e.asAppError
            base = AppError(
                code: base.code,
                message: base.message,
                bc: base.bc, module: base.module, kind: base.kind,
                context: base.context.merging(["failedMemberId": AnySendable(memberId)]) { _, new in new },
                safeContext: base.safeContext,
                observability: base.observability,
                http: base.http
            )
            return base
        }
    }
}
