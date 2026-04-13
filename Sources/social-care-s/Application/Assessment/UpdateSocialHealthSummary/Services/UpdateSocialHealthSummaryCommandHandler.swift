import Foundation

public actor UpdateSocialHealthSummaryCommandHandler: UpdateSocialHealthSummaryUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: UpdateSocialHealthSummaryCommand) async throws {
        do {
            let patientId = try PatientId(command.patientId)

            let summary = try SocialHealthSummary(
                requiresConstantCare: command.requiresConstantCare,
                hasMobilityImpairment: command.hasMobilityImpairment,
                functionalDependencies: command.functionalDependencies,
                hasRelevantDrugTherapy: command.hasRelevantDrugTherapy
            )

            guard var patient = try await repository.find(byId: patientId) else {
                throw UpdateSocialHealthSummaryError.patientNotFound
            }

            try patient.updateSocialHealthSummary(summary, actorId: command.actorId)

            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> UpdateSocialHealthSummaryError {
        if let e = error as? UpdateSocialHealthSummaryError { return e }
        if let e = error as? SocialHealthSummaryError {
            switch e {
            case .functionalDependenciesEmpty: return .functionalDependenciesEmpty
            }
        }
        if let e = error as? PatientError {
            switch e {
            case .patientIsWaitlisted:
                return .patientNotActive(reason: "PATIENT_IS_WAITLISTED")
            case .patientIsDischarged:
                return .patientNotActive(reason: "PATIENT_IS_DISCHARGED")
            default:
                return .unexpectedFailure(String(describing: e))
            }
        }
        if let e = error as? PatientIdError {
            switch e { case .invalidFormat(let v): return .invalidPersonIdFormat(v) }
        }
        if let e = error as? PIDError {
            switch e { case .invalidFormat(let v): return .invalidPersonIdFormat(v) }
        }
        return .unexpectedFailure(String(describing: error))
    }
}
