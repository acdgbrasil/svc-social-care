import Foundation

/// Contrato para o caso de uso de atualização da identidade social da família.
public protocol UpdateSocialIdentityUseCase: CommandHandling where C == UpdateSocialIdentityCommand {}
