import Foundation

/// Payload de entrada para o registro de um novo paciente.
struct RegisterPatientCommand: Sendable {
    struct DiagnosisDraft: Sendable {
        let icdCode: String
        let date: Date
        let description: String
    }
    
    let personId: String
    let initialDiagnoses: [DiagnosisDraft]
    
    init(personId: String, initialDiagnoses: [DiagnosisDraft]) {
        self.personId = personId
        self.initialDiagnoses = initialDiagnoses
    }
}
