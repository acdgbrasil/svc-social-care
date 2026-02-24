import Foundation

extension Patient {
    
    // MARK: - Core Initializer

    /// Inicializa um novo agregado Patient garantindo a validade dos diagnósticos e registrando o evento de criação.
    ///
    /// - Parameters:
    ///   - id: Identificador único do paciente.
    ///   - personId: Identificador da pessoa.
    ///   - diagnoses: Lista inicial de diagnósticos (obrigatória).
    ///   - now: O instante da criação para fins de auditoria e geração de eventos.
    /// - Throws: `PatientError.initialDiagnosesCantBeEmpty` se a lista de diagnósticos estiver vazia.
    public init(
        id: PatientId,
        personId: PersonId,
        diagnoses: [Diagnosis],
        now: TimeStamp = .now
    ) throws {
        
        guard !diagnoses.isEmpty else {
            throw PatientError.initialDiagnosesCantBeEmpty
        }

        self.id = id
        self.version = 0
        self.personId = personId
        self.diagnoses = diagnoses
        self.uncommittedEvents = []

        self.recordEvent(PatientCreatedEvent(
            patientId: id.description,
            personId: personId.description,
            occurredAt: now.date
        ))
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
