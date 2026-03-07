import Foundation
@testable import social_care_s

actor InMemoryPatientRepository: PatientRepository {
    private var storage: [PatientId: Patient] = [:]
    private(set) var saveCallCount = 0

    func save(_ patient: Patient) async throws {
        storage[patient.id] = patient
        saveCallCount += 1
    }

    func exists(byPersonId personId: PersonId) async throws -> Bool {
        storage.values.contains { $0.personId == personId }
    }

    func find(byPersonId personId: PersonId) async throws -> Patient? {
        storage.values.first { $0.personId == personId }
    }

    func find(byId id: PatientId) async throws -> Patient? {
        storage[id]
    }

    // MARK: - Test Helpers

    func seed(_ patient: Patient) {
        storage[patient.id] = patient
    }

    func stored(byId id: PatientId) -> Patient? {
        storage[id]
    }

    var allPatients: [Patient] {
        Array(storage.values)
    }
}
