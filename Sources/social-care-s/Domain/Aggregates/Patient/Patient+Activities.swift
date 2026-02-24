import Foundation

extension Patient {
    
    // MARK: - Activity Management

    /// Registra um novo encaminhamento para o paciente ou membro da família.
    ///
    /// - Throws: `PatientError.referralTargetOutsideBoundary` se a pessoa não pertencer ao agregado.
    public mutating func createReferral(
        id: ReferralId,
        date: TimeStamp,
        requestingProfessionalId: ProfessionalId,
        referredPersonId: PersonId,
        destinationService: Referral.DestinationService,
        reason: String,
        status: Referral.Status = .pending,
        now: TimeStamp
    ) throws {
        
        guard belongsToBoundary(referredPersonId) else {
            throw PatientError.referralTargetOutsideBoundary(targetId: referredPersonId.description)
        }

        let referral = try Referral.create(
            id: id,
            date: date,
            requestingProfessionalId: requestingProfessionalId,
            referredPersonId: referredPersonId,
            destinationService: destinationService,
            reason: reason,
            status: status,
            now: now
        )

        self.referrals.append(referral)
        
        self.recordEvent(ReferralCreatedEvent(
            patientId: self.id.description,
            referralId: referral.id.description,
            referredPersonId: referral.referredPersonId.description,
            destinationService: referral.destinationService.rawValue,
            status: referral.status.rawValue,
            occurredAt: now.date
        ))
    }

    /// Registra uma denúncia de violação de direitos ocorrida dentro da fronteira do agregado.
    public mutating func reportRightsViolation(
        id: ViolationReportId,
        reportDate: TimeStamp,
        incidentDate: TimeStamp?,
        victimId: PersonId,
        violationType: RightsViolationReport.ViolationType,
        descriptionOfFact: String,
        actionsTaken: String,
        now: TimeStamp
    ) throws {
        
        guard belongsToBoundary(victimId) else {
            throw PatientError.violationTargetOutsideBoundary(targetId: victimId.description)
        }

        let violation = try RightsViolationReport.create(
            id: id,
            reportDate: reportDate,
            incidentDate: incidentDate,
            victimId: victimId,
            violationType: violationType,
            descriptionOfFact: descriptionOfFact,
            actionsTaken: actionsTaken,
            now: now
        )

        self.violationReports.append(violation)
        
        self.recordEvent(RightsViolationReportedEvent(
            patientId: self.id.description,
            reportId: violation.id.description,
            victimId: violation.victimId.description,
            violationType: violation.violationType.rawValue,
            occurredAt: now.date
        ))
    }

    /// Registra um atendimento clínico para o paciente.
    public mutating func registerAppointment(
        id: AppointmentId,
        date: TimeStamp,
        professionalInChargeId: ProfessionalId,
        type: SocialCareAppointment.AppointmentType,
        summary: String,
        actionPlan: String,
        now: TimeStamp
    ) throws {
        
        let appointment = try SocialCareAppointment.create(
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
            appointmentId: appointment.id.description,
            professionalInChargeId: appointment.professionalInChargeId.description,
            type: appointment.type.rawValue,
            occurredAt: now.date
        ))
    }

    // MARK: - Private Helpers
    
    /// Verifica se um PersonId pertence à fronteira do agregado.
    private func belongsToBoundary(_ targetId: PersonId) -> Bool {
        if self.personId == targetId { return true }
        return familyMembers.contains { $0.personId == targetId }
    }
}
