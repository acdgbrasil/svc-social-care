import Foundation
import Vapor
import SQLKit

/// Container de dependências que conecta a camada HTTP aos use cases da Application.
struct ServiceContainer: Sendable {
    let db: any SQLDatabase
    let registerPatient: RegisterPatientCommandHandler
    let addFamilyMember: AddFamilyMemberCommandHandler
    let removeFamilyMember: RemoveFamilyMemberCommandHandler
    let assignPrimaryCaregiver: AssignPrimaryCaregiverCommandHandler
    let updateSocialIdentity: UpdateSocialIdentityCommandHandler
    let updateHousingCondition: UpdateHousingConditionCommandHandler
    let updateSocioEconomicSituation: UpdateSocioEconomicSituationCommandHandler
    let updateWorkAndIncome: UpdateWorkAndIncomeCommandHandler
    let updateEducationalStatus: UpdateEducationalStatusCommandHandler
    let updateHealthStatus: UpdateHealthStatusCommandHandler
    let updateCommunitySupportNetwork: UpdateCommunitySupportNetworkCommandHandler
    let updateSocialHealthSummary: UpdateSocialHealthSummaryCommandHandler
    let updatePlacementHistory: UpdatePlacementHistoryCommandHandler
    let reportRightsViolation: ReportRightsViolationCommandHandler
    let createReferral: CreateReferralCommandHandler
    let registerAppointment: RegisterAppointmentCommandHandler
    let registerIntakeInfo: RegisterIntakeInfoCommandHandler
    let patientRepository: any PatientRepository
    let lookupValidator: any LookupValidating

    init(db: any SQLDatabase) {
        self.db = db
        let repository = SQLKitPatientRepository(db: db)
        let eventBus = OutboxEventBus()
        let lookup = SQLKitLookupRepository(db: db)

        self.patientRepository = repository
        self.lookupValidator = lookup

        self.registerPatient = RegisterPatientCommandHandler(
            repository: repository, eventBus: eventBus, lookupValidator: lookup
        )
        self.addFamilyMember = AddFamilyMemberCommandHandler(
            patientRepository: repository, eventBus: eventBus, lookupValidator: lookup
        )
        self.removeFamilyMember = RemoveFamilyMemberCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.assignPrimaryCaregiver = AssignPrimaryCaregiverCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.updateSocialIdentity = UpdateSocialIdentityCommandHandler(
            repository: repository, lookupValidator: lookup, eventBus: eventBus
        )
        self.updateHousingCondition = UpdateHousingConditionCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.updateSocioEconomicSituation = UpdateSocioEconomicSituationCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.updateWorkAndIncome = UpdateWorkAndIncomeCommandHandler(
            repository: repository, eventBus: eventBus, lookupValidator: lookup
        )
        self.updateEducationalStatus = UpdateEducationalStatusCommandHandler(
            repository: repository, eventBus: eventBus, lookupValidator: lookup
        )
        self.updateHealthStatus = UpdateHealthStatusCommandHandler(
            repository: repository, eventBus: eventBus, lookupValidator: lookup
        )
        self.updateCommunitySupportNetwork = UpdateCommunitySupportNetworkCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.updateSocialHealthSummary = UpdateSocialHealthSummaryCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.updatePlacementHistory = UpdatePlacementHistoryCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.reportRightsViolation = ReportRightsViolationCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.createReferral = CreateReferralCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.registerAppointment = RegisterAppointmentCommandHandler(
            repository: repository, eventBus: eventBus
        )
        self.registerIntakeInfo = RegisterIntakeInfoCommandHandler(
            repository: repository, eventBus: eventBus, lookupValidator: lookup
        )
    }
}

// MARK: - Vapor Storage Key

struct ServiceContainerKey: StorageKey {
    typealias Value = ServiceContainer
}

extension Application {
    var services: ServiceContainer {
        get { self.storage[ServiceContainerKey.self]! }
        set { self.storage[ServiceContainerKey.self] = newValue }
    }
}

extension Request {
    var services: ServiceContainer { self.application.services }
}
