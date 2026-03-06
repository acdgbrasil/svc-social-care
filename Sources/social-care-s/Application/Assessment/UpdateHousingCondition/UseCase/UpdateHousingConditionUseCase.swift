import Foundation

/// Contrato para o caso de uso de atualização das condições de moradia.
public protocol UpdateHousingConditionUseCase: CommandHandling where C == UpdateHousingConditionCommand {}
