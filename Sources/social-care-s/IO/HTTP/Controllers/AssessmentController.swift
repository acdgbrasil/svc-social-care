import Vapor

struct AssessmentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let patient = routes.grouped("api", "v1", "patients", ":patientId")
            .grouped(RoleGuardMiddleware("social_worker"))

        patient.put("housing-condition", use: updateHousingCondition)
        patient.put("socioeconomic-situation", use: updateSocioEconomicSituation)
        patient.put("work-and-income", use: updateWorkAndIncome)
        patient.put("educational-status", use: updateEducationalStatus)
        patient.put("health-status", use: updateHealthStatus)
        patient.put("community-support-network", use: updateCommunitySupportNetwork)
        patient.put("social-health-summary", use: updateSocialHealthSummary)
    }

    @Sendable
    private func updateHousingCondition(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateHousingConditionRequest.self)
        let command = UpdateHousingConditionCommand(
            patientId: patientId,
            condition: .init(
                type: body.type, wallMaterial: body.wallMaterial,
                numberOfRooms: body.numberOfRooms, numberOfBedrooms: body.numberOfBedrooms,
                numberOfBathrooms: body.numberOfBathrooms, waterSupply: body.waterSupply,
                hasPipedWater: body.hasPipedWater, electricityAccess: body.electricityAccess,
                sewageDisposal: body.sewageDisposal, wasteCollection: body.wasteCollection,
                accessibilityLevel: body.accessibilityLevel,
                isInGeographicRiskArea: body.isInGeographicRiskArea,
                hasDifficultAccess: body.hasDifficultAccess,
                isInSocialConflictArea: body.isInSocialConflictArea,
                hasDiagnosticObservations: body.hasDiagnosticObservations
            ),
            actorId: actorId
        )
        try await req.services.updateHousingCondition.handle(command)
        return .noContent
    }

    @Sendable
    private func updateSocioEconomicSituation(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateSocioEconomicSituationRequest.self)

        let validator = MetadataValidator(db: req.services.db)
        try await validator.validateBenefits(body.socialBenefits)

        let command = UpdateSocioEconomicSituationCommand(
            patientId: patientId,
            situation: .init(
                totalFamilyIncome: body.totalFamilyIncome,
                incomePerCapita: body.incomePerCapita,
                receivesSocialBenefit: body.receivesSocialBenefit,
                socialBenefits: body.socialBenefits.map {
                    .init(benefitName: $0.benefitName, amount: $0.amount, beneficiaryId: $0.beneficiaryId)
                },
                mainSourceOfIncome: body.mainSourceOfIncome,
                hasUnemployed: body.hasUnemployed
            ),
            actorId: actorId
        )
        try await req.services.updateSocioEconomicSituation.handle(command)
        return .noContent
    }

    @Sendable
    private func updateWorkAndIncome(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateWorkAndIncomeRequest.self)

        let validator = MetadataValidator(db: req.services.db)
        try await validator.validateWorkBenefits(body.socialBenefits)

        let command = UpdateWorkAndIncomeCommand(
            patientId: patientId,
            individualIncomes: body.individualIncomes.map {
                .init(memberId: $0.memberId, occupationId: $0.occupationId,
                      hasWorkCard: $0.hasWorkCard, monthlyAmount: $0.monthlyAmount)
            },
            socialBenefits: body.socialBenefits.map {
                .init(benefitName: $0.benefitName, amount: $0.amount, beneficiaryId: $0.beneficiaryId)
            },
            hasRetiredMembers: body.hasRetiredMembers,
            actorId: actorId
        )
        try await req.services.updateWorkAndIncome.handle(command)
        return .noContent
    }

    @Sendable
    private func updateEducationalStatus(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateEducationalStatusRequest.self)
        let command = UpdateEducationalStatusCommand(
            patientId: patientId,
            memberProfiles: body.memberProfiles.map {
                .init(memberId: $0.memberId, canReadWrite: $0.canReadWrite,
                      attendsSchool: $0.attendsSchool, educationLevelId: $0.educationLevelId)
            },
            programOccurrences: body.programOccurrences.map {
                .init(memberId: $0.memberId, date: $0.date,
                      effectId: $0.effectId, isSuspensionRequested: $0.isSuspensionRequested)
            },
            actorId: actorId
        )
        try await req.services.updateEducationalStatus.handle(command)
        return .noContent
    }

    @Sendable
    private func updateHealthStatus(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateHealthStatusRequest.self)

        if !body.gestatingMembers.isEmpty {
            guard let pid = try? PatientId(patientId),
                  let patient = try await req.services.patientRepository.find(byId: pid) else {
                throw Abort(.notFound, reason: "Patient not found.")
            }
            let validator = CrossValidator(patient: patient)
            try validator.validateGestatingMembers(body.gestatingMembers.map { $0.memberId })
        }

        let command = UpdateHealthStatusCommand(
            patientId: patientId,
            deficiencies: body.deficiencies.map {
                .init(memberId: $0.memberId, deficiencyTypeId: $0.deficiencyTypeId,
                      needsConstantCare: $0.needsConstantCare,
                      responsibleCaregiverName: $0.responsibleCaregiverName)
            },
            gestatingMembers: body.gestatingMembers.map {
                .init(memberId: $0.memberId, monthsGestation: $0.monthsGestation,
                      startedPrenatalCare: $0.startedPrenatalCare)
            },
            constantCareNeeds: body.constantCareNeeds,
            foodInsecurity: body.foodInsecurity,
            actorId: actorId
        )
        try await req.services.updateHealthStatus.handle(command)
        return .noContent
    }

    @Sendable
    private func updateCommunitySupportNetwork(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateCommunitySupportNetworkRequest.self)
        let command = UpdateCommunitySupportNetworkCommand(
            patientId: patientId,
            hasRelativeSupport: body.hasRelativeSupport,
            hasNeighborSupport: body.hasNeighborSupport,
            familyConflicts: body.familyConflicts,
            patientParticipatesInGroups: body.patientParticipatesInGroups,
            familyParticipatesInGroups: body.familyParticipatesInGroups,
            patientHasAccessToLeisure: body.patientHasAccessToLeisure,
            facesDiscrimination: body.facesDiscrimination,
            actorId: actorId
        )
        try await req.services.updateCommunitySupportNetwork.handle(command)
        return .noContent
    }

    @Sendable
    private func updateSocialHealthSummary(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(UpdateSocialHealthSummaryRequest.self)
        let command = UpdateSocialHealthSummaryCommand(
            patientId: patientId,
            requiresConstantCare: body.requiresConstantCare,
            hasMobilityImpairment: body.hasMobilityImpairment,
            functionalDependencies: body.functionalDependencies,
            hasRelevantDrugTherapy: body.hasRelevantDrugTherapy,
            actorId: actorId
        )
        try await req.services.updateSocialHealthSummary.handle(command)
        return .noContent
    }
}
