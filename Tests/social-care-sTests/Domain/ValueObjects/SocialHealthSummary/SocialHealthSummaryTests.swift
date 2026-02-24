import Testing
@testable import social_care_s
import Foundation

@Suite("SocialHealthSummary ValueObject (FP Style - Specification)")
struct SocialHealthSummaryTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {

        @Test("create deduplica dependências")
        func deduplicateDependencies() throws {
            let summary = try SocialHealthSummary.create(
                requiresConstantCare: false,
                hasMobilityImpairment: false,
                functionalDependencies: ["Eating", "Eating", "  Walking  "],
                hasRelevantDrugTherapy: false
            )
            
            #expect(summary.functionalDependencies.count == 2)
            #expect(summary.functionalDependencies.contains("Eating"))
            #expect(summary.functionalDependencies.contains("Walking"))
        }

        @Test("create falha com string vazia")
        func failsWithEmptyString() {
            #expect(throws: SocialHealthSummaryError.functionalDependenciesEmpty) {
                try SocialHealthSummary.create(
                    requiresConstantCare: false,
                    hasMobilityImpairment: false,
                    functionalDependencies: ["Eating", "   "],
                    hasRelevantDrugTherapy: false
                )
            }
        }
    }
}
