import Foundation

/// Contrato para o caso de uso de relato de violação de direitos.
public protocol ReportRightsViolationUseCase: ResultCommandHandling where C == ReportRightsViolationCommand {}
