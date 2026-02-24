import Foundation

/// Um Value Object que representa um diagnóstico clínico associado ao paciente.
///
/// Encapsula o código CID, a data da ocorrência e uma descrição textual detalhada.
public struct Diagnosis: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// O código CID (ICDCode) associado ao diagnóstico.
    public let id: ICDCode
    
    /// A data em que o diagnóstico foi realizado.
    public let date: TimeStamp
    
    /// Descrição detalhada do diagnóstico.
    public let description: String

    // MARK: - Initializer
    
    private init(id: ICDCode, date: TimeStamp, description: String) {
        self.id = id
        self.date = date
        self.description = description
    }

    // MARK: - Factory Method

    /// Cria uma instância validada de `Diagnosis`.
    ///
    /// - Throws: `DiagnosisError` em caso de erro de validação.
    public static func create(
        id: ICDCode,
        date: TimeStamp,
        description: String,
        now: TimeStamp
    ) throws -> Diagnosis {
        
        // Validação: Data não pode ser futura
        guard date <= now else {
            throw DiagnosisError.dateInFuture(
                date: date.toISOString(),
                now: now.toISOString()
            )
        }

        // Validação: Ano deve ser válido (maior ou igual a zero)
        guard date.year >= 0 else {
            throw DiagnosisError.dateBeforeYearZero(year: date.year)
        }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validação: Descrição não pode ser vazia
        guard !trimmedDescription.isEmpty else {
            throw DiagnosisError.descriptionEmpty
        }

        return Diagnosis(
            id: id,
            date: date,
            description: trimmedDescription
        )
    }
}
