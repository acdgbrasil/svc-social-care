import Foundation

extension Patient {

    // MARK: - Interventions

    /// Adiciona um novo atendimento socioassistencial ao histórico.
    public mutating func addAppointment(
        id: AppointmentId,
        date: TimeStamp,
        professionalInChargeId: ProfessionalId,
        type: SocialCareAppointment.AppointmentType,
        summary: String,
        actionPlan: String,
        actorId: String,
        now: TimeStamp = .now
    ) throws {
        try requireActive()
        let appointment = try SocialCareAppointment(
            id: id,
            date: date,
            professionalInChargeId: professionalInChargeId,
            type: type,
            summary: summary,
            actionPlan: actionPlan,
            now: now
        )
        self.appointments.append(appointment)

        self.recordEvent(SocialCareAppointmentRegisteredEvent(
            patientId: self.id.description,
            appointmentId: id.description,
            professionalInChargeId: professionalInChargeId.description,
            type: type.rawValue,
            actorId: actorId,
            occurredAt: date.date
        ))
    }

    /// Adiciona um novo encaminhamento para o paciente ou membro da família.
    ///
    /// - Throws: `PatientError.referralTargetOutsideBoundary` se a pessoa encaminhada não pertencer ao agregado.
    public mutating func addReferral(
        id: ReferralId,
        date: TimeStamp,
        requestingProfessionalId: ProfessionalId,
        referredPersonId: PersonId,
        destinationService: Referral.DestinationService,
        reason: String,
        actorId: String,
        now: TimeStamp = .now
    ) throws {
        try requireActive()
        // Regra de Integridade: O alvo do encaminhamento deve ser o titular ou um membro da família.
        guard self.containsPerson(referredPersonId) else {
            throw PatientError.referralTargetOutsideBoundary(targetId: referredPersonId.description)
        }

        let referral = try Referral(
            id: id,
            date: date,
            requestingProfessionalId: requestingProfessionalId,
            referredPersonId: referredPersonId,
            destinationService: destinationService,
            reason: reason,
            now: now
        )
        self.referrals.append(referral)

        self.recordEvent(ReferralCreatedEvent(
            patientId: self.id.description,
            referralId: id.description,
            referredPersonId: referredPersonId.description,
            destinationService: destinationService.rawValue,
            status: referral.status.rawValue,
            actorId: actorId,
            occurredAt: date.date
        ))
    }

    /// Registra um relato de violação de direitos.
    ///
    /// - Throws: `PatientError.violationTargetOutsideBoundary` se a vítima não pertencer ao agregado.
    public mutating func addRightsViolationReport(
        id: ViolationReportId,
        reportDate: TimeStamp,
        incidentDate: TimeStamp?,
        victimId: PersonId,
        violationType: RightsViolationReport.ViolationType,
        descriptionOfFact: String,
        actionsTaken: String,
        actorId: String,
        now: TimeStamp = .now
    ) throws {
        try requireActive()
        // Regra de Integridade: A vítima deve pertencer à família atendida.
        guard self.containsPerson(victimId) else {
            throw PatientError.violationTargetOutsideBoundary(targetId: victimId.description)
        }

        let report = try RightsViolationReport(
            id: id,
            reportDate: reportDate,
            incidentDate: incidentDate,
            victimId: victimId,
            violationType: violationType,
            descriptionOfFact: descriptionOfFact,
            actionsTaken: actionsTaken,
            now: now
        )
        self.violationReports.append(report)

        self.recordEvent(RightsViolationReportedEvent(
            patientId: self.id.description,
            reportId: id.description,
            victimId: victimId.description,
            violationType: violationType.rawValue,
            actorId: actorId,
            occurredAt: reportDate.date
        ))
    }

    // MARK: - Validation Extensions

    /// Valida se uma situação de separação/acolhimento é compatível com o ciclo de vida da família.
    ///
    /// - Parameter history: O histórico de acolhimento a ser validado.
    /// - Parameter now: Data de referência para cálculo de idade.
    /// - Throws: `PatientError.incompatiblePlacementSituation` ou `.incompatibleGuardianshipSituation`.
    public func validatePlacementCompatibility(_ history: PlacementHistory, now: TimeStamp = .now) throws {
        if history.separationChecklist.adolescentInInternment {
            let hasAdolescent = self.hasAnyMember(inAgeRange: 12...17, at: now)
            if !hasAdolescent {
                throw PatientError.incompatiblePlacementSituation
            }
        }

        if history.collectiveSituations.thirdPartyGuardReport != nil {
            let hasMinor = self.hasAnyMember(inAgeRange: 0...17, at: now)
            if !hasMinor {
                throw PatientError.incompatibleGuardianshipSituation
            }
        }
    }
}
