import Foundation

extension Patient {

    // MARK: - Lifecycle & Factory

    /// Inicializa um novo agregado `Patient` com validações de integridade v2.0.
    ///
    /// - Parameters:
    ///   - id: Identificador único do prontuário.
    ///   - personId: Identificador global da pessoa titular.
    ///   - personalData: Dados de identificação civil.
    ///   - civilDocuments: Documentos agrupados (CPF, NIS, RG).
    ///   - address: Endereço principal.
    ///   - diagnoses: Lista inicial de diagnósticos (obrigatória).
    ///   - familyMembers: Lista de membros da família.
    ///   - prRelationshipId: O identificador de lookup que define a Pessoa de Referência (PR).
    ///   - now: Instante da criação para fins de auditoria.
    /// - Throws: `PatientError.initialDiagnosesCantBeEmpty` ou erros de PR.
    public init(
        id: PatientId,
        personId: PersonId,
        personalData: PersonalData? = nil,
        civilDocuments: CivilDocuments? = nil,
        address: Address? = nil,
        diagnoses: [Diagnosis],
        familyMembers: [FamilyMember] = [],
        prRelationshipId: LookupId,
        actorId: String,
        now: TimeStamp = .now
    ) throws {

        guard !diagnoses.isEmpty else {
            throw PatientError.initialDiagnosesCantBeEmpty
        }

        // Validação Versão 2.0: Exatamente uma Pessoa de Referência (PR)
        let prCount = familyMembers.filter { $0.relationshipId == prRelationshipId }.count
        guard prCount == 1 else {
            if prCount == 0 { throw PatientError.mustHaveExactlyOnePrimaryReference }
            throw PatientError.multiplePrimaryReferencesNotAllowed
        }

        self = Patient(
            id: id,
            version: 0,
            personId: personId,
            personalData: personalData,
            civilDocuments: civilDocuments,
            address: address,
            diagnoses: diagnoses
        )
        self.familyMembers = familyMembers

        self.recordEvent(PatientCreatedEvent(
            patientId: id.description,
            personId: personId.description,
            actorId: actorId,
            occurredAt: now.date
        ))
    }

    /// Reconstitui o agregado `Patient` a partir de um estado persistido.
    ///
    /// Usado pelos adaptadores de infraestrutura (IO) para carregar o agregado do banco.
    /// - Note: Este método não gera eventos de domínio nem valida regras de negócio mutáveis.
    public static func reconstitute(
        id: PatientId,
        version: Int,
        personId: PersonId,
        personalData: PersonalData? = nil,
        civilDocuments: CivilDocuments? = nil,
        address: Address? = nil,
        diagnoses: [Diagnosis],
        familyMembers: [FamilyMember] = [],
        appointments: [SocialCareAppointment] = [],
        referrals: [Referral] = [],
        violationReports: [RightsViolationReport] = [],
        housingCondition: HousingCondition? = nil,
        socioeconomicSituation: SocioEconomicSituation? = nil,
        workAndIncome: WorkAndIncome? = nil,
        educationalStatus: EducationalStatus? = nil,
        healthStatus: HealthStatus? = nil,
        communitySupportNetwork: CommunitySupportNetwork? = nil,
        socialHealthSummary: SocialHealthSummary? = nil,
        socialIdentity: SocialIdentity? = nil,
        placementHistory: PlacementHistory? = nil,
        intakeInfo: IngressInfo? = nil,
        status: PatientStatus = .active,
        dischargeInfo: DischargeInfo? = nil
    ) -> Patient {
        var patient = Patient(
            id: id,
            version: version,
            personId: personId,
            personalData: personalData,
            civilDocuments: civilDocuments,
            address: address,
            diagnoses: diagnoses
        )

        patient.familyMembers = familyMembers
        patient.appointments = appointments
        patient.referrals = referrals
        patient.violationReports = violationReports
        patient.housingCondition = housingCondition
        patient.socioeconomicSituation = socioeconomicSituation
        patient.workAndIncome = workAndIncome
        patient.educationalStatus = educationalStatus
        patient.healthStatus = healthStatus
        patient.communitySupportNetwork = communitySupportNetwork
        patient.socialHealthSummary = socialHealthSummary
        patient.socialIdentity = socialIdentity
        patient.placementHistory = placementHistory
        patient.intakeInfo = intakeInfo
        patient.status = status
        patient.dischargeInfo = dischargeInfo

        return patient
    }

    // MARK: - Discharge & Readmit

    /// Desliga formalmente o paciente do acompanhamento.
    ///
    /// - Throws: `PatientError.alreadyDischarged` se o status atual não for `.active`.
    /// - Throws: `DischargeInfoError` se a validação do `DischargeInfo` falhar.
    public mutating func discharge(reason: DischargeReason, notes: String?, actorId: String, now: TimeStamp = .now) throws {
        guard status == .active else {
            throw PatientError.alreadyDischarged
        }
        let info = try DischargeInfo(reason: reason, notes: notes, dischargedAt: now, dischargedBy: actorId)
        self.status = .discharged
        self.dischargeInfo = info
        self.recordEvent(PatientDischargedEvent(
            patientId: id.description,
            personId: personId.description,
            actorId: actorId,
            reason: reason.rawValue,
            notes: notes,
            occurredAt: now.date
        ))
    }

    /// Readmite um paciente previamente desligado, retomando o acompanhamento.
    ///
    /// - Throws: `PatientError.alreadyActive` se o status atual não for `.discharged`.
    /// - Throws: `DischargeInfoError.notesExceedMaxLength` se as notas excederem 1000 caracteres.
    public mutating func readmit(notes: String?, actorId: String, now: TimeStamp = .now) throws {
        guard status == .discharged else {
            throw PatientError.alreadyActive
        }
        if let notes, notes.count > 1000 {
            throw DischargeInfoError.notesExceedMaxLength(notes.count)
        }
        self.status = .active
        self.dischargeInfo = nil
        self.recordEvent(PatientReadmittedEvent(
            patientId: id.description,
            personId: personId.description,
            actorId: actorId,
            notes: notes,
            occurredAt: now.date
        ))
    }

    /// Inicializador privado para uso exclusivo em factory e reconstituição.
    private init(
        id: PatientId,
        version: Int,
        personId: PersonId,
        personalData: PersonalData?,
        civilDocuments: CivilDocuments?,
        address: Address?,
        diagnoses: [Diagnosis]
    ) {
        self.id = id
        self.version = version
        self.uncommittedEvents = []
        self.personId = personId
        self.personalData = personalData
        self.civilDocuments = civilDocuments
        self.address = address
        self.diagnoses = diagnoses
    }
}
