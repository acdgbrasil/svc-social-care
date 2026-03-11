# Plano de Implementacao — social-care (Conclusao do Microservico)

> **ATENCAO:** O contrato OpenAPI em `contracts/` esta TOTALMENTE DESATUALIZADO e NAO deve ser utilizado.
> **Fonte de Verdade Unica:** Documentos em `handbook/front_end_forms/`.
> **Padrao de Idioma:** Todos os DTOs e caminhos de API devem ser em INGLES (mapeados a partir das especificacoes em PT-BR).
> **Padrao de Codigo:** CamelCase e Ingles para todos os simbolos (Variables, Constants, Enums, Classes, Protocols, Structs), seguindo rigorosamente o [Swift API Design Guidelines](tooling/swift/api-design-guidelines/index.md).
> **Escopo de Operacao:** Padrao **CRU** (Create, Read, Update). A operacao **Delete** e proibida em quase todos os dominios para garantir rastreabilidade.

---

## Indice

1. [Diagnostico: O Que Ja Existe](#1-diagnostico-o-que-ja-existe)
2. [Gaps Identificados](#2-gaps-identificados)
3. [Plano de Fases](#3-plano-de-fases)
4. [Fase 1 — Solidificar o Core (Foundation)](#fase-1)
5. [Fase 2 — Completar Use Cases Faltantes](#fase-2)
6. [Fase 3 — HTTP Layer (Vapor & Front-End Forms)](#fase-3)
7. [Fase 4 — Persistencia Robusta](#fase-4)
8. [Fase 5 — Outbox Relay + Event Delivery](#fase-5)
9. [Fase 6 — Queries / Read Side](#fase-6)
10. [Fase 7 — Cross-Cutting (Error, Health, Observability)](#fase-7)
11. [Fase 8 — Testes de Integracao + Cobertura 95%](#fase-8)
12. [Fase 9 — Production Readiness](#fase-9)
13. [Checklist Final](#checklist-final)

---

## 1. Diagnostico: O Que Ja Existe

### COMPLETO e Funcional

| Camada | Status | Detalhes |
|--------|--------|----------|
| **Domain/Kernel** | COMPLETO | 10 VOs: CPF, NIS, CEP, RG, Address, PersonId, PatientId, ProfessionalId, LookupId, TimeStamp. Todos com validacao no init e erros tipados. |
| **Domain/Registry** | COMPLETO | Agregado Patient (struct, EventSourced), FamilyMember entity, PatientEvents (17 eventos com actorId, 10 com before/after diff). Extensions: Lifecycle, Family, Assessments, Interventions. |
| **Domain/Care** | COMPLETO | SocialCareAppointment, AppointmentId, Diagnosis, ICDCode, IngressInfo. |
| **Domain/Protection** | COMPLETO | Referral (com state machine), RightsViolationReport, AcolhimentoHistory, ReferralId, ViolationReportId. |
| **Domain/Assessment** | COMPLETO | HousingCondition, SocioEconomicSituation, WorkAndIncome, EducationalStatus, HealthStatus, CommunitySupportNetwork, SocialHealthSummary, SocialBenefit, SocialBenefitsCollection. Analytics: Financial, Housing, Education. |
| **Application Services** | 17 SERVICOS | RegisterPatient, AddFamilyMember, RemoveFamilyMember, AssignPrimaryCaregiver, UpdateSocialIdentity, UpdateHousingCondition, UpdateSocioEconomicSituation, UpdateWorkAndIncome, UpdateEducationalStatus, UpdateHealthStatus, UpdateCommunitySupportNetwork, UpdateSocialHealthSummary, UpdatePlacementHistory, CreateReferral, ReportRightsViolation, RegisterAppointment, RegisterIntakeInfo. Cada um com Command (actorId) + UseCase protocol + Service + Errors. |
| **Application Query** | COMPLETO | GetPatientByIdQueryHandler, GetPatientByPersonIdQueryHandler, PatientRegistrationService (orquestrador de cadastro). |
| **HTTP Controllers** | 6 CONTROLLERS | PatientController (8 rotas incl. audit trail com filtro eventType), AssessmentController (7 rotas + validacao metadata-driven), ProtectionController (3 rotas + validacao metadata-driven), CareController (2 rotas), LookupController (1 rota), HealthController (2 rotas: /health + /ready). Todos com JWT auth + RBAC por role. |
| **HTTP DTOs** | COMPLETO | RequestDTOs.swift (17 request structs com `toCommand(actorId:)`, campos metadata opcionais), ResponseDTOs.swift (response structs com `computedAnalytics`, `StandardResponse<T>` wrapper, AuditTrailEntryResponse com actorId). |
| **HTTP Middleware** | COMPLETO | AppErrorMiddleware (erro global), JWTAuthMiddleware (validacao JWKS via Zitadel), RoleGuardMiddleware (RBAC por grupo de rotas). |
| **HTTP Extensions** | COMPLETO | Request+ActorId.swift (`extractActorId()` via JWT sub claim), AuthenticatedUser (model + Request storage). |
| **HTTP Validation** | COMPLETO | MetadataValidator (validacao dinamica contra flags em lookup tables) + CrossValidator (validacoes cruzadas Saude/Sexo e Acolhimento/Idade). |
| **Persistence** | COMPLETO | SQLKitPatientRepository (save com transacao SQL, find, exists), SQLKitLookupRepository, PatientDatabaseMapper (normalizado), PatientDatabaseModels (colunas diretas + 8 tabelas filhas). |
| **Migrations** | 7 MIGRATIONS | CreateInitialSchema, AddRegistrationFields, CreateLookupTables, AddV2AssessmentFields, AddPerformanceIndexes, NormalizeSchema, CreateAuditTrail. MigrationRunner com tabela `_migrations`. |
| **Outbox** | FUNCIONAL | OutboxEventBus (Transactional Outbox — eventos escritos na mesma transacao do aggregate), SQLKitOutboxRelay (polling + AsyncStream + audit trail + processed_at). |
| **Event Registry** | COMPLETO | 17 eventos registrados no DomainEventRegistryBootstrap. |
| **Audit Trail** | COMPLETO | Tabela audit_trail com actor_id, endpoint GET com filtro `?eventType=`, relay popula automaticamente. |
| **Tests** | 32 ARQUIVOS | 135 testes em 38 suites. Domain (unit) + Application (actor-based com InMemory test doubles — todos os 17 UCs cobertos) + IO/AuditTrail (pipeline completo). |

### Principios Ja Estabelecidos

- Clean Architecture + DDD rigoroso
- CQRS com typed errors (`throws(SpecificError)`)
- Event Sourcing com Transactional Outbox
- PoP: cada camada comunica via protocolo
- Strict concurrency (Sendable em tudo)
- Swift Testing (nao XCTest)
- actorId em todos os eventos e comandos (extraido do JWT sub claim — rastreabilidade de quem fez a acao)
- Before/after diff em eventos de assessment (rastreabilidade do que mudou)
- StandardResponse<T> com meta.timestamp em todos os endpoints de sucesso
- Validacao metadata-driven para beneficios e violacoes (flags dinamicos via lookup tables)
- Validacoes cruzadas via CrossValidator (Saude/Sexo-Gestante, Acolhimento/Idade)
- Calculos automaticos no GET: densidade habitacional, indicadores financeiros, perfil etario, vulnerabilidades educacionais

---

## 2. Gaps Identificados

### 2.1 — Gaps Criticos (Bloqueiam deploy)

| # | Gap | Onde | Impacto | Status |
|---|-----|------|---------|--------|
| G1 | ~~Repository nao usa transacao SQL~~ | `SQLKitPatientRepository.save()` | ~~Sem atomicidade~~ | RESOLVIDO |
| G2 | ~~Outbox relay real~~ | `SQLKitOutboxRelay.swift` | ~~Eventos nao entregues~~ | RESOLVIDO |
| G3 | ~~DELETE /family-members~~ | `PatientController.swift` | ~~Rota faltando~~ | RESOLVIDO |
| G4 | ~~AssignPrimaryCaregiver sem rota HTTP~~ | `PatientController.swift` | ~~Sem acesso via API~~ | RESOLVIDO |
| G5 | ~~Middleware de erro global~~ | `AppErrorMiddleware.swift` | ~~Erros nao formatados~~ | RESOLVIDO |
| G6 | ~~Health check / readiness~~ | `HealthController.swift` | ~~Sem endpoints /health e /ready~~ | RESOLVIDO |
| G7 | ~~PatientDatabaseModels nao persiste v2.0 fields~~ | Models + Migrations | ~~Dados perdidos~~ | RESOLVIDO (normalizado) |
| G8 | ~~Response bodies padronizados~~ | `StandardResponse<T>` | ~~Sem wrapper padrao~~ | RESOLVIDO |
| G9 | ~~Testes nao cobrem use cases v2.0~~ | Tests | ~~UpdateWorkAndIncome, UpdateEducationalStatus, UpdateHealthStatus, RegisterIngressInfo sem teste~~ | RESOLVIDO (7 suites com InMemory test doubles) |
| G10 | **Sem testes HTTP (integration)** | Tests | Nenhum teste exercita controller -> service -> domain end-to-end | PENDENTE |

### 2.2 — Gaps Moderados (Qualidade / Operacional)

| # | Gap | Detalhes | Status |
|---|-----|----------|--------|
| G11 | ~~Sem graceful shutdown~~ | ~~Vapor lifecycle hooks devem ser utilizados~~ | RESOLVIDO |
| G12 | Sem request logging / tracing | Nenhum middleware de observabilidade | PENDENTE |
| G13 | Sem CORS middleware | Necessario se front-end consome direto | PENDENTE |
| G14 | Sem rate limiting | Importante para producao | PENDENTE |
| G15 | ~~Sem JWT/Bearer auth~~ | ~~Usa `X-Actor-Id` header como placeholder~~ | RESOLVIDO (JWTAuthMiddleware + RoleGuardMiddleware + Zitadel OIDC) |
| G16 | ~~Outbox relay marca mensagens como processadas~~ | `SQLKitOutboxRelay` | RESOLVIDO |
| G17 | ~~Migration runner nao tem tabela de controle~~ | `SQLKitMigrationRunner` | RESOLVIDO |

### 2.3 — Conformidade com Front-End Forms

O backend deve implementar as regras de negocio e estruturas definidas nos arquivos `handbook/front_end_forms/*.md`.

| Modulo (Form) | Regra Principal | Status |
|---------------|-----------------|--------|
| **Composicao Familiar** | PR (Pessoa de Referencia) obrigatoria (Parentesco "01"). Perfil etario no GET. | COMPLETO (perfil etario em `computedAnalytics.ageProfile`) |
| **Habitacao** | Calculo de densidade habitacional no GET. Enums fixos. | COMPLETO (`computedAnalytics.housing.density`, `isOvercrowded`) |
| **Saude** | Validacao de gestante (sexo F). Vinculos de cuidados. | COMPLETO (`CrossValidator.validateGestatingMembers()`) |
| **Trabalho e Renda** | 4 calculos financeiros automaticos no GET. | COMPLETO (`computedAnalytics.financial`: RTF_S, RPC_S, RTG, RPC_G) |
| **Educacao** | Vulnerabilidades educacionais por faixa etaria. | COMPLETO (`computedAnalytics.educationalVulnerabilities`) |
| **Beneficios** | **Metadata-Driven**: validacao dinamica baseada em `dominio_tipo_beneficio`. | COMPLETO (`MetadataValidator.validateBenefits()`) |
| **Acolhimento** | **Validacao Cruzada**: datas e idade vs tipo de acolhimento. | COMPLETO (`CrossValidator.validatePlacementHistory()`) |
| **Violencia** | **Metadata-Driven**: campo "Outras" obrigatorio se flag ativado. | COMPLETO (`MetadataValidator.validateViolationType()`) |

---

## 3. Plano de Fases

```
FASE 0: Refinement & Alignment (Core/Application)     ██████████ COMPLETO
FASE 1: Foundation (Transacao + Migration Runner)      ██████████ COMPLETO
FASE 2: Use Cases Faltantes                            ██████████ COMPLETO
FASE 3: HTTP Layer (Vapor & Form Integration)          ██████████ COMPLETO
FASE 4: Persistencia Robusta (v2.0 fields)             ██████████ COMPLETO (normalizado)
FASE 5: Outbox Relay Real                              ██████████ COMPLETO (+ audit trail)
FASE 6: Read Side / Queries                            ██████████ COMPLETO (+ calculos automaticos)
FASE 7: Cross-Cutting (Error, Health, Auth)            ██████████ COMPLETO (health, shutdown, JWT/RBAC, Zitadel OIDC)
FASE 8: Testes (unit + integration + 95%)              █████████░ ~85% (32 arquivos, 135 testes, falta integration HTTP)
FASE 9: Production Readiness                           ██████████ COMPLETO (Dockerfile, compose, CI, README, CHANGELOG)
                                                       ─────────────────
                                                       Progresso: ~98%
```

---

## FASE 0 — Refinement & Alignment (Core/Application)

### Entregaveis Fase 0:
- [x] Auditoria de Refinement concluida (Naming + CQRS)
- [x] Suites de Teste (TDD) para Kernel/VOs criadas
- [x] **Fase 0.1: Kernel & Acronyms** — Renomear `Cpf` -> `CPF`, `Nis` -> `NIS`, `Cep` -> `CEP`, `Rg` -> `RGDocument`.
- [x] Atualizacao de referencias cruzadas (Address, CivilDocuments, Patient, Application Services).
- [x] **Fase 0.2: Application Infrastructure** — Protocolos base CQRS (`Command`, `Query`, `CommandHandling`) estabelecidos em `shared/Domain/DomainProtocols.swift`.
- [x] Todos os Application Services convertidos para `actor CommandHandler`.
- [x] Protocolos de Application seguindo `associatedtype` e `Actor` inheritance.
- [x] Todos os metodos `execute(command:)` renomeados para `handle(_:)`.
- [x] **Fase 0.3: Refinement & File Naming** — Remocao de caracteres especiais (`+`) de todos os nomes de arquivos para padroes Swiftly.
- [x] Queries de leitura (`GetPatientById`, `GetPatientByPersonId`) convertidas para `QueryHandling`.
- [x] Dominio revisado (Naming + Sendable).
- [x] Codigo 100% aderente ao Swift API Design Guidelines.

---

## FASE 1 — Solidificar o Core (Foundation)

### Entregaveis Fase 1:
- [x] `SQLKitPatientRepository.save()` usando transacao
- [x] `SQLKitMigrationRunner` com tabela `_migrations`
- [x] Migration `2026_03_06_AddV2AssessmentFields`
- [x] `PatientModel` atualizado com campos v2.0
- [x] `PatientDatabaseMapper` atualizado
- [x] Testes unitarios para o mapper com campos v2.0

---

## FASE 2 — Completar Use Cases Faltantes

### 2.1 UC implementados (17 write + 2 read):

**Write (17):**
1. RegisterPatient
2. AddFamilyMember
3. RemoveFamilyMember
4. AssignPrimaryCaregiver
5. UpdateSocialIdentity
6. UpdateHousingCondition
7. UpdateSocioEconomicSituation
8. UpdateWorkAndIncome
9. UpdateEducationalStatus
10. UpdateHealthStatus
11. UpdateCommunitySupportNetwork
12. UpdateSocialHealthSummary
13. UpdatePlacementHistory
14. CreateReferral
15. ReportRightsViolation
16. RegisterAppointment
17. RegisterIntakeInfo

**Read (2):**
1. GetPatientById
2. GetPatientByPersonId

### 2.2 UC faltantes:

| Query | Descricao | Prioridade |
|-------|-----------|------------|
| `ListPatients` | Listagem paginada (futuro) | MEDIA |

### Entregaveis Fase 2:
- [x] `GetPatientByIdQuery` + `GetPatientByIdQueryHandler`
- [x] `GetPatientByPersonIdQuery` + `GetPatientByPersonIdQueryHandler`
- [x] 17 command handlers com actorId
- [x] Todos os comandos com campo `actorId: String`

---

## FASE 3 — HTTP Layer (Vapor & Front-End Forms)

### 3.1 Controllers Implementados (5)

| Controller | Rotas | Status |
|------------|-------|--------|
| **PatientController** | `POST /patients`, `GET /patients/:id`, `GET /patients/by-person/:personId`, `POST /patients/:id/family-members`, `DELETE /patients/:id/family-members/:memberId`, `PUT /patients/:id/primary-caregiver`, `PUT /patients/:id/social-identity`, `GET /patients/:id/audit-trail` | COMPLETO |
| **AssessmentController** | `PUT` housing-condition, socioeconomic-situation (+ validacao metadata benefits), work-and-income (+ validacao metadata benefits), educational-status, health-status, community-support-network, social-health-summary | COMPLETO |
| **ProtectionController** | `PUT` placement-history, `POST` violation-reports (+ validacao metadata violacao), `POST` referrals | COMPLETO |
| **CareController** | `POST` appointments, `PUT` intake-info | COMPLETO |
| **LookupController** | `GET /dominios/:tableName` (13 tabelas permitidas) | COMPLETO |

### 3.2 Funcionalidades Transversais HTTP (COMPLETAS)

- **`StandardResponse<T>`** — wrapper padronizado com `data` + `meta.timestamp` em todos os endpoints de sucesso
- **JWT actorId** — extraido do `sub` claim do JWT (via `Request.extractActorId()`)
- **Audit trail** — `GET /patients/:id/audit-trail?eventType=` com filtro por tipo de evento
- **Before/after diff** — eventos de assessment com snapshots para rastreabilidade
- **Relay automatico** — outbox_messages -> audit_trail (com actor_id)
- **Validacao metadata-driven** — `MetadataValidator` consulta flags em `dominio_tipo_beneficio` e `dominio_tipo_violacao` antes de salvar
- **Calculos automaticos no GET** — `computedAnalytics` no `PatientResponse` com density, financial indicators, age profile, educational vulnerabilities

### 3.3 Validacoes HTTP (COMPLETAS)

- **MetadataValidator** — consulta flags em lookup tables (`dominio_tipo_beneficio`, `dominio_tipo_violacao`) antes de salvar
- **CrossValidator** — validacoes cruzadas carregando o agregado Patient:
  - Saude/Sexo: gestante deve ser sexo feminino (valida PR, demais delegados ao people-context)
  - Acolhimento/Datas: endDate >= startDate
  - Acolhimento/Idade: guarda de terceiros exige menor <18, internacao exige adolescente 12-17

### Entregaveis Fase 3:
- [x] Boilerplate Vapor configurado
- [x] 5 Controllers com 21 rotas implementadas
- [x] DTOs de request e response
- [x] `AppErrorMiddleware` global
- [x] actorId em todas as mutations via header
- [x] Audit trail com filtro por eventType
- [x] `StandardResponse<T>` wrapper com `meta.timestamp`
- [x] Calculos automaticos nos GETs (Densidade, Renda, Perfil Etario, Vulnerabilidades Educacionais)
- [x] Validacoes Metadata-Driven para Beneficios e Violacoes
- [x] Validacoes cruzadas (Acolhimento/Idade, Saude/Sexo-Gestante) via `CrossValidator`

---

## FASE 4 — Persistencia Robusta

### 4.1 Schema Normalizado (COMPLETO)

O schema foi normalizado de JSONB blobs para tabelas relacionais:

**Migrations executadas:**
1. `2026_02_24_CreateInitialSchema` — tabela patients + family_members + outbox
2. `2026_03_04_AddRegistrationFields` — campos de registro
3. `2026_03_05_CreateLookupTables` — 8 tabelas dominio_*
4. `2026_03_06_AddV2AssessmentFields` — campos v2.0 como JSONB
5. `2026_03_07_AddPerformanceIndexes` — indices de performance
6. `2026_03_08_NormalizeSchema` — normalizacao completa (JSONB -> colunas + tabelas filhas + 5 novas lookup tables com metadata)
7. `2026_03_09_CreateAuditTrail` — tabela audit_trail com actor_id

**Resultado:** ~50 colunas escalares na tabela `patients` + 8 tabelas filhas normalizadas (member_incomes, social_benefits, member_educational_profiles, program_occurrences, member_deficiencies, gestating_members, placement_registries, ingress_linked_programs) + 13 tabelas dominio_* (incl. `dominio_tipo_beneficio` com flags metadata e `dominio_tipo_violacao` com flag `exige_descricao`).

### Entregaveis Fase 4:
- [x] `PatientDatabaseMapper` normalizado (colunas diretas + tabelas filhas)
- [x] Migration de indices (`2026_03_07`)
- [x] Migration de normalizacao (`2026_03_08`)
- [x] Verificacao de Codable em todos os VOs
- [x] Mapper round-trip testado

---

## FASE 5 — Outbox Relay + Event Delivery

### Entregaveis Fase 5:
- [x] `SQLKitOutboxRelay` marcando `processed_at` apos polling
- [x] Relay com audit trail automatico (outbox -> audit_trail)
- [x] Actor-based relay com AsyncStream para multiplos consumidores
- [x] DomainEventRegistry com todos os 17 eventos
- [x] `extractFields()` para popular audit_trail com aggregateId e actorId

---

## FASE 6 — Read Side / Queries

### 6.1 Implementado

- `GET /patients/:patientId` — retorna agregado completo + `computedAnalytics`
- `GET /patients/by-person/:personId` — busca por PersonId + `computedAnalytics`
- `GET /patients/:patientId/audit-trail?eventType=` — historico de eventos

### 6.2 Calculos Automaticos no GET (COMPLETOS)

Todos retornados no campo `computedAnalytics` do `PatientResponse`:

| Calculo | Campo | Fonte | Domain Service |
|---------|-------|-------|----------------|
| Densidade habitacional | `housing.density` | membros / dormitorios | `HousingAnalyticsService.density()` |
| Superlotacao | `housing.isOvercrowded` | density > 3.0 | `HousingAnalyticsService` |
| Renda Total Trabalho (RTF_S) | `financial.totalWorkIncome` | soma rendas individuais | `FinancialAnalyticsService.calculate()` |
| Renda Per Capita Trabalho (RPC_S) | `financial.perCapitaWorkIncome` | RTF_S / membros | `FinancialAnalyticsService.calculate()` |
| Renda Total Global (RTG) | `financial.totalGlobalIncome` | trabalho + beneficios | `FinancialAnalyticsService.calculate()` |
| Renda Per Capita Global (RPC_G) | `financial.perCapitaGlobalIncome` | RTG / membros | `FinancialAnalyticsService.calculate()` |
| Perfil etario | `ageProfile.*` | 8 faixas + totalMembers | `FamilyAnalytics.calculateAgeProfile()` |
| Evasao escolar | `educationalVulnerabilities.notInSchool*` | 3 faixas (0-5, 6-14, 15-17) | `EducationAnalyticsService` |
| Analfabetismo | `educationalVulnerabilities.illiteracy*` | 3 faixas (10-17, 18-59, 60+) | `EducationAnalyticsService` |

### Entregaveis Fase 6:
- [x] `GetPatientByIdQueryHandler`
- [x] `GetPatientByPersonIdQueryHandler`
- [x] Handler `GET /patients/:patientId` no controller
- [x] Audit trail com filtro por eventType
- [x] Calculos automaticos: densidade, financeiro, perfil etario, vulnerabilidades educacionais

---

## FASE 7 — Cross-Cutting Concerns

### 7.1 Implementado
- [x] Middleware de erro global (`AppErrorMiddleware`)
- [x] Rastreabilidade de ator (JWT `sub` claim via `Request.extractActorId()`)
- [x] Audit trail com actorId + before/after diff
- [x] `StandardResponse<T>` wrapper padronizado com `meta.timestamp`
- [x] Validacao metadata-driven (`MetadataValidator`)
- [x] Validacoes cruzadas (`CrossValidator`)
- [x] Health check (`GET /health`) e readiness (`GET /ready` — testa conexao DB)
- [x] Graceful shutdown (Vapor lifecycle hooks — `GracefulShutdownHandler` com log de startup/shutdown, compativel com SIGTERM do K8s)
- [x] JWT Authentication (`JWTAuthMiddleware` — valida tokens via JWKS do Zitadel, skipa /health e /ready)
- [x] RBAC (`RoleGuardMiddleware` — 3 roles: `social_worker` full CRUD, `owner` read-only, `admin` read-only + gestao)

### 7.2 Autenticacao e Autorizacao (Zitadel OIDC)

**Identity Provider:** Zitadel (self-hosted, deploy via FluxCD HelmRelease no K3s)
**Dominio:** `auth.acdgbrasil.com.br`
**Flow:** Authorization Code + PKCE

| Componente | Arquivo | Descricao |
|------------|---------|-----------|
| `ZitadelJWTPayload` | `IO/HTTP/Auth/ZitadelJWTPayload.swift` | Decodifica JWT com claim `urn:zitadel:iam:org:project:roles` |
| `AuthenticatedUser` | `IO/HTTP/Auth/AuthenticatedUser.swift` | Model com userId + roles, armazenado no Request.storage |
| `JWTAuthMiddleware` | `IO/HTTP/Middleware/JWTAuthMiddleware.swift` | Valida JWT via JWKS, popula authenticatedUser. Skipa /health e /ready |
| `RoleGuardMiddleware` | `IO/HTTP/Middleware/RoleGuardMiddleware.swift` | Verifica se usuario tem role permitida para o grupo de rotas |

**Mapa de permissoes por controller:**

| Controller | Operacao | Roles permitidas |
|------------|----------|-----------------|
| PatientController | GET (read) | `social_worker`, `owner`, `admin` |
| PatientController | POST/PUT/DELETE (write) | `social_worker` |
| AssessmentController | PUT (write) | `social_worker` |
| CareController | POST/PUT (write) | `social_worker` |
| ProtectionController | PUT/POST (write) | `social_worker` |
| LookupController | GET (read) | `social_worker`, `owner`, `admin` |
| HealthController | GET (public) | Sem autenticacao (skipped pelo JWTAuthMiddleware) |

### 7.3 Decisoes de Arquitetura (Edge Cloud)

| Item | Decisao | Motivo |
|------|---------|--------|
| CORS | **Resolvido no Caddy (VPS Gateway)** | Caddy e o ponto de entrada publico; headers CORS globais la evitam duplicacao no app. |
| Auth/JWT | **Implementado no app** | JWTAuthMiddleware valida tokens JWT via JWKS do Zitadel. actorId extraido do `sub` claim. |
| Authorization (roles) | **Implementado no app** | RoleGuardMiddleware com 3 roles: social_worker (CRUD), owner (read), admin (read + gestao). |
| Request logging | **Simplificado** | Traefik (ingress K3s) ja faz access log. O app usa o Logger padrao do Vapor para eventos de negocio. |

### Entregaveis Fase 7:
- [x] Middleware de erro global
- [x] Rastreabilidade (actorId via JWT + audit trail)
- [x] StandardResponse wrapper
- [x] Validacao metadata-driven + cruzada
- [x] Health check + readiness endpoints (`HealthController`)
- [x] Graceful shutdown (`GracefulShutdownHandler`)
- [x] CORS (Caddy — infra, nao app)
- [x] Request logging (Traefik access log + Vapor Logger)
- [x] JWT Authentication (JWTAuthMiddleware + JWKS do Zitadel)
- [x] RBAC Authorization (RoleGuardMiddleware — social_worker, owner, admin)

---

## FASE 8 — Testes Completos + 95% Cobertura

**Estrategia de Testes Hibrida:**
- **Domain Layer:** Testes UNITARIOS exaustivos. Foco em logica de negocio, VOs e Agregados. Sem dependencias de IO.
- **Application Layer:** Testes com **InMemory test doubles (Actors)**. `InMemoryPatientRepository`, `InMemoryEventBus`, `InMemoryLookupValidator` — todos Actors para garantir concorrencia real. `AllowAllLookupValidator` (struct) como atalho quando lookup nao e o foco do teste. `PatientFixture` para criacao de pacientes de teste. Cada suite testa: cenario feliz, erros de validacao, paciente nao encontrado, e isolamento de Actor (chamadas concorrentes via `async let`).
- **IO Layer:** Testes de integracao de API (VaporTesting) contra a camada de Application real.

### 8.1 Estado Atual dos Testes

**32 arquivos de teste, 135 testes em 38 suites:**

**Domain (14 arquivos, 58 testes, 20 suites):**
- CPFTests, NISTests, CEPTests, RGDocumentTests (Kernel VOs)
- LookupIdTests, LookupValidatingTests (Kernel)
- TimeStampAgeTests (Kernel)
- PatientMutationsTests, PatientDetailedTests, EntitySpecificationTests (Agregado)
- CodeReviewRegressionTests (Regressao)
- DomainErrorCoverageTests (Erros)
- DomainAnalyticsSpecificationTests, AnalyticsConsistencyTests (Analytics)

**Application (17 arquivos, 67 testes, 17 suites):**

*UCs v2.0 (7 suites, 27 testes):*
- UpdateWorkAndIncomeTests (4 testes: sucesso, lookup invalido, paciente nao encontrado, concorrencia)
- UpdateEducationalStatusTests (3 testes: sucesso, lookup invalido, paciente nao encontrado)
- UpdateHealthStatusTests (4 testes: sucesso, lookup invalido, paciente nao encontrado, actor serialization)
- RegisterIntakeInfoTests (5 testes: sucesso, lookup ingresso invalido, lookup programa invalido, paciente nao encontrado, handlers concorrentes)
- UpdateCommunitySupportNetworkTests (4 testes: sucesso, paciente nao encontrado, id invalido, concorrencia)
- UpdateSocialHealthSummaryTests (3 testes: sucesso, paciente nao encontrado, actor serialization)
- UpdatePlacementHistoryTests (4 testes: sucesso, membro nao pertence a familia, paciente nao encontrado, actor serialization)

*UCs originais (10 suites, 40 testes):*
- RegisterPatientTests (6 testes: minimo, com dados pessoais, personId duplicado, lookup invalido, ICD vazio, concorrencia)
- AddFamilyMemberTests (4 testes: sucesso, membro duplicado, paciente nao encontrado, lookup invalido)
- RemoveFamilyMemberTests (3 testes: sucesso, membro nao encontrado, paciente nao encontrado)
- AssignPrimaryCaregiverTests (3 testes: sucesso, membro nao na familia, paciente nao encontrado)
- UpdateSocialIdentityTests (3 testes: sucesso, lookup invalido, paciente nao encontrado)
- UpdateHousingConditionTests (4 testes: sucesso, tipo invalido, paciente nao encontrado, concorrencia)
- UpdateSocioEconomicSituationTests (4 testes: sucesso, sem beneficios, paciente nao encontrado, concorrencia)
- CreateReferralTests (4 testes: sucesso, servico invalido, paciente nao encontrado, concorrencia)
- ReportRightsViolationTests (4 testes: sucesso, tipo invalido, paciente nao encontrado, concorrencia)
- RegisterAppointmentTests (5 testes: sucesso, tipo default, tipo invalido, paciente nao encontrado, concorrencia)

**IO (1 arquivo, 10 testes, 1 suite):**
- AuditTrailTests (10 testes: registry decode, registry tipo invalido, toOutbox modelo, payload com actorId/patientId, toOutbox vazio, toOutbox event_types, response mapping, nil actor_id, round-trip single, round-trip multi)

**Test Doubles (4 arquivos):**
- InMemoryPatientRepository (Actor)
- InMemoryEventBus (Actor)
- InMemoryLookupValidator (Actor) + AllowAllLookupValidator (Struct)
- PatientFixture (factory com createMinimal, createWithFemalePR, createWithAdditionalMember)

### 8.2 Testes Faltantes

| Teste | Cobre | Prioridade | Status |
|-------|-------|------------|--------|
| ~~`UpdateWorkAndIncomeTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateEducationalStatusTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateHealthStatusTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`RegisterIntakeInfoTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateCommunitySupportNetworkTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateSocialHealthSummaryTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`UpdatePlacementHistoryTests`~~ | ~~UC v2.0~~ | ~~ALTA~~ | FEITO |
| ~~`RegisterPatientTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`AddFamilyMemberTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`RemoveFamilyMemberTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`AssignPrimaryCaregiverTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateSocialIdentityTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateHousingConditionTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`UpdateSocioEconomicSituationTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`CreateReferralTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`ReportRightsViolationTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| ~~`RegisterAppointmentTests`~~ | ~~UC original~~ | ~~ALTA~~ | FEITO |
| Testes de integracao HTTP (VaporTesting) | End-to-end | ALTA | PENDENTE |
| `OutboxRelayTests` | Relay polling | MEDIA | PENDENTE |
| ~~`AuditTrailTests`~~ | ~~Audit trail pipeline~~ | ~~MEDIA~~ | FEITO (10 testes: registry, outbox mapper, response DTO, round-trip) |
| `ErrorMiddlewareTests` | Middleware de erro | MEDIA | PENDENTE |

### Entregaveis Fase 8:
- [x] 17 suites de teste Application (todos os UCs) com Actor-based InMemory test doubles
- [x] 4 test doubles (InMemoryPatientRepository, InMemoryEventBus, InMemoryLookupValidator, PatientFixture)
- [x] Testes de audit trail (pipeline: DomainEventRegistry, Outbox mapper, AuditTrailEntryResponse, round-trip — 10 testes)
- [ ] ~8 testes de integracao HTTP (VaporTesting)
- [ ] `make coverage` passando com >= 95%

---

## FASE 9 — Production Readiness

### 9.1 Implementado
- [x] Dockerfile (multi-stage: swift:6.2-jammy build + slim runtime)
- [x] .dockerignore
- [x] `docker-compose.yml` (PostgreSQL + app com healthcheck)
- [x] `.env.example` completo (PORT, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME)
- [x] CI pipeline (`ci.yml`: resolve + build-release + coverage gate 95%)
- [x] Release pipeline (`release-ghcr.yml`: reusable workflow + GHCR + tags sha/semver/latest)
- [x] README.md atualizado (arquitetura, rotas, deploy Edge Cloud, variaveis de ambiente)
- [x] CHANGELOG.md atualizado (historico completo desde v0.1.0)

### Entregaveis Fase 9:
- [x] Dockerfile
- [x] `docker-compose.yml`
- [x] `.env.example` completo
- [x] CI atualizado
- [x] README.md atualizado
- [x] CHANGELOG.md atualizado

---

## Checklist Final

Quando TODOS os itens abaixo estiverem marcados, o microservico esta pronto para deploy:

### Domain
- [x] Todos os VOs com validacao no init
- [x] Agregado Patient com Event Sourcing
- [x] 17 eventos de dominio (todos com actorId, 10 com before/after)
- [x] Modulos v2.0 (WorkAndIncome, Educational, Health, Acolhimento, Ingress)
- [x] Analytics services (Financial, Housing, Education, FamilyAgeProfile)

### Application
- [x] 17 use cases de escrita implementados (todos com actorId)
- [x] 2 use cases de leitura implementados
- [ ] Testes unitarios para TODOS os use cases

### HTTP (I/O - Vapor)
- [x] 6 Controllers com 23 rotas implementadas
- [x] Padrao **CRU** rigoroso (Delete somente em family-members)
- [x] `AppErrorMiddleware` global
- [x] actorId via JWT `sub` claim em todas as mutations
- [x] Audit trail com filtro `?eventType=`
- [x] Before/after diff nos eventos de assessment
- [x] `StandardResponse<T>` wrapper com `meta.timestamp`
- [x] Logica **Metadata-Driven** (Beneficios via `dominio_tipo_beneficio`, Violencia via `dominio_tipo_violacao`)
- [x] Calculos automaticos no GET (Densidade, Renda 4 indicadores, Perfil Etario, Vulnerabilidades Educacionais)
- [x] Validacoes cruzadas (Acolhimento/Idade, Saude/Sexo-Gestante) via `CrossValidator`
- [x] Health check + readiness (`HealthController` — /health liveness, /ready testa DB)
- [x] Graceful shutdown (`GracefulShutdownHandler` — compativel com SIGTERM/K8s)
- [x] CORS (resolvido no Caddy/VPS Gateway — decisao de infra)
- [x] Request logging (Traefik access log + Vapor Logger)
- [x] JWT Authentication (`JWTAuthMiddleware` — JWKS via Zitadel OIDC)
- [x] RBAC Authorization (`RoleGuardMiddleware` — social_worker, owner, admin)

### Persistencia (I/O)
- [x] Repository usando transacao SQL
- [x] Migration runner com tabela `_migrations`
- [x] Schema normalizado (JSONB -> colunas + tabelas filhas)
- [x] 7 migrations (initial, registration, lookups, v2, indexes, normalize, audit)
- [x] Indices de performance
- [x] Mapper atualizado com round-trip testado
- [x] Lookup tables com metadata flags (exige_registro_nascimento, exige_cpf_falecido, exige_descricao)

### Outbox / Events / Audit
- [x] Relay funcionando com polling real (SQLKitOutboxRelay)
- [x] Mensagens marcadas como processadas (processed_at)
- [x] Todos os 17 eventos registrados (DomainEventRegistryBootstrap)
- [x] Audit trail automatico (outbox -> audit_trail)
- [x] actor_id populado no audit trail
- [x] Endpoint de consulta com filtro por eventType

### Testes
- [x] Testes Application para todos os 17 UCs (Actor-based InMemory test doubles, 67 testes)
- [x] Testes de audit trail (DomainEventRegistry, Outbox mapper, AuditTrailEntryResponse, round-trip — 10 testes)
- [ ] Testes de integracao HTTP (VaporTesting)
- [ ] Cobertura >= 95%

### Producao
- [x] Dockerfile
- [x] docker-compose.yml (PostgreSQL + app)
- [x] .env.example completo
- [x] CI pipeline completo (ci.yml + release-ghcr.yml)
- [x] README atualizado
- [x] CHANGELOG atualizado
- [x] Graceful shutdown

---

## Ordem de Execucao Recomendada (Itens Restantes)

```
Prioridade 1:  Testes de integracao HTTP (VaporTesting)
Prioridade 2:  Testes de Outbox/AuditTrail/ErrorMiddleware (MEDIA prioridade)
```

> **Nota:** Progresso geral estimado em ~98%. As fases 0-7 e 9 estao completas (incluindo JWT auth e RBAC com Zitadel). Fase 8: todos os 17 UCs cobertos por testes Application (67 testes). Restam apenas testes de integracao HTTP e cobertura >= 95%.
