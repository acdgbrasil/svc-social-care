import Foundation

/// Serviço de orquestração para o processo de cadastro de paciente.
///
/// Este serviço coordena a validação de documentos, criação do agregado e
/// persistência inicial, retornando um resultado consolidado para a UI.
public struct PatientRegistrationService: PatientRegistering {
    
    private let registerPatient: any RegisterPatientUseCase
    
    public init(registerPatient: any RegisterPatientUseCase) {
        self.registerPatient = registerPatient
    }
    
    public func register(request: PatientRegistrationRequest) async throws -> PatientRegistrationResult {
        
        let patientId: String
        
        do {
            // 1. Executa o Use Case de Registro
            let command = RegisterPatientCommand(
                personId: request.personId,
                initialDiagnoses: request.initialDiagnoses.map { 
                    RegisterPatientCommand.DiagnosisDraft(icdCode: $0.icdCode, date: $0.date, description: $0.description) 
                },
                personalData: request.personalData.map {
                    RegisterPatientCommand.PersonalDataDraft(
                        firstName: $0.firstName, lastName: $0.lastName, motherName: $0.motherName,
                        nationality: $0.nationality, sex: $0.sex, socialName: $0.socialName,
                        birthDate: $0.birthDate, phone: $0.phone
                    )
                },
                prRelationshipId: request.prRelationshipId
            )
            patientId = try await registerPatient.handle(command)
        } catch let error as RegisterPatientError {
            throw PatientRegistrationError.registrationFailed(error)
        } catch {
            // Fallback para outros erros que não foram mapeados no UseCase
            throw PatientRegistrationError.registrationFailed(.persistenceMappingFailure(issues: [String(describing: error)]))
        }

        return PatientRegistrationResult(
            patientId: patientId,
            status: .completed,
            timestamp: Date()
        )
    }
}
