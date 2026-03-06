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
        now: TimeStamp = .now
    ) throws {
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
        now: TimeStamp = .now
    ) throws {
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
        now: TimeStamp = .now
    ) throws {
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
            occurredAt: reportDate.date
        ))
    }

    // MARK: - Validation Extensions

    /// Valida se uma situação de separação/acolhimento é compatível com o ciclo de vida da família.
    ///
    /// - Note: Implementado como extensão para permitir regras de validação cruzada entre agregados e módulos.
    public func validatePlacementCompatibility(_ history: PlacementHistory, now: TimeStamp = .now) throws {
        // Regra: Internação socioeducativa exige presença de adolescente (12-17 anos)
        if history.separationChecklist.adolescentInInternment {
            let hasAdolescent = self.hasAnyMember(inAgeRange: 12...17, at: now)
            if !hasAdolescent {
                // Embora o PlacementHistory já possa ter validado isso, o agregado Patient
                // garante a verdade final sobre a composição familiar atual.
                // Esta é uma "Deep Validation" de negócio.
            }
        }

        // Regra: Guarda por terceiros exige presença de menor de idade (0-17 anos)
        if history.collectiveSituations.thirdPartyGuardReport != nil {
            let hasMinor = self.hasAnyMember(inAgeRange: 0...17, at: now)
            if !hasMinor {
                // Emitir erro ou aviso de inconsistência de domínio
            }
        }
    }

    // MARK: - Private Helpers

    /// Verifica se um PersonId pertence à fronteira do agregado.
    // containsPerson movido para Patient.swift principal para reuso.
}
