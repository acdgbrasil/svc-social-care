---
title: "HTTP responses must use StandardResponse wrapper"
scope: "file"
path: ["Sources/social-care-s/IO/HTTP/Controllers/**/*.swift"]
severity_min: "medium"
languages: ["swift"]
buckets: ["style-conventions"]
enabled: true
---

## Instructions

All controller handlers must return responses wrapped in `StandardResponse<T>`, which provides a consistent envelope with `data` and `meta.timestamp`.

Flag:
- Handlers returning raw models or dictionaries directly
- Handlers encoding responses without the `StandardResponse` wrapper
- Inconsistent use of `.encodeResponse(status:for:)` pattern

The standard pattern is:
```swift
let response = StandardResponse(data: someDTO)
return try await response.encodeResponse(status: .ok, for: req)
```

## Examples

### Bad example
```swift
@Sendable
private func getById(req: Request) async throws -> Response {
    let patient = try await fetchPatient(req)
    // Returning raw model — no standard envelope
    return try await patient.encodeResponse(for: req)
}
```

### Good example
```swift
@Sendable
private func getById(req: Request) async throws -> Response {
    let patient = try await fetchPatient(req)
    let dto = PatientResponse(from: patient)
    return try await StandardResponse(data: dto)
        .encodeResponse(status: .ok, for: req)
}
```
