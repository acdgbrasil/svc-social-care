import Foundation

/// Responsável por converter entre o Agregado de Domínio e os Modelos de Banco de Dados.
struct PatientDatabaseMapper {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    /// Converte o Agregado Patient para os modelos relacionais.
    static func toDatabase(_ patient: Patient) throws -> (
        patient: PatientModel,
        diagnoses: [DiagnosisModel],
        familyMembers: [FamilyMemberModel],
        appointments: [AppointmentModel],
        referrals: [ReferralModel],
        reports: [ViolationReportModel]
    ) {
        let patientId = UUID(uuidString: patient.id.description)!
        
        let model = try PatientModel(
            id: patientId,
            person_id: UUID(uuidString: patient.personId.description)!,
            version: patient.version,
            housing_condition: patient.housingCondition.map { try encoder.encode($0) },
            socioeconomic_situation: patient.socioeconomicSituation.map { try encoder.encode($0) },
            community_support_network: patient.communitySupportNetwork.map { try encoder.encode($0) },
            social_health_summary: patient.socialHealthSummary.map { try encoder.encode($0) }
        )
        
        let diagnoses = patient.diagnoses.map { d in
            DiagnosisModel(
                patient_id: patientId,
                icd_code: d.id.value,
                date: d.date.date,
                description: d.description
            )
        }
        
        let familyMembers = patient.familyMembers.map { m in
            FamilyMemberModel(
                patient_id: patientId,
                person_id: UUID(uuidString: m.personId.description)!,
                relationship: m.relationship,
                is_primary_caregiver: m.isPrimaryCaregiver,
                resides_with_patient: m.residesWithPatient
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
        
        return (model, diagnoses, familyMembers, appointments, referrals, reports)
    }

    /// Converte eventos de domínio para o modelo de persistência do Outbox.
    static func toOutbox(_ events: [any DomainEvent]) throws -> [OutboxMessageModel] {
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

    /// Wrapper para permitir codificação de 'any DomainEvent'
    private struct AnySendableEvent: Encodable {
        let event: any DomainEvent
        func encode(to encoder: Encoder) throws {
            // Como DomainEvent não é Encodable diretamente (apenas protocolos que assinam),
            // em um sistema real usaríamos um Registry de eventos ou Type Erasure mais complexo.
            // Para SQLKit, assumimos que as structs de evento assinam Encodable.
            if let encodableEvent = event as? Encodable {
                try encodableEvent.encode(to: encoder)
            }
        }
    }

    /// Reconstitui o Agregado Patient a partir dos dados do banco.
    static func toDomain(
        patient: PatientModel,
        diagnoses: [DiagnosisModel],
        familyMembers: [FamilyMemberModel],
        appointments: [AppointmentModel],
        referrals: [ReferralModel],
        reports: [ViolationReportModel]
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
            try FamilyMember(
                personId: try PersonId(m.person_id.uuidString),
                relationship: m.relationship,
                isPrimaryCaregiver: m.is_primary_caregiver,
                residesWithPatient: m.resides_with_patient
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
            // Reconstituição de Referral é complexa pois o init valida.
            // Para persistência, o ideal é ter um método 'reconstitute' ou similar se disponível.
            // Vou usar o init público assumindo que os dados no banco já foram validados.
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

        return Patient.reconstitute(
            id: try PatientId(patient.id.uuidString),
            version: patient.version,
            personId: try PersonId(patient.person_id.uuidString),
            diagnoses: domainDiagnoses,
            familyMembers: domainFamily,
            appointments: domainAppointments,
            referrals: domainReferrals,
            violationReports: domainReports,
            housingCondition: try patient.housing_condition.map { try decoder.decode(HousingCondition.self, from: $0) },
            socioeconomicSituation: try patient.socioeconomic_situation.map { try decoder.decode(SocioEconomicSituation.self, from: $0) },
            communitySupportNetwork: try patient.community_support_network.map { try decoder.decode(CommunitySupportNetwork.self, from: $0) },
            socialHealthSummary: try patient.social_health_summary.map { try decoder.decode(SocialHealthSummary.self, from: $0) }
        )
    }
}
