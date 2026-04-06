import Foundation

/// Contract for the use case that links a Patient to a canonical PersonId.
public protocol LinkPersonIdUseCase: CommandHandling where C == LinkPersonIdCommand {}
