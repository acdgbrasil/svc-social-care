import Foundation
import Logging

/// Handles linking a Patient to a canonical PersonId from people-context.
///
/// Flow:
/// 1. Parse CPF and PersonId from the command
/// 2. Find Patient by CPF
/// 3. If found and not already linked, update person_id
/// 4. If already linked with the same PersonId, idempotent no-op
public actor LinkPersonIdCommandHandler: LinkPersonIdUseCase {
    private let patientRepository: any PatientRepository
    private let logger: Logger

    public init(patientRepository: any PatientRepository) {
        self.patientRepository = patientRepository
        self.logger = Logger(label: "link-person-id")
    }

    public func handle(_ command: LinkPersonIdCommand) async throws {
        // 1. Parse values
        let cpf: CPF
        do {
            cpf = try CPF(command.cpf)
        } catch {
            logger.warning("Invalid CPF in event", metadata: ["cpf": "\(Self.maskedCpf(command.cpf))"])
            throw LinkPersonIdError.invalidCpf(Self.maskedCpf(command.cpf))
        }

        let newPersonId: PersonId
        do {
            newPersonId = try PersonId(command.personId)
        } catch {
            logger.warning("Invalid PersonId in event: \(command.personId)")
            throw LinkPersonIdError.invalidPersonId(command.personId)
        }

        // 2. Find Patient by CPF
        guard let patient = try await patientRepository.find(byCpf: cpf) else {
            logger.info("No patient found for CPF — skipping link", metadata: ["cpf": "\(Self.maskedCpf(command.cpf))"])
            return
        }

        // 3. Idempotency: already linked with same PersonId
        if patient.personId == newPersonId {
            logger.info("Patient already linked to PersonId", metadata: ["patientId": "\(patient.id.description)", "personId": "\(command.personId)"])
            return
        }

        // 4. Update person_id
        try await patientRepository.updatePersonId(
            patientId: patient.id,
            newPersonId: newPersonId
        )

        logger.info("Linked Patient to PersonId via CPF", metadata: ["patientId": "\(patient.id.description)", "personId": "\(command.personId)"])
    }

    private static func maskedCpf(_ cpf: String) -> String {
        let clean = cpf.filter(\.isNumber)
        guard clean.count >= 4 else { return "***" }
        return "***.\(clean.suffix(4))"
    }
}
