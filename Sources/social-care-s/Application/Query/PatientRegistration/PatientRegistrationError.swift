import Foundation

/// Erros do Query Orchestrator de cadastro. Propaga erros dos use cases internos sem expor detalhes de implementação.
public enum PatientRegistrationError: Error, Sendable {
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
            let base = e.asAppError
            _ = memberId // contexto disponível para enriquecimento futuro
            return base
        }
    }
}
