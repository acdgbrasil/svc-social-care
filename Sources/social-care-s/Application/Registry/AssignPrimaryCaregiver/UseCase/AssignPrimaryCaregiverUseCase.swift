import Foundation

/// Contrato para o caso de uso de atribuição de cuidador principal.
public protocol AssignPrimaryCaregiverUseCase: CommandHandling where C == AssignPrimaryCaregiverCommand {}
