import Foundation

struct PatientDatabaseMapper {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Domain → Database

    static func toDatabase(_ patient: Patient) throws -> PatientDatabaseSnapshot {
        let patientId = UUID(uuidString: patient.id.description)!

        let model = try buildPatientModel(patient, patientId: patientId)

        let diagnoses = patient.diagnoses.map { d in
            DiagnosisModel(
                patient_id: patientId,
                icd_code: d.id.value,
                date: d.date.date,
                description: d.description
            )
        }

        let familyMembers = try patient.familyMembers.map { m in
            FamilyMemberModel(
                patient_id: patientId,
                person_id: UUID(uuidString: m.personId.description)!,
                relationship: m.relationshipId.description,
                is_primary_caregiver: m.isPrimaryCaregiver,
                resides_with_patient: m.residesWithPatient,
                has_disability: m.hasDisability,
                required_documents: try encoder.encode(m.requiredDocuments.map { $0.rawValue }),
                birth_date: m.birthDate.date
            )
        }

        let appointments = patient.appointments.map { a in
            AppointmentModel(
                id: UUID(uuidString: a.id.description)!,
                patient_id: patientId,
                date: a.date.date,
                professional_in_charge_id: UUID(uuidString: a.professionalInChargeId.description)!,
                type: a.type.rawValue,
                summary: a.summary,
                action_plan: a.actionPlan
            )
        }

        let referrals = patient.referrals.map { r in
            ReferralModel(
                id: UUID(uuidString: r.id.description)!,
                patient_id: patientId,
                date: r.date.date,
                requesting_professional_id: UUID(uuidString: r.requestingProfessionalId.description)!,
                referred_person_id: UUID(uuidString: r.referredPersonId.description)!,
                destination_service: r.destinationService.rawValue,
                reason: r.reason,
                status: r.status.rawValue
            )
        }

        let reports = patient.violationReports.map { v in
            ViolationReportModel(
                id: UUID(uuidString: v.id.description)!,
                patient_id: patientId,
                report_date: v.reportDate.date,
                incident_date: v.incidentDate?.date,
                victim_id: UUID(uuidString: v.victimId.description)!,
                violation_type: v.violationType.rawValue,
                description_of_fact: v.descriptionOfFact,
                actions_taken: v.actionsTaken
            )
        }

        // Normalized child tables
        let memberIncomes = mapMemberIncomes(patient, patientId: patientId)
        let socialBenefits = mapSocialBenefits(patient, patientId: patientId)
        let educationalProfiles = mapEducationalProfiles(patient, patientId: patientId)
        let programOccurrences = mapProgramOccurrences(patient, patientId: patientId)
        let memberDeficiencies = mapMemberDeficiencies(patient, patientId: patientId)
        let gestatingMembers = mapGestatingMembers(patient, patientId: patientId)
        let placementRegistries = mapPlacementRegistries(patient, patientId: patientId)
        let ingressLinkedPrograms = mapIngressLinkedPrograms(patient, patientId: patientId)

        return PatientDatabaseSnapshot(
            patient: model,
            diagnoses: diagnoses,
            familyMembers: familyMembers,
            appointments: appointments,
            referrals: referrals,
            reports: reports,
            memberIncomes: memberIncomes,
            socialBenefits: socialBenefits,
            educationalProfiles: educationalProfiles,
            programOccurrences: programOccurrences,
            memberDeficiencies: memberDeficiencies,
            gestatingMembers: gestatingMembers,
            placementRegistries: placementRegistries,
            ingressLinkedPrograms: ingressLinkedPrograms
        )
    }

    // MARK: - Database → Domain

    static func toDomain(
        patient: PatientModel,
        diagnoses: [DiagnosisModel],
        familyMembers: [FamilyMemberModel],
        appointments: [AppointmentModel],
        referrals: [ReferralModel],
        reports: [ViolationReportModel],
        memberIncomes: [MemberIncomeModel],
        socialBenefits: [SocialBenefitModel],
        educationalProfiles: [MemberEducationalProfileModel],
        programOccurrences: [ProgramOccurrenceModel],
        memberDeficiencies: [MemberDeficiencyModel],
        gestatingMembers: [GestatingMemberModel],
        placementRegistries: [PlacementRegistryModel],
        ingressLinkedPrograms: [IngressLinkedProgramModel]
    ) throws -> Patient {

        let domainDiagnoses = try diagnoses.map { d in
            try Diagnosis(
                id: try ICDCode(d.icd_code),
                date: try TimeStamp(d.date),
                description: d.description,
                now: .now
            )
        }

        let domainFamily = try familyMembers.map { m in
            let rawDocs = (try? decoder.decode([String].self, from: m.required_documents)) ?? []
            let docs = rawDocs.compactMap { RequiredDocument(rawValue: $0) }
            return try FamilyMember(
                personId: try PersonId(m.person_id.uuidString),
                relationshipId: try LookupId(m.relationship),
                isPrimaryCaregiver: m.is_primary_caregiver,
                residesWithPatient: m.resides_with_patient,
                hasDisability: m.has_disability,
                requiredDocuments: docs,
                birthDate: try TimeStamp(m.birth_date)
            )
        }

        let domainAppointments = try appointments.map { a in
            try SocialCareAppointment(
                id: try AppointmentId(a.id.uuidString),
                date: try TimeStamp(a.date),
                professionalInChargeId: try ProfessionalId(a.professional_in_charge_id.uuidString),
                type: SocialCareAppointment.AppointmentType(rawValue: a.type)!,
                summary: a.summary,
                actionPlan: a.action_plan,
                now: .now
            )
        }

        let domainReferrals = try referrals.map { r in
            try Referral(
                id: try ReferralId(r.id.uuidString),
                date: try TimeStamp(r.date),
                requestingProfessionalId: try ProfessionalId(r.requesting_professional_id.uuidString),
                referredPersonId: try PersonId(r.referred_person_id.uuidString),
                destinationService: Referral.DestinationService(rawValue: r.destination_service)!,
                reason: r.reason,
                status: Referral.Status(rawValue: r.status)!,
                now: .now
            )
        }

        let domainReports = try reports.map { v in
            try RightsViolationReport(
                id: try ViolationReportId(v.id.uuidString),
                reportDate: try TimeStamp(v.report_date),
                incidentDate: try v.incident_date.map { try TimeStamp($0) },
                victimId: try PersonId(v.victim_id.uuidString),
                violationType: RightsViolationReport.ViolationType(rawValue: v.violation_type)!,
                descriptionOfFact: v.description_of_fact,
                actionsTaken: v.actions_taken,
                now: .now
            )
        }

        let personalData = try reconstructPersonalData(from: patient)
        let civilDocuments = try reconstructCivilDocuments(from: patient)
        let address = try reconstructAddress(from: patient)
        let housingCondition = try reconstructHousingCondition(from: patient)
        let socialIdentity = try reconstructSocialIdentity(from: patient)
        let communitySupportNetwork = try reconstructCommunitySupportNetwork(from: patient)
        let socialHealthSummary = try reconstructSocialHealthSummary(from: patient)
        let socioeconomicSituation = try reconstructSocioEconomicSituation(from: patient, socialBenefits: socialBenefits)
        let workAndIncome = try reconstructWorkAndIncome(from: patient, memberIncomes: memberIncomes, socialBenefits: socialBenefits)
        let educationalStatus = try reconstructEducationalStatus(from: patient, profiles: educationalProfiles, occurrences: programOccurrences)
        let healthStatus = try reconstructHealthStatus(from: patient, deficiencies: memberDeficiencies, gestating: gestatingMembers)
        let placementHistory = try reconstructPlacementHistory(from: patient, registries: placementRegistries)
        let intakeInfo = try reconstructIngressInfo(from: patient, programs: ingressLinkedPrograms)

        return Patient.reconstitute(
            id: try PatientId(patient.id.uuidString),
            version: patient.version,
            personId: try PersonId(patient.person_id.uuidString),
            personalData: personalData,
            civilDocuments: civilDocuments,
            address: address,
            diagnoses: domainDiagnoses,
            familyMembers: domainFamily,
            appointments: domainAppointments,
            referrals: domainReferrals,
            violationReports: domainReports,
            housingCondition: housingCondition,
            socioeconomicSituation: socioeconomicSituation,
            workAndIncome: workAndIncome,
            educationalStatus: educationalStatus,
            healthStatus: healthStatus,
            communitySupportNetwork: communitySupportNetwork,
            socialHealthSummary: socialHealthSummary,
            socialIdentity: socialIdentity,
            placementHistory: placementHistory,
            intakeInfo: intakeInfo
        )
    }

    // MARK: - Outbox

    static func toOutbox(_ events: [any DomainEvent]) throws -> [OutboxMessageModel] {
        let encoder = JSONEncoder()
        return try events.map { event in
            let payload = try encoder.encode(AnySendableEvent(event: event))
            return OutboxMessageModel(
                id: event.id,
                event_type: String(describing: type(of: event)),
                payload: payload,
                occurred_at: event.occurredAt,
                processed_at: nil
            )
        }
    }

    private struct AnySendableEvent: Encodable {
        let event: any DomainEvent
        func encode(to encoder: Encoder) throws {
            if let encodableEvent = event as? Encodable {
                try encodableEvent.encode(to: encoder)
            }
        }
    }
}

// MARK: - Snapshot Container

struct PatientDatabaseSnapshot {
    let patient: PatientModel
    let diagnoses: [DiagnosisModel]
    let familyMembers: [FamilyMemberModel]
    let appointments: [AppointmentModel]
    let referrals: [ReferralModel]
    let reports: [ViolationReportModel]
    let memberIncomes: [MemberIncomeModel]
    let socialBenefits: [SocialBenefitModel]
    let educationalProfiles: [MemberEducationalProfileModel]
    let programOccurrences: [ProgramOccurrenceModel]
    let memberDeficiencies: [MemberDeficiencyModel]
    let gestatingMembers: [GestatingMemberModel]
    let placementRegistries: [PlacementRegistryModel]
    let ingressLinkedPrograms: [IngressLinkedProgramModel]
}

// MARK: - Domain → Database (Private Helpers)

private extension PatientDatabaseMapper {

    static func buildPatientModel(_ patient: Patient, patientId: UUID) throws -> PatientModel {
        PatientModel(
            id: patientId,
            person_id: UUID(uuidString: patient.personId.description)!,
            version: patient.version,
            // personal_data
            first_name: patient.personalData?.firstName,
            last_name: patient.personalData?.lastName,
            mother_name: patient.personalData?.motherName,
            nationality: patient.personalData?.nationality,
            sex: patient.personalData?.sex.rawValue,
            social_name: patient.personalData?.socialName,
            birth_date: patient.personalData?.birthDate.date,
            phone: patient.personalData?.phone,
            // civil_documents
            cpf: patient.civilDocuments?.cpf?.value,
            nis: patient.civilDocuments?.nis?.value,
            rg_number: patient.civilDocuments?.rgDocument?.number,
            rg_issuing_state: patient.civilDocuments?.rgDocument?.issuingState,
            rg_issuing_agency: patient.civilDocuments?.rgDocument?.issuingAgency,
            rg_issue_date: patient.civilDocuments?.rgDocument?.issueDate.date,
            // address
            address_cep: patient.address?.cep?.value,
            address_is_shelter: patient.address?.isShelter,
            address_location: patient.address?.residenceLocation.rawValue,
            address_street: patient.address?.street,
            address_neighborhood: patient.address?.neighborhood,
            address_number: patient.address?.number,
            address_complement: patient.address?.complement,
            address_state: patient.address?.state,
            address_city: patient.address?.city,
            // housing_condition
            hc_type: patient.housingCondition?.type.rawValue,
            hc_wall_material: patient.housingCondition?.wallMaterial.rawValue,
            hc_number_of_rooms: patient.housingCondition?.numberOfRooms,
            hc_number_of_bedrooms: patient.housingCondition?.numberOfBedrooms,
            hc_number_of_bathrooms: patient.housingCondition?.numberOfBathrooms,
            hc_water_supply: patient.housingCondition?.waterSupply.rawValue,
            hc_has_piped_water: patient.housingCondition?.hasPipedWater,
            hc_electricity_access: patient.housingCondition?.electricityAccess.rawValue,
            hc_sewage_disposal: patient.housingCondition?.sewageDisposal.rawValue,
            hc_waste_collection: patient.housingCondition?.wasteCollection.rawValue,
            hc_accessibility_level: patient.housingCondition?.accessibilityLevel.rawValue,
            hc_is_in_geographic_risk_area: patient.housingCondition?.isInGeographicRiskArea,
            hc_has_difficult_access: patient.housingCondition?.hasDifficultAccess,
            hc_is_in_social_conflict_area: patient.housingCondition?.isInSocialConflictArea,
            hc_has_diagnostic_observations: patient.housingCondition?.hasDiagnosticObservations,
            // social_identity
            social_identity_type_id: patient.socialIdentity.flatMap { UUID(uuidString: $0.typeId.description) },
            social_identity_other_desc: patient.socialIdentity?.otherDescription,
            // community_support_network
            csn_has_relative_support: patient.communitySupportNetwork?.hasRelativeSupport,
            csn_has_neighbor_support: patient.communitySupportNetwork?.hasNeighborSupport,
            csn_family_conflicts: patient.communitySupportNetwork?.familyConflicts,
            csn_patient_participates_in_groups: patient.communitySupportNetwork?.patientParticipatesInGroups,
            csn_family_participates_in_groups: patient.communitySupportNetwork?.familyParticipatesInGroups,
            csn_patient_has_access_to_leisure: patient.communitySupportNetwork?.patientHasAccessToLeisure,
            csn_faces_discrimination: patient.communitySupportNetwork?.facesDiscrimination,
            // social_health_summary
            shs_requires_constant_care: patient.socialHealthSummary?.requiresConstantCare,
            shs_has_mobility_impairment: patient.socialHealthSummary?.hasMobilityImpairment,
            shs_functional_dependencies: patient.socialHealthSummary.map { try! encoder.encode($0.functionalDependencies) },
            shs_has_relevant_drug_therapy: patient.socialHealthSummary?.hasRelevantDrugTherapy,
            // socioeconomic_situation
            ses_total_family_income: patient.socioeconomicSituation?.totalFamilyIncome,
            ses_income_per_capita: patient.socioeconomicSituation?.incomePerCapita,
            ses_receives_social_benefit: patient.socioeconomicSituation?.receivesSocialBenefit,
            ses_main_source_of_income: patient.socioeconomicSituation?.mainSourceOfIncome,
            ses_has_unemployed: patient.socioeconomicSituation?.hasUnemployed,
            // work_and_income
            wi_has_retired_members: patient.workAndIncome?.hasRetiredMembers,
            // health_status
            hs_food_insecurity: patient.healthStatus?.foodInsecurity,
            hs_constant_care_member_ids: patient.healthStatus.map { try! encoder.encode($0.constantCareNeeds.map { $0.description }) },
            // placement_history
            ph_home_loss_report: patient.placementHistory?.collectiveSituations.homeLossReport,
            ph_third_party_guard_report: patient.placementHistory?.collectiveSituations.thirdPartyGuardReport,
            ph_adult_in_prison: patient.placementHistory?.separationChecklist.adultInPrison,
            ph_adolescent_in_internment: patient.placementHistory?.separationChecklist.adolescentInInternment,
            // ingress_info
            ii_ingress_type_id: patient.intakeInfo.flatMap { UUID(uuidString: $0.ingressTypeId.description) },
            ii_origin_name: patient.intakeInfo?.originName,
            ii_origin_contact: patient.intakeInfo?.originContact,
            ii_service_reason: patient.intakeInfo?.serviceReason
        )
    }

    static func mapMemberIncomes(_ patient: Patient, patientId: UUID) -> [MemberIncomeModel] {
        guard let wi = patient.workAndIncome else { return [] }
        return wi.individualIncomes.map { income in
            MemberIncomeModel(
                id: UUID(),
                patient_id: patientId,
                member_id: UUID(uuidString: income.memberId.description)!,
                occupation_id: UUID(uuidString: income.occupationId.description),
                has_work_card: income.hasWorkCard,
                monthly_amount: income.monthlyAmount
            )
        }
    }

    static func mapSocialBenefits(_ patient: Patient, patientId: UUID) -> [SocialBenefitModel] {
        var models: [SocialBenefitModel] = []

        if let ses = patient.socioeconomicSituation {
            models += ses.socialBenefits.items.map { b in
                SocialBenefitModel(
                    id: UUID(),
                    patient_id: patientId,
                    source: "SOCIOECONOMIC",
                    benefit_name: b.benefitName,
                    amount: b.amount,
                    beneficiary_id: UUID(uuidString: b.beneficiaryId.description)!
                )
            }
        }

        if let wi = patient.workAndIncome {
            models += wi.socialBenefits.map { b in
                SocialBenefitModel(
                    id: UUID(),
                    patient_id: patientId,
                    source: "WORK_AND_INCOME",
                    benefit_name: b.benefitName,
                    amount: b.amount,
                    beneficiary_id: UUID(uuidString: b.beneficiaryId.description)!
                )
            }
        }

        return models
    }

    static func mapEducationalProfiles(_ patient: Patient, patientId: UUID) -> [MemberEducationalProfileModel] {
        guard let es = patient.educationalStatus else { return [] }
        return es.memberProfiles.map { p in
            MemberEducationalProfileModel(
                id: UUID(),
                patient_id: patientId,
                member_id: UUID(uuidString: p.memberId.description)!,
                can_read_write: p.canReadWrite,
                attends_school: p.attendsSchool,
                education_level_id: UUID(uuidString: p.educationLevelId.description)
            )
        }
    }

    static func mapProgramOccurrences(_ patient: Patient, patientId: UUID) -> [ProgramOccurrenceModel] {
        guard let es = patient.educationalStatus else { return [] }
        return es.programOccurrences.map { o in
            ProgramOccurrenceModel(
                id: UUID(),
                patient_id: patientId,
                member_id: UUID(uuidString: o.memberId.description)!,
                date: o.date.date,
                effect_id: UUID(uuidString: o.effectId.description),
                is_suspension_requested: o.isSuspensionRequested
            )
        }
    }

    static func mapMemberDeficiencies(_ patient: Patient, patientId: UUID) -> [MemberDeficiencyModel] {
        guard let hs = patient.healthStatus else { return [] }
        return hs.deficiencies.map { d in
            MemberDeficiencyModel(
                id: UUID(),
                patient_id: patientId,
                member_id: UUID(uuidString: d.memberId.description)!,
                deficiency_type_id: UUID(uuidString: d.deficiencyTypeId.description),
                needs_constant_care: d.needsConstantCare,
                responsible_caregiver_name: d.responsibleCaregiverName
            )
        }
    }

    static func mapGestatingMembers(_ patient: Patient, patientId: UUID) -> [GestatingMemberModel] {
        guard let hs = patient.healthStatus else { return [] }
        return hs.gestatingMembers.map { g in
            GestatingMemberModel(
                id: UUID(),
                patient_id: patientId,
                member_id: UUID(uuidString: g.memberId.description)!,
                months_gestation: g.monthsGestation,
                started_prenatal_care: g.startedPrenatalCare
            )
        }
    }

    static func mapPlacementRegistries(_ patient: Patient, patientId: UUID) -> [PlacementRegistryModel] {
        guard let ph = patient.placementHistory else { return [] }
        return ph.individualPlacements.map { p in
            PlacementRegistryModel(
                id: p.id,
                patient_id: patientId,
                member_id: UUID(uuidString: p.memberId.description)!,
                start_date: p.startDate.date,
                end_date: p.endDate?.date,
                reason: p.reason
            )
        }
    }

    static func mapIngressLinkedPrograms(_ patient: Patient, patientId: UUID) -> [IngressLinkedProgramModel] {
        guard let ii = patient.intakeInfo else { return [] }
        return ii.linkedSocialPrograms.map { lp in
            IngressLinkedProgramModel(
                id: UUID(),
                patient_id: patientId,
                program_id: UUID(uuidString: lp.programId.description),
                observation: lp.observation
            )
        }
    }
}

// MARK: - Database → Domain (Private Helpers)

private extension PatientDatabaseMapper {

    static func reconstructPersonalData(from p: PatientModel) throws -> PersonalData? {
        guard let firstName = p.first_name,
              let lastName = p.last_name,
              let motherName = p.mother_name,
              let nationality = p.nationality,
              let sexRaw = p.sex,
              let sex = PersonalData.Sex(rawValue: sexRaw),
              let birthDate = p.birth_date else { return nil }

        return try PersonalData(
            firstName: firstName,
            lastName: lastName,
            motherName: motherName,
            nationality: nationality,
            sex: sex,
            socialName: p.social_name,
            birthDate: try TimeStamp(birthDate),
            phone: p.phone
        )
    }

    static func reconstructCivilDocuments(from p: PatientModel) throws -> CivilDocuments? {
        let hasCpf = p.cpf != nil
        let hasNis = p.nis != nil
        let hasRg = p.rg_number != nil
        guard hasCpf || hasNis || hasRg else { return nil }

        let cpf = try p.cpf.map { try CPF($0) }
        let nis = try p.nis.map { try NIS($0) }
        let rg: RGDocument? = try {
            guard let number = p.rg_number,
                  let state = p.rg_issuing_state,
                  let agency = p.rg_issuing_agency,
                  let date = p.rg_issue_date else { return nil }
            return try RGDocument(number: number, issuingState: state, issuingAgency: agency, issueDate: try TimeStamp(date))
        }()

        return try CivilDocuments(cpf: cpf, nis: nis, rgDocument: rg)
    }

    static func reconstructAddress(from p: PatientModel) throws -> Address? {
        guard let isShelter = p.address_is_shelter,
              let locationRaw = p.address_location,
              let location = Address.ResidenceLocation(rawValue: locationRaw),
              let state = p.address_state,
              let city = p.address_city else { return nil }

        return try Address(
            cep: p.address_cep,
            isShelter: isShelter,
            residenceLocation: location,
            street: p.address_street,
            neighborhood: p.address_neighborhood,
            number: p.address_number,
            complement: p.address_complement,
            state: state,
            city: city
        )
    }

    static func reconstructHousingCondition(from p: PatientModel) throws -> HousingCondition? {
        guard let typeRaw = p.hc_type,
              let type = HousingCondition.ConditionType(rawValue: typeRaw),
              let wallRaw = p.hc_wall_material,
              let wall = HousingCondition.WallMaterial(rawValue: wallRaw),
              let rooms = p.hc_number_of_rooms,
              let bedrooms = p.hc_number_of_bedrooms,
              let bathrooms = p.hc_number_of_bathrooms,
              let waterRaw = p.hc_water_supply,
              let water = HousingCondition.WaterSupply(rawValue: waterRaw),
              let pipedWater = p.hc_has_piped_water,
              let elecRaw = p.hc_electricity_access,
              let elec = HousingCondition.ElectricityAccess(rawValue: elecRaw),
              let sewageRaw = p.hc_sewage_disposal,
              let sewage = HousingCondition.SewageDisposal(rawValue: sewageRaw),
              let wasteRaw = p.hc_waste_collection,
              let waste = HousingCondition.WasteCollection(rawValue: wasteRaw),
              let accessRaw = p.hc_accessibility_level,
              let access = HousingCondition.AccessibilityLevel(rawValue: accessRaw),
              let geoRisk = p.hc_is_in_geographic_risk_area,
              let difficultAccess = p.hc_has_difficult_access,
              let socialConflict = p.hc_is_in_social_conflict_area,
              let diagObs = p.hc_has_diagnostic_observations else { return nil }

        return try HousingCondition(
            type: type, wallMaterial: wall,
            numberOfRooms: rooms, numberOfBedrooms: bedrooms, numberOfBathrooms: bathrooms,
            waterSupply: water, hasPipedWater: pipedWater,
            electricityAccess: elec, sewageDisposal: sewage, wasteCollection: waste,
            accessibilityLevel: access,
            isInGeographicRiskArea: geoRisk, hasDifficultAccess: difficultAccess,
            isInSocialConflictArea: socialConflict, hasDiagnosticObservations: diagObs
        )
    }

    static func reconstructSocialIdentity(from p: PatientModel) throws -> SocialIdentity? {
        guard let typeId = p.social_identity_type_id else { return nil }
        return try SocialIdentity(
            typeId: try LookupId(typeId.uuidString),
            otherDescription: p.social_identity_other_desc
        )
    }

    static func reconstructCommunitySupportNetwork(from p: PatientModel) throws -> CommunitySupportNetwork? {
        guard let relSupport = p.csn_has_relative_support,
              let neighborSupport = p.csn_has_neighbor_support,
              let conflicts = p.csn_family_conflicts,
              let patGroups = p.csn_patient_participates_in_groups,
              let famGroups = p.csn_family_participates_in_groups,
              let leisure = p.csn_patient_has_access_to_leisure,
              let discrimination = p.csn_faces_discrimination else { return nil }

        return try CommunitySupportNetwork(
            hasRelativeSupport: relSupport,
            hasNeighborSupport: neighborSupport,
            familyConflicts: conflicts,
            patientParticipatesInGroups: patGroups,
            familyParticipatesInGroups: famGroups,
            patientHasAccessToLeisure: leisure,
            facesDiscrimination: discrimination
        )
    }

    static func reconstructSocialHealthSummary(from p: PatientModel) throws -> SocialHealthSummary? {
        guard let constantCare = p.shs_requires_constant_care,
              let mobility = p.shs_has_mobility_impairment,
              let drugTherapy = p.shs_has_relevant_drug_therapy else { return nil }

        let dependencies: [String] = p.shs_functional_dependencies
            .flatMap { try? decoder.decode([String].self, from: $0) } ?? []

        return try SocialHealthSummary(
            requiresConstantCare: constantCare,
            hasMobilityImpairment: mobility,
            functionalDependencies: dependencies,
            hasRelevantDrugTherapy: drugTherapy
        )
    }

    static func reconstructSocioEconomicSituation(
        from p: PatientModel,
        socialBenefits: [SocialBenefitModel]
    ) throws -> SocioEconomicSituation? {
        guard let totalIncome = p.ses_total_family_income,
              let perCapita = p.ses_income_per_capita,
              let receivesBenefit = p.ses_receives_social_benefit,
              let mainSource = p.ses_main_source_of_income,
              let hasUnemployed = p.ses_has_unemployed else { return nil }

        let sesBenefits = socialBenefits.filter { $0.source == "SOCIOECONOMIC" }
        let domainBenefits = try sesBenefits.map { b in
            try SocialBenefit(
                benefitName: b.benefit_name,
                amount: b.amount,
                beneficiaryId: try PersonId(b.beneficiary_id.uuidString)
            )
        }

        return try SocioEconomicSituation(
            totalFamilyIncome: totalIncome,
            incomePerCapita: perCapita,
            receivesSocialBenefit: receivesBenefit,
            socialBenefits: try SocialBenefitsCollection(domainBenefits),
            mainSourceOfIncome: mainSource,
            hasUnemployed: hasUnemployed
        )
    }

    static func reconstructWorkAndIncome(
        from p: PatientModel,
        memberIncomes: [MemberIncomeModel],
        socialBenefits: [SocialBenefitModel]
    ) throws -> WorkAndIncome? {
        guard let hasRetired = p.wi_has_retired_members else { return nil }

        let incomes = try memberIncomes.map { m in
            try WorkIncomeVO(
                memberId: try PersonId(m.member_id.uuidString),
                occupationId: try LookupId((m.occupation_id ?? UUID()).uuidString),
                hasWorkCard: m.has_work_card,
                monthlyAmount: m.monthly_amount
            )
        }

        let wiBenefits = socialBenefits.filter { $0.source == "WORK_AND_INCOME" }
        let domainBenefits = try wiBenefits.map { b in
            try SocialBenefit(
                benefitName: b.benefit_name,
                amount: b.amount,
                beneficiaryId: try PersonId(b.beneficiary_id.uuidString)
            )
        }

        return WorkAndIncome(
            familyId: try PatientId(p.id.uuidString),
            individualIncomes: incomes,
            socialBenefits: domainBenefits,
            hasRetiredMembers: hasRetired
        )
    }

    static func reconstructEducationalStatus(
        from p: PatientModel,
        profiles: [MemberEducationalProfileModel],
        occurrences: [ProgramOccurrenceModel]
    ) throws -> EducationalStatus? {
        guard !profiles.isEmpty || !occurrences.isEmpty else { return nil }

        let domainProfiles = try profiles.map { ep in
            MemberEducationalProfile(
                memberId: try PersonId(ep.member_id.uuidString),
                canReadWrite: ep.can_read_write,
                attendsSchool: ep.attends_school,
                educationLevelId: try LookupId((ep.education_level_id ?? UUID()).uuidString)
            )
        }

        let domainOccurrences = try occurrences.map { o in
            ProgramOccurrence(
                memberId: try PersonId(o.member_id.uuidString),
                date: try TimeStamp(o.date),
                effectId: try LookupId((o.effect_id ?? UUID()).uuidString),
                isSuspensionRequested: o.is_suspension_requested
            )
        }

        return EducationalStatus(
            familyId: try PatientId(p.id.uuidString),
            memberProfiles: domainProfiles,
            programOccurrences: domainOccurrences
        )
    }

    static func reconstructHealthStatus(
        from p: PatientModel,
        deficiencies: [MemberDeficiencyModel],
        gestating: [GestatingMemberModel]
    ) throws -> HealthStatus? {
        guard p.hs_food_insecurity != nil else { return nil }

        let domainDeficiencies = try deficiencies.map { d in
            MemberDeficiency(
                memberId: try PersonId(d.member_id.uuidString),
                deficiencyTypeId: try LookupId((d.deficiency_type_id ?? UUID()).uuidString),
                needsConstantCare: d.needs_constant_care,
                responsibleCaregiverName: d.responsible_caregiver_name
            )
        }

        let domainGestating = try gestating.map { g in
            PregnantMember(
                memberId: try PersonId(g.member_id.uuidString),
                monthsGestation: g.months_gestation,
                startedPrenatalCare: g.started_prenatal_care
            )
        }

        let careIds: [PersonId] = {
            guard let data = p.hs_constant_care_member_ids,
                  let ids = try? decoder.decode([String].self, from: data) else { return [] }
            return ids.compactMap { try? PersonId($0) }
        }()

        return HealthStatus(
            familyId: try PatientId(p.id.uuidString),
            deficiencies: domainDeficiencies,
            gestatingMembers: domainGestating,
            constantCareNeeds: careIds,
            foodInsecurity: p.hs_food_insecurity!
        )
    }

    static func reconstructPlacementHistory(
        from p: PatientModel,
        registries: [PlacementRegistryModel]
    ) throws -> PlacementHistory? {
        let hasScalars = p.ph_adult_in_prison != nil
        guard hasScalars || !registries.isEmpty else { return nil }

        let domainRegistries = try registries.map { r in
            try PlacementRegistry(
                id: r.id,
                memberId: try PersonId(r.member_id.uuidString),
                startDate: try TimeStamp(r.start_date),
                endDate: try r.end_date.map { try TimeStamp($0) },
                reason: r.reason
            )
        }

        return PlacementHistory(
            familyId: try PatientId(p.id.uuidString),
            individualPlacements: domainRegistries,
            collectiveSituations: CollectiveSituations(
                homeLossReport: p.ph_home_loss_report,
                thirdPartyGuardReport: p.ph_third_party_guard_report
            ),
            separationChecklist: SeparationChecklist(
                adultInPrison: p.ph_adult_in_prison ?? false,
                adolescentInInternment: p.ph_adolescent_in_internment ?? false
            )
        )
    }

    static func reconstructIngressInfo(
        from p: PatientModel,
        programs: [IngressLinkedProgramModel]
    ) throws -> IngressInfo? {
        guard let typeId = p.ii_ingress_type_id,
              let reason = p.ii_service_reason else { return nil }

        let domainPrograms = try programs.map { lp in
            ProgramLink(
                programId: try LookupId((lp.program_id ?? UUID()).uuidString),
                observation: lp.observation
            )
        }

        return try IngressInfo(
            ingressTypeId: try LookupId(typeId.uuidString),
            originName: p.ii_origin_name,
            originContact: p.ii_origin_contact,
            serviceReason: reason,
            linkedSocialPrograms: domainPrograms
        )
    }
}
