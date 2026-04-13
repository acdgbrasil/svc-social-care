import Foundation

/// Status do ciclo de vida do paciente no sistema de acompanhamento social.
public enum PatientStatus: String, Sendable, Codable, Equatable {
    case active
    case discharged
}
