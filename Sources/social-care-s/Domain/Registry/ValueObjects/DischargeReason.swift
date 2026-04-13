import Foundation

/// Motivos padronizados para o desligamento formal de um paciente do acompanhamento social.
public enum DischargeReason: String, Sendable, Codable, Equatable, CaseIterable {
    case caseObjectiveAchieved
    case transferredToAnotherService
    case patientRequestedDischarge
    case lossOfContact
    case relocation
    case death
    case other
}
