import Foundation

/// Contrato para o caso de uso de remoção de membro familiar.
public protocol RemoveFamilyMemberUseCase: CommandHandling where C == RemoveFamilyMemberCommand {}
