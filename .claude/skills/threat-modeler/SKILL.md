---
name: threat-modeler
description: >
  Threat Modeling expert using STRIDE + DFD methodology with DREAD scoring.
  Evaluates OWASP Top 10 compliance and ASVS levels.
  Use when analyzing system security architecture or performing risk assessment.
user_invocable: true
---

# Threat Modeler — STRIDE + DREAD

## Methodology

### 1. Data Flow Diagram (DFD)
Map the system with Mermaid diagrams showing:
- **External Entities**: clients, IdPs, external APIs
- **Processes**: controllers, middleware, use cases, event handlers
- **Data Stores**: PostgreSQL, NATS, outbox
- **Data Flows**: HTTP, SQL, TCP, events
- **Trust Boundaries**: internet/edge, edge/DB, edge/NATS, edge/external

### 2. STRIDE Per Element

| Threat | Question | Applies To |
|--------|----------|------------|
| **S**poofing | Can identity be faked? | Entities, Processes |
| **T**ampering | Can data be modified? | Flows, Stores |
| **R**epudiation | Can actions be denied? | Processes |
| **I**nfo Disclosure | Can data leak? | Flows, Stores |
| **D**enial of Service | Can it be overloaded? | Processes, Stores |
| **E**levation of Privilege | Can access be escalated? | Processes |

### 3. DREAD Scoring (1-10 each)
- **D**amage: How bad is it?
- **R**eproducibility: How easy to reproduce?
- **E**xploitability: How easy to exploit?
- **A**ffected Users: How many affected?
- **D**iscoverability: How easy to discover?

Score = average of all 5 dimensions.

### 4. OWASP Top 10 (2021) Compliance
For each category (A01-A10): Compliant / Partial / Non-Compliant / N/A

### 5. Risk Matrix
High/Medium/Low Likelihood vs High/Medium/Low Impact -> Priority

## social-care Specific Context
- Handles PHI/PII under LGPD (Brazilian data protection law)
- CPF, NIS, CNS, medical diagnoses, domestic violence reports
- Edge hardware deployment (private network, but shared K3s)
- NATS for inter-service events (contains PII in payloads)
- PostgreSQL with normalized schema (PII in plaintext columns)
