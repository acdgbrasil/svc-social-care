import Foundation
import SQLKit
import NIOCore
import NIOPosix
import Logging

/// Um banco de dados SQL mockado que captura todas as queries e binds para asserções de teste.
public final class SQLDatabaseMock: SQLDatabase, @unchecked Sendable {
    public let eventLoop: any EventLoop
    public var logger: Logger
    public var dialect: any SQLDialect
    
    public private(set) var executedQueries: [String] = []
    public private(set) var capturedBinds: [[any Encodable]] = []
    
    public var rowsToReturn: [any SQLRow] = []
    public var errorToThrow: (any Error)?

    public init(dialect: any SQLDialect = GenericSQLDialect(), eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.next()) {
        self.dialect = dialect
        self.eventLoop = eventLoop
        self.logger = Logger(label: "sql-mock")
    }

    public func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> EventLoopFuture<Void> {
        let serialized = self.serialize(query)
        self.executedQueries.append(serialized.sql)
        self.capturedBinds.append(serialized.binds)
        
        if let error = errorToThrow {
            let promise = eventLoop.makePromise(of: Void.self)
            promise.fail(error)
            return promise.futureResult
        }
        
        for row in rowsToReturn {
            onRow(row)
        }
        
        return eventLoop.makeSucceededVoidFuture()
    }
}

public struct GenericSQLDialect: SQLDialect {
    public var name: String { "generic" }
    public var identifierQuote: any SQLExpression { SQLRaw("\"") }
    public var literalStringQuote: any SQLExpression { SQLRaw("'") }
    public func bindPlaceholder(at position: Int) -> any SQLExpression { SQLRaw("$\(position)") }
    public func literalBoolean(_ value: Bool) -> any SQLExpression { SQLRaw(value ? "TRUE" : "FALSE") }
    public var autoIncrementClause: any SQLExpression { SQLRaw("SERIAL") }
    public var supportsIfExists: Bool { true }
    public var enumSyntax: SQLEnumSyntax { .unsupported }
    public var triggerSyntax: SQLTriggerSyntax { .init() }
    public var alterTableSyntax: SQLAlterTableSyntax { .init(allowsBatch: true) }
    public var upsertSyntax: SQLUpsertSyntax { .standard }
    public var supportsAutoIncrement: Bool { true }
    
    public init() {}
}

public struct SQLRowMock: SQLRow, @unchecked Sendable {
    private let data: [String: Any]
    public var allColumns: [String] { Array(data.keys) }

    public init(_ data: [String: Any]) {
        self.data = data
    }

    public func contains(column: String) -> Bool {
        data.keys.contains(column)
    }

    public func decodeNil(column: String) throws -> Bool {
        data[column] == nil
    }

    public func decode<T>(column: String, as type: T.Type) throws -> T where T : Decodable {
        guard let value = data[column] else {
            throw DecodingError.keyNotFound(SQLColumn(stringValue: column), .init(codingPath: [], debugDescription: "Column not found"))
        }
        // Force cast for mock simplicity
        return value as! T
    }
}

struct SQLColumn: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(stringValue: String) { self.stringValue = stringValue }
    init(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
}
