import Foundation
import Vapor

/// Validacoes cruzadas que requerem dados de multiplos modulos do agregado Patient.
/// Executa regras de negocio do BFF que dependem de contexto (familia, idade, sexo).
struct CrossValidator: Sendable {
    private let patient: Patient

    init(patient: Patient) {
        self.patient = patient
    }

    // MARK: - Health × Sex (Gestating Members)

    /// Valida que membros listados como gestantes sao do sexo feminino.
    /// So e possivel validar o PR (pessoa de referencia) pois dados de sexo
    /// de outros membros residem no people-context (outro bounded context).
    func validateGestatingMembers(_ gestatingMemberIds: [String]) throws {
        for memberId in gestatingMemberIds {
            if memberId == patient.personId.description {
                guard patient.personalData?.sex == .feminino else {
                    throw Abort(
                        .unprocessableEntity,
                        reason: "Member '\(memberId)' cannot be registered as gestating: sex is not 'feminino'."
                    )
                }
            }
        }
    }

    // MARK: - Placement History (Acolhimento)

    /// Valida regras cruzadas do historico de acolhimento:
    /// 1. endDate >= startDate em cada registro
    /// 2. thirdPartyGuardReport exige membro < 18 anos
    /// 3. adolescentInInternment exige membro 12-17 anos
    func validatePlacementHistory(
        registries: [UpdatePlacementHistoryRequest.RegistryDraftDTO],
        thirdPartyGuardReport: String?,
        adolescentInInternment: Bool
    ) throws {
        // 1. Date chronology
        for registry in registries {
            if let endDate = registry.endDate, endDate < registry.startDate {
                throw Abort(
                    .unprocessableEntity,
                    reason: "Placement registry for member '\(registry.memberId)': endDate cannot be before startDate."
                )
            }
        }

        let now = TimeStamp.now
        let memberAges = patient.familyMembers.map { $0.birthDate.years(at: now) }

        // 2. Third-party guard requires at least one minor (< 18)
        if let report = thirdPartyGuardReport, !report.isEmpty {
            let hasMinor = memberAges.contains { $0 < 18 }
            if !hasMinor {
                throw Abort(
                    .unprocessableEntity,
                    reason: "Third-party guard report requires at least one family member under 18 years old."
                )
            }
        }

        // 3. Adolescent internment requires member aged 12-17
        if adolescentInInternment {
            let hasAdolescent = memberAges.contains { $0 >= 12 && $0 < 18 }
            if !hasAdolescent {
                throw Abort(
                    .unprocessableEntity,
                    reason: "Adolescent internment flag requires at least one family member aged 12 to 17."
                )
            }
        }
    }
}
