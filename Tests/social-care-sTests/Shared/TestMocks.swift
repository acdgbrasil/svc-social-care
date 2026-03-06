import Foundation
import SQLKit
@testable import social_care_s

// MARK: - Use Case Mocks

public actor MockRegisterUseCase: RegisterPatientUseCase {
    public init() {}
    public func handle(_ command: RegisterPatientCommand) async throws -> String { return "" }
}
public actor MockAddFamilyUseCase: AddFamilyMemberUseCase {
    public init() {}
    public func handle(_ command: AddFamilyMemberCommand) async throws {}
}
public actor MockRemoveFamilyUseCase: RemoveFamilyMemberUseCase {
    public init() {}
    public func handle(_ command: RemoveFamilyMemberCommand) async throws {}
}
public actor MockUpdateIdentityUseCase: UpdateSocialIdentityUseCase {
    public init() {}
    public func handle(_ command: UpdateSocialIdentityCommand) async throws {}
}
public struct MockIntakeUseCase: PatientRegistering {
    public init() {}
    public func register(request: PatientRegistrationRequest) async throws -> PatientRegistrationResult { 
        return .init(patientId: "", status: .completed, timestamp: Date()) 
    }
}
public actor MockHousingUseCase: UpdateHousingConditionUseCase {
    public init() {}
    public func handle(_ command: UpdateHousingConditionCommand) async throws {}
}
public actor MockSocioUseCase: UpdateSocioEconomicSituationUseCase {
    public init() {}
    public func handle(_ command: UpdateSocioEconomicSituationCommand) async throws {}
}
public actor MockEducationUseCase: UpdateEducationalStatusUseCase {
    public init() {}
    public func handle(_ command: UpdateEducationalStatusCommand) async throws {}
}
public actor MockHealthUseCase: UpdateHealthStatusUseCase {
    public init() {}
    public func handle(_ command: UpdateHealthStatusCommand) async throws {}
}
public actor MockReferralUseCase: CreateReferralUseCase {
    private let resultId: String
    public init(resultId: String = "") { self.resultId = resultId }
    public func handle(_ command: CreateReferralCommand) async throws -> String { return resultId }
}
public actor MockViolationUseCase: ReportRightsViolationUseCase {
    private let resultId: String
    public init(resultId: String = "") { self.resultId = resultId }
    public func handle(_ command: ReportRightsViolationCommand) async throws -> String { return resultId }
}
public actor MockPlacementUseCase: UpdatePlacementHistoryUseCase {
    public init() {}
    public func handle(_ command: UpdatePlacementHistoryCommand) async throws {}
}
public actor MockAppointmentUseCase: RegisterAppointmentUseCase {
    public init() {}
    public func handle(_ command: RegisterAppointmentCommand) async throws -> String { return "" }
}
public actor MockIntakeInfoUseCase: RegisterIntakeInfoUseCase {
    public init() {}
    public func handle(_ command: RegisterIntakeInfoCommand) async throws {}
}

// MARK: - Repository Mock

public struct MockRepoEmpty: PatientRepository {
    public init() {}
    public func save(_ patient: Patient) async throws {}
    public func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
    public func find(byPersonId personId: PersonId) async throws -> Patient? { return nil }
    public func find(byId id: PatientId) async throws -> Patient? { return nil }
}
