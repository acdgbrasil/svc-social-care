import Foundation
import SQLKit

struct AddV2AssessmentFields: Migration {
    let name = "2026_03_06_AddV2AssessmentFields"

    func prepare(on db: any SQLDatabase) async throws {
        let jsonbType = SQLRaw("JSONB")
        
        try await db.alter(table: "patients")
            .column("work_and_income", type: .custom(jsonbType))
            .column("educational_status", type: .custom(jsonbType))
            .column("health_status", type: .custom(jsonbType))
            .column("acolhimento_history", type: .custom(jsonbType))
            .column("ingress_info", type: .custom(jsonbType))
            .run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.alter(table: "patients")
            .dropColumn("work_and_income")
            .dropColumn("educational_status")
            .dropColumn("health_status")
            .dropColumn("acolhimento_history")
            .dropColumn("ingress_info")
            .run()
    }
}
