//
//  PatientRepository.swift
//  SOCIAL-CARE
//
//  Created by Gabriel Vieira Soriano Aderaldo on 24/02/26.
//

import Foundation

// 1. O Protocolo (Equivalente ao PatientRepositoryPort)
protocol PatientRepository: Sendable {
    
    /// Salva ou atualiza o agregado completo.
    func save(_ patient: Patient) async throws
    
    /// Verifica se já existe um paciente para o ID de pessoa informado.
    func exists(byPersonId personId: PersonId) async throws -> Bool
    
    /// Recupera o agregado completo pelo ID de pessoa.
    func find(byPersonId personId: PersonId) async throws -> Patient?
    
    /// Recupera o agregado completo pelo ID interno.
    func find(byId id: UUID) async throws -> Patient?
}
