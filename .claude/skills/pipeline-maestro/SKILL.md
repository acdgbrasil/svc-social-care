---
name: pipeline-maestro
description: >
  Orchestrates a multi-agent fail-first pipeline for Swift/Vapor development.
  Coordinates domain-architect, test-writer, domain-modeler, application-orchestrator,
  infra-implementer, code-reviewer, swift-quality-checker, integration-validator.
  Use when implementing features that span multiple layers.
user_invocable: true
---

# Pipeline Maestro — Swift/Vapor Multi-Agent Pipeline

## Agent Roster

| Agent | Role | Writes To | Never Touches |
|-------|------|-----------|---------------|
| domain-architect | Type contracts | 001-contracts/ | implementations, tests |
| test-writer | Failing tests | 002-tests/ | implementations, Sources/ |
| domain-modeler | Domain code | 003-domain/ + Domain/ | app, IO, tests |
| application-orchestrator | Use cases | 003-application/ + Application/ | domain impl, IO, tests |
| infra-implementer | IO layer | 003-infra/ + IO/ | domain, app, tests |
| code-reviewer | Architecture audit | 004-code-review/ | cannot modify code |
| swift-quality-checker | Swift quality | 005-swift-quality/ | cannot modify code |
| integration-validator | Build + test | 006-integration/ | cannot modify anything |

## Execution Waves

### Wave 1: Design
1. **domain-architect** — reads request + OpenAPI contracts, produces type-level artifacts

### Wave 2: Tests (TDD Red)
2. **test-writer** — reads contracts, writes failing tests (swift-testing)

### Wave 3: Implementation (parallel where independent)
3. **domain-modeler** — reads contracts + tests, implements domain (make tests green)
4. **application-orchestrator** — reads contracts + tests + domain REPORT, implements use cases
5. **infra-implementer** — reads ALL REPORTs, implements IO layer (controllers, repos, DTOs)

### Wave 4: Quality Gates
6. **code-reviewer** — audits all code against CLAUDE.md rules
7. **swift-quality-checker** — audits Swift language quality
8. **integration-validator** — runs `make ci` (build + test + coverage)

## Communication Protocol

### REPORT.md Public API Chain
1. domain-modeler lists domain functions -> application-orchestrator reads it
2. application-orchestrator lists use cases + ports -> infra-implementer reads it
3. infra-implementer reads ALL reports to know what to implement

### Fresh Context Protocol
Each agent gets ONLY the context it needs:
- domain-modeler: 001-contracts/, 002-tests/ (domain only)
- application-orchestrator: 001-contracts/, 002-tests/ (app only), 003-domain/REPORT.md
- infra-implementer: 001-contracts/, 002-tests/ (infra only), ALL 003-*/REPORT.md

### Review Loops
- Max 3 rounds per review stage
- Issues routed to SPECIFIC implementer by file/layer
- After 3 rejections -> escalate to user

## Pipeline Folder Structure
```
.pipeline/<ticket>/
  000-request.md          — original user request
  000-discuss/CONTEXT.md  — design decisions (if discuss phase used)
  001-contracts/           — type definitions, signatures, errors
  002-tests/               — failing tests (TDD red)
  003-domain/REPORT.md     — domain Public API
  003-application/REPORT.md — use case Public API
  003-infra/REPORT.md      — IO layer summary
  004-code-review/         — review rounds
  005-swift-quality/       — quality check results
  006-integration/         — build + test results
  STATE.md                 — current pipeline state
```

## Granularity
- 1 ticket = 1 atomic unit (1 VO, 1 aggregate, 1 use case, 1 controller)
- Complete one ticket end-to-end before starting next
- Never implement multiple bounded contexts simultaneously

## Commit Convention
```
feat(<bc>/<scope>): <description>

- [what was created]
- [error handling]
- [coverage stats]

Pipeline: [agents used], [review rounds]
```
