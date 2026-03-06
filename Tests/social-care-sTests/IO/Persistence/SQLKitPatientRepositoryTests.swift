import Testing
import SQLKit
import Foundation
@testable import social_care_s

@Suite("SQLKitPatientRepository Transactional Tests")
struct SQLKitPatientRepositoryTests {

    /// Mock que simula um banco SQL e permite injetar falhas e rastrear sessões.
    final class MockSQLDatabase: SQLDatabase, @unchecked Sendable {
        let eventLoop: any EventLoop = EmbeddedEventLoop()
        let logger: Logger = Logger(label: "test")
        var dialect: any SQLDialect { GenericDialect() }
        
        var operations: [String] = []
        var shouldFail: Bool = false
        var lastSession: (any SQLDatabase)?

        func execute(sql: any SQLExpression, _ onRow: @escaping (any SQLRow) throws -> ()) -> EventLoopFuture<Void> {
            operations.append("\(sql)")
            if shouldFail {
                return eventLoop.makeFailedFuture(NSError(domain: "test", code: 1))
            }
            return eventLoop.makeSucceededFuture(())
        }
        
        func withSession<T>(_ closure: @escaping (any SQLDatabase) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
            lastSession = self
            return closure(self)
        }
    }

    struct GenericDialect: SQLDialect {
        var name: String { "generic" }
        var identifierQuote: any SQLExpression { SQLRaw("\"") }
        var literalStringQuote: any SQLExpression { SQLRaw("'") }
        func bindPlaceholder(at position: Int) -> any SQLExpression { SQLRaw("?") }
        func literalBoolean(_ value: Bool) -> any SQLExpression { SQLRaw(value ? "TRUE" : "FALSE") }
        var autoIncrementClause: any SQLExpression { SQLRaw("AUTOINCREMENT") }
        var supportsAutoIncrement: Bool { true }
        var enumSyntax: SQLEnumSyntax { .unsupported }
        var triggerSyntax: SQLTriggerSyntax { .init() }
        var alterTableSyntax: SQLAlterTableSyntax { .init() }
        var upsertSyntax: SQLUpsertSyntax { .standard }
        var unionSyntax: SQLUnionSyntax { .init() }
    }

    @Test("Deve garantir que todas as operacoes usam a mesma transacao")
    func allOperationsUseTransaction() async throws {
        let db = MockSQLDatabase()
        let repo = SQLKitPatientRepository(db: db)
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        let patient = try Patient(id: PatientId(), personId: pId, diagnoses: [diag], familyMembers: [prMember], prRelationshipId: prId)
        
        // Atualmente o MockSQLDatabase.transaction (via fallback) usa BEGIN/COMMIT
        try await repo.save(patient)
        
        #expect(db.operations.contains(where: { $0.contains("BEGIN") }))
        #expect(db.operations.contains(where: { $0.contains("COMMIT") }))
        #expect(db.operations.contains(where: { $0.contains("INSERT INTO \"patients\"") }))
        #expect(db.operations.contains(where: { $0.contains("INSERT INTO \"family_members\"") }))
    }

    @Test("Deve realizar rollback em caso de falha no meio da transacao")
    func rollbackOnFailure() async throws {
        let db = MockSQLDatabase()
        let repo = SQLKitPatientRepository(db: db)
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        let patient = try Patient(id: PatientId(), personId: pId, diagnoses: [diag], familyMembers: [prMember], prRelationshipId: prId)
        
        // Simular falha
        db.shouldFail = true
        
        await #expect(throws: Error.self) {
            try await repo.save(patient)
        }
        
        #expect(db.operations.contains(where: { $0.contains("BEGIN") }))
        #expect(db.operations.contains(where: { $0.contains("ROLLBACK") }))
        #expect(!db.operations.contains(where: { $0.contains("COMMIT") }))
    }
}
