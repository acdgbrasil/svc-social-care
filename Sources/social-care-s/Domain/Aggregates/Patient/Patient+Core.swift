import Foundation

extension Patient {
    
    // MARK: - Core Factory Methods

    /// Cria um novo agregado Patient.
    ///
    /// - Parameters:
    ///   - id: Identificador único do paciente.
    ///   - personId: Identificador da pessoa.
    ///   - diagnoses: Lista inicial de diagnósticos (obrigatória).
    ///   - now: Data de criação para o evento.
    /// - Returns: Uma nova instância de `Patient`.
    /// - Throws: `PatientErrors.initialDiagnosesCantBeEmpty` se a lista de diagnósticos estiver vazia.
    public static func create(
        id: PatientId,
        personId: PersonId,
        diagnoses: [Diagnosis],
        now: Date = Date()
    ) throws -> Patient {
        
        guard !diagnoses.isEmpty else {
            throw PatientError.initialDiagnosesCantBeEmpty
        }

        var patient = Patient(
            id: id,
            version: 0,
            personId: personId,
            diagnoses: diagnoses
        )

        patient.recordEvent(PatientCreatedEvent(
            patientId: id.description,
            personId: personId.description,
            occurredAt: now
        ))

        return patient
    }

    /// Reconstitui um agregado a partir de um estado persistido.
    public static func reconstitute(
        id: PatientId,
        version: Int,
        personId: PersonId,
        diagnoses: [Diagnosis],
        familyMembers: [FamilyMember] = [],
        appointments: [SocialCareAppointment] = [],
        referrals: [Referral] = [],
        violationReports: [RightsViolationReport] = [],
        housingCondition: HousingCondition? = nil,
        socioeconomicSituation: SocioEconomicSituation? = nil,
        communitySupportNetwork: CommunitySupportNetwork? = nil,
        socialHealthSummary: SocialHealthSummary? = nil
    ) -> Patient {
        var patient = Patient(
            id: id,
            version: version,
            personId: personId,
            diagnoses: diagnoses
        )
        
        // Atribuição direta via mutação interna
        patient.familyMembers = familyMembers
        patient.appointments = appointments
        patient.referrals = referrals
        patient.violationReports = violationReports
        patient.housingCondition = housingCondition
        patient.socioeconomicSituation = socioeconomicSituation
        patient.communitySupportNetwork = communitySupportNetwork
        patient.socialHealthSummary = socialHealthSummary
        
        return patient
    }
}
