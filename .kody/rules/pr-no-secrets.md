---
title: "No hardcoded secrets or credentials in code"
scope: "pull_request"
severity_min: "critical"
buckets: ["security"]
enabled: true
---

## Instructions

Scan the entire PR diff (`pr_files_diff`) for hardcoded secrets, credentials, or sensitive values.

Flag as critical:
- API keys, tokens, or bearer tokens (strings matching `Bearer `, `token_`, `sk_`, `pk_`, `ghp_`, `gho_`)
- Database connection strings with embedded passwords
- Hardcoded passwords or passphrases in any variable
- Private keys (RSA, EC, PEM headers like `-----BEGIN`)
- JWT secrets or signing keys
- Zitadel client secrets or master keys
- Bitwarden tokens
- Any `.env` file content committed to the repository

Allowed:
- Environment variable references (`ProcessInfo.processInfo.environment["KEY"]`, `Environment.get("KEY")`)
- Placeholder/example values in `.env.example` files
- Test fixtures with obviously fake values (e.g., `"test-actor-id"`, `"00000000-0000-0000-0000-000000000000"`)

This organization manages sensitive patient data. A leaked credential is a compliance incident.

## Examples

### Bad example
```swift
let dbPassword = "sup3r_s3cr3t_p@ss"
let jwksURL = "https://auth.acdgbrasil.com.br/oauth/v2/keys"
let apiKey = "sk_live_abc123def456"
```

### Good example
```swift
let dbPassword = Environment.get("DB_PASSWORD") ?? ""
let jwksURL = Environment.get("JWKS_URL") ?? "https://auth.acdgbrasil.com.br/oauth/v2/keys"
```
