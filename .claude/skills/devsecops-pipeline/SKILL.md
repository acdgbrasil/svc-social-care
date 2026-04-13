---
name: devsecops-pipeline
description: >
  DevSecOps for Swift/Vapor infrastructure. Covers Docker, CI/CD (GitHub Actions),
  SwiftPM dependency security, secrets management, and supply chain.
  Use when auditing infrastructure, Dockerfile, CI/CD, or dependencies.
user_invocable: true
---

# DevSecOps Pipeline — Swift/Vapor

## 6 Pillars

### 1. SwiftPM Dependency Security
- `Package.resolved` committed (lockfile)
- Dependencies from trusted publishers (apple/*, vapor/*, swift-server/*)
- No known CVEs in current versions
- Dependabot configured for swift ecosystem
- Version ranges in `Package.swift`, exact pins in `Package.resolved`

### 2. Docker Security
```dockerfile
# Required patterns:
FROM swift:6.2-jammy AS build          # Pinned version
COPY Package.swift Package.resolved ./ # Deps first (layer cache)
RUN swift package resolve
COPY Sources ./Sources                 # No Tests in build
RUN swift build -c release --product social-care-s

FROM ubuntu:22.04                      # Minimal runtime
RUN useradd -r -g appgroup appuser     # Non-root user
COPY --from=build --chown=appuser:appgroup ... # Owned by appuser
USER appuser                           # Run as non-root
HEALTHCHECK ...                        # Health check defined
```

Checklist:
- [ ] Base image pinned (not `:latest`)
- [ ] Non-root USER directive
- [ ] Multi-stage build
- [ ] No secrets in ENV/ARG
- [ ] `.dockerignore` excludes `.env`, `.git`, `.build`
- [ ] HEALTHCHECK defined
- [ ] `security_opt: [no-new-privileges:true]` in compose

### 3. CI/CD Pipeline (GitHub Actions)
- [ ] Actions pinned by SHA (not tag)
- [ ] Reusable workflows pinned by SHA (not `@main`)
- [ ] `swift test` runs BEFORE image push
- [ ] Security scanning step (Trivy container scan)
- [ ] Least privilege permissions on jobs
- [ ] Secrets in GitHub Secrets only

### 4. Secrets Management
- [ ] No secrets in source code (grep for patterns)
- [ ] No fallback credentials compiled into binary
- [ ] `.env` in `.gitignore`
- [ ] Pre-commit hooks (gitleaks)
- [ ] Different secrets per environment
- [ ] Bitwarden Secret Manager for prod secrets

### 5. Supply Chain
- [ ] SBOM generation in pipeline
- [ ] Container image signing (cosign/Sigstore)
- [ ] Immutable image tags (`sha-<commit>`, `vX.Y.Z`)
- [ ] `:latest` only on main, production uses digest

### 6. Monitoring & Alerting
- [ ] Structured logging (not `print()`)
- [ ] Health/readiness probes (K8s compatible)
- [ ] Graceful shutdown handler
- [ ] Outbox relay monitoring (failed event delivery)
