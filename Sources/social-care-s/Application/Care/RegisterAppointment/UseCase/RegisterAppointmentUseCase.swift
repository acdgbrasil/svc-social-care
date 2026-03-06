import Foundation

/// Contrato para o caso de uso de registro de atendimento.
public protocol RegisterAppointmentUseCase: ResultCommandHandling where C == RegisterAppointmentCommand {}
