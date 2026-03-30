//
//  PatientRepository.swift
//  SOCIAL-CARE
//
//  Created by Gabriel Vieira Soriano Aderaldo on 24/02/26.
//

import Foundation

// 1. O Protocolo (Equivalente ao PatientRepositoryPort)
public protocol PatientRepository: Sendable {

    /// Salva ou atualiza o agregado completo.
    func save(_ patient: Patient) async throws

    /// Verifica se já existe um paciente para o ID de pessoa informado.
    func exists(byPersonId personId: PersonId) async throws -> Bool

    /// Recupera o agregado completo pelo ID de pessoa.
    func find(byPersonId personId: PersonId) async throws -> Patient?

    /// Recupera o agregado completo pelo ID interno.
    func find(byId id: PatientId) async throws -> Patient?

    /// Lista pacientes com paginação cursor-based e busca opcional.
    func list(search: String?, cursor: PatientId?, limit: Int) async throws -> PatientListResult
}

/// Resultado paginado da listagem de pacientes.
public struct PatientListResult: Sendable {
    public let items: [PatientSummary]
    public let totalCount: Int
    public let hasMore: Bool
    public let nextCursor: PatientId?

    public init(items: [PatientSummary], totalCount: Int, hasMore: Bool, nextCursor: PatientId?) {
        self.items = items
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.nextCursor = nextCursor
    }
}

/// Projeção leve do paciente para listagem (sem carregar agregado completo).
public struct PatientSummary: Sendable {
    public let patientId: PatientId
    public let personId: PersonId
    public let firstName: String?
    public let lastName: String?
    public let primaryDiagnosis: String?
    public let memberCount: Int

    public init(
        patientId: PatientId,
        personId: PersonId,
        firstName: String?,
        lastName: String?,
        primaryDiagnosis: String?,
        memberCount: Int
    ) {
        self.patientId = patientId
        self.personId = personId
        self.firstName = firstName
        self.lastName = lastName
        self.primaryDiagnosis = primaryDiagnosis
        self.memberCount = memberCount
    }
}
