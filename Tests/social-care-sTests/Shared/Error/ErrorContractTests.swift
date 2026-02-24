import Testing
@testable import social_care_s
import Foundation

@Suite("Error Contract Tests")
struct ErrorContractTests {

    @Test("Error initialization with required fields")
    func errorInitialization() {
        // GIVEN
        let id = UUID().uuidString
        let code = "PAT-001"
        let message = "Patient not found"
        let bc = "PatientManagement"
        let module = "Registration"
        let kind = "NOT_FOUND"
        let context: [String: AnySendable] = ["patientId": AnySendable("123")]
        let safeContext: [String: AnySendable] = ["reason": AnySendable("not_in_db")]
        
        let observability = AppError.Observability(
            category: .domainRuleViolation,
            severity: .error,
            fingerprint: ["registration", "not-found"],
            tags: ["feature": "search"]
        )
        
        // WHEN
        let sut = AppError(
            id: id,
            code: code,
            message: message,
            bc: bc,
            module: module,
            kind: kind,
            context: context,
            safeContext: safeContext,
            observability: observability
        )
        
        // THEN
        #expect(sut.id == id)
        #expect(sut.code == code)
        #expect(sut.message == message)
        #expect(sut.bc == bc)
        #expect(sut.module == module)
        #expect(sut.kind == kind)
        #expect(sut.context["patientId"]?.value as? String == "123")
        #expect(sut.safeContext["reason"]?.value as? String == "not_in_db")
        #expect(sut.observability.category == .domainRuleViolation)
    }
    
    @Test("Error with optional fields")
    func errorWithOptionalFields() {
        // GIVEN
        let observability = AppError.Observability(
            category: .unexpectedSystemState,
            severity: .critical,
            fingerprint: ["system-crash"],
            tags: [:]
        )
        
        // WHEN
        let sut = AppError(
            id: "1",
            code: "SYS-500",
            message: "Internal error",
            bc: "Core",
            module: "System",
            kind: "CRASH",
            context: [:],
            safeContext: [:],
            observability: observability,
            http: 500,
            stackTrace: "main.swift:10...",
            cause: nil 
        )
        
        // THEN
        #expect(sut.http == 500)
        #expect(sut.stackTrace == "main.swift:10...")
    }
    
    @Test("Result pattern integration")
    func resultPatternIntegration() {
        // GIVEN
        func performOperation() -> Result<String, AppError> {
            let error = AppError(
                id: "1", code: "ERR", message: "Fail", bc: "BC", module: "MOD", kind: "K",
                context: [:], safeContext: [:],
                observability: .init(category: .conflict, severity: .warning, fingerprint: ["f"], tags: [:])
            )
            return .failure(error)
        }
        
        // WHEN
        let result = performOperation()
        
        // THEN
        switch result {
        case .success:
            #expect(Bool(false), "Should have failed")
        case .failure(let error):
            #expect(error.code == "ERR")
        }
    }
}
