---
title: "Use SQLKit DSL for queries, never string-interpolated SQL"
scope: "file"
path: ["Sources/social-care-s/IO/Persistence/**/*.swift"]
severity_min: "critical"
languages: ["swift"]
buckets: ["security"]
enabled: true
---

## Instructions

All database queries must use SQLKit's type-safe DSL (`db.select()`, `db.insert()`, `db.update()`, `db.delete()`) with `SQLBind` for parameters. This prevents SQL injection.

Flag:
- String interpolation inside `SQLRaw()` with user-supplied values (e.g., `SQLRaw("SELECT * FROM \(tableName) WHERE id = '\(userId)'")`
- Raw SQL strings with concatenated variables
- Any pattern where user input flows into a SQL string without `SQLBind`

Allowed uses of `SQLRaw`:
- DDL in migrations (CREATE TABLE, CREATE INDEX, ALTER TABLE) with hardcoded strings
- Static SQL fragments that don't include user input

## Examples

### Bad example
```swift
func findByName(_ name: String) async throws -> PatientModel? {
    // SQL INJECTION RISK — user input directly in SQL string
    let result = try await db.raw("SELECT * FROM patients WHERE name = '\(name)'")
        .first(decoding: PatientModel.self)
    return result
}
```

### Good example
```swift
func findByName(_ name: String) async throws -> PatientModel? {
    return try await db.select()
        .column("*")
        .from("patients")
        .where("name", .equal, SQLBind(name))
        .first(decoding: PatientModel.self)
}
```
