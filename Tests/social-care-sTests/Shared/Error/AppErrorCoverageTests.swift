import Testing
@testable import social_care_s
import Foundation

@Suite("AppError Coverage")
struct AppErrorCoverageTests {

    @Test("Equatable considera id idêntico ou tripla code/bc/module")
    func appErrorEqualityRules() {
        let observability = AppError.Observability(
            category: .domainRuleViolation,
            severity: .error,
            fingerprint: ["x"],
            tags: [:]
        )

        let e1 = AppError(
            id: "same-id",
            code: "A-1",
            message: "m1",
            bc: "SOCIAL",
            module: "mod-1",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        let e2 = AppError(
            id: "same-id",
            code: "B-2",
            message: "m2",
            bc: "SOCIAL",
            module: "mod-2",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        #expect(e1 == e2)

        let e3 = AppError(
            id: "id-3",
            code: "C-3",
            message: "m3",
            bc: "SOCIAL",
            module: "mod-3",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        let e4 = AppError(
            id: "id-4",
            code: "C-3",
            message: "m4",
            bc: "SOCIAL",
            module: "mod-3",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        #expect(e3 == e4)

        let e5 = AppError(
            id: "id-5",
            code: "X-1",
            message: "m5",
            bc: "SOCIAL",
            module: "mod-x",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        let e6 = AppError(
            id: "id-6",
            code: "X-2",
            message: "m6",
            bc: "SOCIAL",
            module: "mod-x",
            kind: "K",
            context: [:],
            safeContext: [:],
            observability: observability
        )
        #expect(e5 != e6)
    }

    @Test("Result.appFailure monta AppError com contexto e HTTP")
    func resultAppFailureBuilder() {
        let result: Result<Int, AppError> = .appFailure(
            code: "APP-900",
            message: "Erro de teste",
            bc: "SOCIAL",
            module: "social-care/tests",
            kind: "SyntheticFailure",
            category: .observabilityPipelineFailure,
            severity: .warning,
            context: ["attempt": 3],
            http: 503
        )

        guard case .failure(let err) = result else {
            #expect(Bool(false), "Era esperado .failure")
            return
        }

        #expect(err.code == "APP-900")
        #expect(err.http == 503)
        #expect(err.context["attempt"]?.value as? Int == 3)
        #expect(err.safeContext.isEmpty)
        #expect(err.observability.fingerprint == ["APP-900"])
    }

    @Test("Enums de observabilidade e AnySendable ficam acessíveis")
    func observabilityEnumsAndAnySendableCoverage() {
        let categories: [AppError.Category] = [
            .domainRuleViolation,
            .externalApiFailure,
            .externalContractMismatch,
            .crossLayerCommunicationFailure,
            .dataConsistencyIncident,
            .securityBoundaryViolation,
            .infrastructureDependencyFailure,
            .observabilityPipelineFailure,
            .unexpectedSystemState,
            .conflict
        ]

        let severities: [AppError.Severity] = [
            .debug, .info, .warning, .error, .critical
        ]

        #expect(categories.count == 10)
        #expect(severities.count == 5)
        #expect(categories.map(\.rawValue).contains("CONFLICT"))
        #expect(severities.map(\.rawValue).contains("CRITICAL"))

        let wrapped = AnySendable(["k": "v"])
        #expect((wrapped.value as? [String: String])?["k"] == "v")
    }
}
