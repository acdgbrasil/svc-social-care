import Foundation

/// Resultado do cadastro completo da pessoa de referência.
public struct PatientRegistrationResult: Sendable {
    
    public enum RegistrationStatus: String, Sendable {
        case completed = "COMPLETED"
        case pending = "PENDING"
        case failed = "FAILED"
    }

    /// Identificador do prontuário criado.
    public let patientId: String
    
    /// Status atual do registro.
    public let status: RegistrationStatus
    
    /// Instante em que o registro foi processado.
    public let timestamp: Date

    public init(patientId: String, status: RegistrationStatus, timestamp: Date) {
        self.patientId = patientId
        self.status = status
        self.timestamp = timestamp
    }
}
