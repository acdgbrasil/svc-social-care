# Plano de Implementacao — social-care (Conclusao do Microservico)

> **ATENCAO:** O contrato OpenAPI em `contracts/` esta TOTALMENTE DESATUALIZADO e NÃO deve ser utilizado.
> **Fonte de Verdade Única:** Documentos em `handbook/front_end_forms/`.
> **Padrao de Idioma:** Todos os DTOs e caminhos de API devem ser em INGLES (mapeados a partir das especificações em PT-BR).
> **Padrao de Codigo:** CamelCase e Ingles para todos os simbolos (Variables, Constants, Enums, Classes, Protocols, Structs), seguindo rigorosamente o [Swift API Design Guidelines](tooling/swift/api-design-guidelines/index.md).
> **Escopo de Operação:** Padrão **CRU** (Create, Read, Update). A operação **Delete** é proibida em quase todos os domínios para garantir rastreabilidade.

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
| **Domain/Registry** | COMPLETO | Agregado Patient (struct, EventSourced), FamilyMember entity, PatientEvents (7 eventos), PersonalData, CivilDocuments, SocialIdentity. Extensions: Lifecycle, Family, Assessments, Interventions. |
| **Domain/Care** | COMPLETO | SocialCareAppointment, AppointmentId, Diagnosis, ICDCode, IngressInfo. |
| **Domain/Protection** | COMPLETO | Referral (com state machine), RightsViolationReport, AcolhimentoHistory, ReferralId, ViolationReportId. |
| **Domain/Assessment** | COMPLETO | HousingCondition, SocioEconomicSituation, WorkAndIncome, EducationalStatus, HealthStatus, CommunitySupportNetwork, SocialHealthSummary, SocialBenefit, SocialBenefitsCollection. Analytics: Financial, Housing, Education. |
| **Application Services** | 14 SERVICOS | RegisterPatient, AddFamilyMember, RemoveFamilyMember, AssignPrimaryCaregiver, UpdateSocialIdentity, UpdateHousingCondition, UpdateSocioEconomicSituation, UpdateWorkAndIncome, UpdateEducationalStatus, UpdateHealthStatus, CreateReferral, ReportRightsViolation, RegisterAppointment, RegisterIngressInfo. Cada um com Command + UseCase protocol + Service + Errors. |
| **Application Query** | PARCIAL | PatientRegistrationService (orquestrador de cadastro). |
| **HTTP Controllers** | REMOVIDO | Migrando de Hummingbird para **Vapor**. Todo o código anterior foi removido. |
| **HTTP DTOs** | REMOVIDO | A serem recriados conforme **Front-End Forms** e padrões Vapor. |
| **HTTP Mappers** | REMOVIDO | A serem recriados para a nova camada de I/O. |
| **Persistence** | FUNCIONAL | SQLKitPatientRepository (save, find, exists), SQLKitLookupRepository, PatientDatabaseMapper, PatientDatabaseModels (6 modelos), 3 Migrations. |
| **Outbox** | ESQUELETO | OutboxEventBus (actor, publish noop), SQLKitOutboxRelay (polling + AsyncStream). |
| **Contracts** | OBSOLETO | OpenAPI/AsyncAPI desatualizados. Ignorar. |
| **Tests** | 16 ARQUIVOS | Domain v2 (7 suites), Application (3 suites), IO (3 suites), Shared (1 suite). |

### Principios Ja Estabelecidos

- Clean Architecture + DDD rigoroso
- CQRS com typed errors (`throws(SpecificError)`)
- Event Sourcing com Transactional Outbox
- PoP: cada camada comunica via protocolo
- Strict concurrency (Sendable em tudo)
- Swift Testing (nao XCTest)

---

## 2. Gaps Identificados

### 2.1 — Gaps Criticos (Bloqueiam deploy)

| # | Gap | Onde | Impacto |
|---|-----|------|---------|
| G1 | **Repository nao usa transacao SQL** | `SQLKitPatientRepository.save()` | Sem atomicidade — aggregate + outbox podem ficar inconsistentes |
| G2 | **Outbox relay real** | `OutboxEventBus.swift` | Eventos entregues via polling; relay iniciado no boot |
| G3 | **DELETE /family-members** | `RegistryController.swift` | Rota implementada e vinculada ao Use Case |
| G4 | **AssignPrimaryCaregiver sem rota HTTP** | Front-End Forms definem fluxos, UC existe | Decidir se expoe via HTTP ou fica interno |
| G5 | **Middleware de erro global** | `GlobalErrorMiddleware.swift` | Intercepta erros e formata JSON padronizado |
| G6 | **Health check / readiness** | `HealthController.swift` | Endpoints /health e /ready implementados |
| G7 | **PatientDatabaseModels nao persiste v2.0 fields** | Models + Migrations | WorkAndIncome, EducationalStatus, HealthStatus, AcolhimentoHistory, IngressInfo existem no domain mas NAO no DB |
| G8 | **Response bodies padronizados** | `StandardResponse.swift` | Wrapper `StandardResponse<T>` em todos os endpoints de sucesso |
| G9 | **Testes nao cobrem use cases v2.0** | Tests | UpdateWorkAndIncome, UpdateEducationalStatus, UpdateHealthStatus, RegisterIngressInfo sem teste |
| G10 | **Sem testes HTTP (integration)** | Tests | Nenhum teste exercita controller → service → domain end-to-end |

### 2.2 — Gaps Moderados (Qualidade / Operacional)

| # | Gap | Detalhes |
|---|-----|----------|
| G11 | Sem graceful shutdown | Vapor lifecycle hooks devem ser utilizados |
| G12 | Sem request logging / tracing | Nenhum middleware de observabilidade |
| G13 | Sem CORS middleware | Necessario se front-end consome direto |
| G14 | Sem rate limiting | Importante para producao |
| G15 | Sem JWT/Bearer auth | Exigência de segurança, código ignora |
| G16 | Outbox relay marca mensagens como processadas | `SQLKitOutboxRelay` | Bulk update processado após distribuição |

| G17 | Migration runner nao tem tabela de controle | `SQLKitMigrationRunner` nao persiste quais migrations ja rodaram |

### 2.3 — Conformidade com Front-End Forms

O backend deve implementar as regras de negócio e estruturas definidas nos arquivos `handbook/front_end_forms/*.md`.

| Módulo (Form) | Regra Principal | Status |
|---------------|-----------------|--------|
| **Composição Familiar** | PR (Pessoa de Referência) obrigatória (Parentesco "01"). Perfil etário no GET. | Faltando no I/O |
| **Habitação** | Cálculo de densidade habitacional no GET. Enums fixos. | Faltando no I/O |
| **Saúde** | Validação de gestante (sexo F). Vínculos de cuidados. | Faltando no I/O |
| **Trabalho e Renda** | 4 cálculos financeiros automáticos no GET. | Faltando no I/O |
| **Benefícios** | **Metadata-Driven**: validação dinâmica baseada em `dominio_tipo_beneficio`. | Faltando no I/O |
| **Acolhimento** | **Validação Cruzada**: datas e idade vs tipo de acolhimento. | Faltando no I/O |
| **Violência** | **Metadata-Driven**: campo "Outras" obrigatório se flag ativado. | Faltando no I/O |

---

## 3. Plano de Fases

```
FASE 0: Refinement & Alignment (Core/Application)     ████████░░ ~3 dias
FASE 1: Foundation (Transacao + Migration Runner)     ████░░░░░░ ~2 dias
FASE 2: Use Cases Faltantes                           ██░░░░░░░░ ~1 dia
FASE 3: HTTP Layer (Vapor & Form Integration)         ████████░░ ~3 dias
FASE 4: Persistencia Robusta (v2.0 fields)             ████░░░░░░ ~2 dias
FASE 5: Outbox Relay Real                              ███░░░░░░░ ~1-2 dias
FASE 6: Read Side / Queries                            ███░░░░░░░ ~1-2 dias
FASE 7: Cross-Cutting (Error, Health, Auth)            █████░░░░░ ~2-3 dias
FASE 8: Testes (unit + integration + 95%)              ██████░░░░ ~3 dias
FASE 9: Production Readiness                           ███░░░░░░░ ~1-2 dias
                                                       ─────────────────
                                                       Total: ~19-23 dias
```

---

## FASE 0 — Refinement & Alignment (Core/Application)

**Objetivo:** Revisar e otimizar todo o Domínio e camada de Application para seguir o [Swift API Design Guidelines](tooling/swift/api-design-guidelines/index.md) e o [Guia CQRS](tooling/swift/CQRS/index.md).

### 0.1 Nomenclatura e Estilo (Swift Guidelines)
- **Inglês & CamelCase:** Revisar todas as `Variables`, `Constants`, `Enums`, `Classes`, `Protocols` e `Structs`.
- **Clarity at Point of Use:** Renomear métodos para formarem frases gramaticais em Inglês (ex: `addFamilyMember(_:)` em vez de `executeAddFamilyMember`).
- **Omit Needless Words:** Remover redundâncias de tipo nos nomes (ex: `Patient.id` em vez de `Patient.patientId` quando o contexto é claro).

### 0.2 Otimização CQRS (Swift Idiomatic)
- **Command Side (Write):**
    - Todos os `CommandHandlers` devem ser **Actors** (`protocol CommandHandling: Actor`).
    - Commands devem ser `structs` imutáveis e conformar a `Sendable` (sintetizado).
    - Commands **não retornam dados de domínio**, apenas o identificador (UUID) via `ResultCommand`.
- **Query Side (Read):**
    - `QueryHandlers` devem ser `structs` puras (`protocol QueryHandling`).
    - Uso de `some QueryHandling` em factories para ocultar implementação.
    - Uso de `async let` para buscas paralelas em queries complexas.
- **Event Bus:**
    - Revisar `EventBus` para usar `any DomainEvent` em coleções heterogêneas e `as?` para despacho seguro.

### 0.3 Concorrência e Segurança
- **Sendable:** Garantir que todos os VOs e DTOs que cruzam domínios de concorrência são `Sendable`.
- **Memory Safety:** Revisar uso de `inout` e mutabilidade para evitar conflitos de acesso.

### Entregaveis Fase 0:
- [x] Auditoria de Refinement concluída (Naming + CQRS)
- [x] Suítes de Teste (TDD) para Kernel/VOs criadas
- [x] **Fase 0.1: Kernel & Acronyms** — Renomear `Cpf` -> `CPF`, `Nis` -> `NIS`, `Cep` -> `CEP`, `Rg` -> `RGDocument`.
- [x] Atualização de referências cruzadas (Address, CivilDocuments, Patient, Application Services).
- [x] **Fase 0.2: Application Infrastructure** — Protocolos base CQRS (`Command`, `Query`, `CommandHandling`) estabelecidos em `shared/Domain/DomainProtocols.swift`.
- [x] Todos os Application Services convertidos para `actor CommandHandler`.
- [x] Protocolos de Application seguindo `associatedtype` e `Actor` inheritance.
- [x] Todos os métodos `execute(command:)` renomeados para `handle(_:)`.
- [x] **Fase 0.3: Refinement & File Naming** — Remoção de caracteres especiais (`+`) de todos os nomes de arquivos para padrões Swiftly.
- [x] Queries de leitura (`GetPatientById`, `GetPatientByPersonId`) convertidas para `QueryHandling`.
- [x] Domínio revisado (Naming + Sendable).
- [x] Código 100% aderente ao Swift API Design Guidelines.


---

## FASE 1 — Solidificar o Core (Foundation)

**Objetivo:** Garantir que a base de infraestrutura e confiavel antes de construir em cima.

### 1.1 Transacao SQL no Repository

**Arquivo:** `IO/Persistence/SQLKit/SQLKitPatientRepository.swift`

**Problema:** `save()` executa ~12 queries SQL sequenciais sem transacao. Se qualquer query falhar no meio, o banco fica inconsistente.

**Solucao:**
```swift
func save(_ patient: Patient) async throws {
    try await db.transaction { tx in
        // Todas as operacoes dentro da transacao
        let data = try PatientDatabaseMapper.toDatabase(patient)
        // ... upsert + delete-and-insert + outbox ...
    }
}
```

**Arquivos a alterar:**
- `SQLKitPatientRepository.swift` — wrapping em `db.transaction`

### 1.2 Migration Runner com Tabela de Controle

**Arquivo:** `IO/Persistence/SQLKit/Migrations/SQLKitMigrationRunner.swift`

**Problema:** Nao ha tabela `_migrations` para rastrear quais ja rodaram. Se reiniciar o server, tenta rodar tudo de novo.

**Solucao:**
- Criar tabela `_migrations` (name TEXT PK, applied_at TIMESTAMP)
- No `run()`, verificar quais ja foram aplicadas antes de executar
- Apos sucesso, inserir registro na tabela

**Arquivos a criar/alterar:**
- `SQLKitMigrationRunner.swift` — refatorar para consultar `_migrations`

### 1.3 Migration para Campos v2.0

**Problema:** Domain tem WorkAndIncome, EducationalStatus, HealthStatus, AcolhimentoHistory, IngressInfo, mas o banco nao tem colunas correspondentes.

**Solucao:** Nova migration `2026_03_06_AddV2AssessmentFields.swift`:

```sql
ALTER TABLE patients ADD COLUMN work_and_income JSONB;
ALTER TABLE patients ADD COLUMN educational_status JSONB;
ALTER TABLE patients ADD COLUMN health_status JSONB;
ALTER TABLE patients ADD COLUMN acolhimento_history JSONB;
ALTER TABLE patients ADD COLUMN ingress_info JSONB;
```

**Arquivos a criar:**
- `IO/Persistence/SQLKit/Migrations/2026_03_06_AddV2AssessmentFields.swift`

**Arquivos a alterar:**
- `PatientDatabaseModels.swift` — adicionar 5 campos opcionais ao `PatientModel`
- `PatientDatabaseMapper.swift` — mapear os 5 novos campos (toDomain e toDatabase)
- `ApplicationContext.swift` — registrar nova migration no runner

### Entregaveis Fase 1:
- [x] `SQLKitPatientRepository.save()` usando transacao
- [x] `SQLKitMigrationRunner` com tabela `_migrations`
- [x] Migration `2026_03_06_AddV2AssessmentFields`
- [x] `PatientModel` atualizado com 5 campos v2.0
- [x] `PatientDatabaseMapper` atualizado
- [x] Testes unitarios para o mapper com campos v2.0


---

## FASE 2 — Completar Use Cases Faltantes

**Objetivo:** Garantir que todos os casos de uso que o dominio suporta tem servico de aplicacao.

### 2.1 UC ja implementados (14):
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
11. CreateReferral
12. ReportRightsViolation
13. RegisterAppointment
14. RegisterIngressInfo

### 2.2 UC faltantes para completar o contrato:

**Nenhum use case de escrita novo e necessario.** Todos os endpoints do OpenAPI tem UC correspondente.

Porem, faltam **UC de leitura (queries)**:

| Query | Descricao | Prioridade |
|-------|-----------|------------|
| `GetPatientById` | Retorna o agregado completo de um paciente | ALTA |
| `GetPatientByPersonId` | Busca paciente por PersonId | ALTA |
| `ListPatients` | Listagem paginada (futuro) | MEDIA |

### Entregaveis Fase 2:
- [x] `GetPatientByIdQuery` + `GetPatientByIdService`
- [x] `GetPatientByPersonIdQuery` + `GetPatientByPersonIdService`
- [x] Testes unitarios para cada query service

---

## FASE 3 — HTTP Layer (Vapor & Front-End Forms)

**Objetivo:** Implementar a camada HTTP usando **Vapor**, seguindo rigorosamente as especificações de formulários em `handbook/front_end_forms/`.

### 3.1 Decisao Arquitetural: Paths (RESTful)

Mapeamento das telas para endpoints (em Inglês):
```
POST   /patients                                    (Registry)
POST   /patients/{id}/family-members                (Composition)
GET    /patients/{id}/housing                       (Habitação)
POST   /patients/{id}/housing                       (Habitação)
GET    /patients/{id}/health                        (Saúde)
POST   /patients/{id}/health                        (Saúde)
GET    /patients/{id}/income                        (Renda)
POST   /patients/{id}/income                        (Renda)
GET    /patients/{id}/benefits                      (Benefícios)
POST   /patients/{id}/benefits                      (Benefícios)
GET    /patients/{id}/protection-history            (Acolhimento/Socioeducativa)
```

### 3.2 Rotas no Vapor (Routes.swift)

```swift
func boot(routes: RoutesBuilder) throws {
    let api = routes.grouped("api", "v1")
    let patients = api.grouped("patients")

    patients.post(use: registry.handleRegister)
    
    patients.group(":patientId") { patient in
        patient.get(use: query.handleGetPatient)
        
        // Composição
        patient.group("family-members") { family in
            family.post(use: registry.handleAddFamily)
        }
        
        // Módulos CRU
        patient.group("housing") { h in
            h.get(use: assessment.handleGetHousing)
            h.post(use: assessment.handleUpdateHousing)
        }
    }
}
```

### 3.3 Lógica Metadata-Driven (BFF)

Para Benefícios e Violência, o Controller deve:
1. Consultar a tabela de domínio no DB.
2. Aplicar as validações baseadas nos flags (ex: `exige_certidao`).
3. Rejeitar a requisição antes de chamar o Use Case se falhar.

### 3.4 Response Bodies Padronizados

Criar DTOs de resposta que suportem os cálculos automáticos (Densidade, Renda, Vulnerabilidades) e mapeiem os nomes de campos das especificações.

### 3.5 Middleware de Erro Global (Vapor)

```swift
struct AppErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let error as any AppErrorConvertible {
             // Mapeia AppError -> JSON padronizado (code, message)
        } catch {
            // Internal Server Error
        }
    }
}
```

### Entregaveis Fase 3:
- [ ] Boilerplate Vapor configurado
- [ ] Handlers `POST /patients` e `POST /family-members`
- [ ] DTOs de resposta com cálculos (Densidade, Renda)
- [ ] `AppErrorMiddleware` global
- [ ] Validações Metadata-Driven para Benefícios

---

## FASE 4 — Persistencia Robusta

**Objetivo:** Garantir que todos os dados do dominio sao persistidos e recuperados corretamente.

### 4.1 PatientDatabaseMapper — Campos v2.0

Atualizar `toDomain()` e `toDatabase()` para incluir:
- `work_and_income` (JSONB)
- `educational_status` (JSONB)
- `health_status` (JSONB)
- `acolhimento_history` (JSONB)
- `ingress_info` (JSONB)

Cada campo e um VO Codable, entao basta usar `JSONEncoder`/`JSONDecoder`.

### 4.2 Indices de Performance

Nova migration com indices:
```sql
CREATE UNIQUE INDEX idx_patients_person_id ON patients(person_id);
CREATE INDEX idx_family_members_patient_id ON family_members(patient_id);
CREATE INDEX idx_outbox_unprocessed ON outbox_messages(processed_at) WHERE processed_at IS NULL;
```

### 4.3 Codable Conformance para VOs

Verificar e garantir que todos os VOs novos implementam `Codable`:
- WorkAndIncome
- EducationalStatus
- HealthStatus
- AcolhimentoHistory
- IngressInfo

### Entregaveis Fase 4:
- [ ] `PatientDatabaseMapper` atualizado com 5 campos v2.0
- [ ] Migration de indices
- [ ] Verificacao de Codable em todos os VOs
- [ ] Testes de round-trip (domain -> db -> domain) para cada campo

---

## FASE 5 — Outbox Relay + Event Delivery

**Objetivo:** Fazer o Transactional Outbox funcionar de verdade.

### 5.1 OutboxEventBus — Implementacao Real

Atualmente `publish()` e um noop. Opcoes:

**Opcao A (recomendada para MVP):** Manter o relay baseado em polling, mas garantir que:
1. O relay e iniciado no `ApplicationContext.start()`
2. O relay faz polling periodico (ex: a cada 5s)
3. Apos processar, faz `UPDATE outbox_messages SET processed_at = NOW() WHERE id = ?`
4. Eventos sao logados (para futuro broker)

**Opcao B (futuro):** Integrar com Kafka/RabbitMQ.

### 5.2 SQLKitOutboxRelay — Completar

O relay ja tem a estrutura de polling + AsyncStream. Falta:
- Marcar mensagens como `processed_at = NOW()` apos distribuicao
- Tratamento de erro (retry? dead letter?)
- Inicializacao automatica no boot da aplicacao

### 5.3 DomainEventRegistry+Bootstrap — Verificar

Garantir que TODOS os 7 tipos de evento estao registrados:
- PatientCreatedEvent
- FamilyMemberAddedEvent
- FamilyMemberRemovedEvent
- PrimaryCaregiverAssignedEvent
- ReferralCreatedEvent
- RightsViolationReportedEvent
- SocialCareAppointmentRegisteredEvent

### Entregaveis Fase 5:
- [ ] `SQLKitOutboxRelay` marcando `processed_at` apos polling
- [ ] Relay iniciado automaticamente no `ApplicationContext.start()`
- [ ] Log de eventos processados
- [ ] DomainEventRegistry com todos os 7 eventos
- [ ] Teste unitário do relay (mock DB)

---

## FASE 6 — Read Side / Queries

**Objetivo:** Implementar endpoints de leitura.

### 6.1 GET /patients/{patientId}

**Response:** JSON completo do Patient com todos os sub-recursos.

```swift
struct PatientDetailDTO: Codable, Sendable {
    let patientId: String
    let personId: String
    let personalData: PersonalDataDTO?
    let civilDocuments: CivilDocumentsDTO?
    let address: AddressDTO?
    let diagnoses: [DiagnosisDTO]
    let familyMembers: [FamilyMemberDTO]
    let housingCondition: HousingConditionDTO?
    let socioeconomicSituation: SocioEconomicSituationDTO?
    // ... todos os campos
}
```

### 6.2 Read Model vs Aggregate

**Para MVP:** usar o mesmo repository `find(byId:)` e mapear Patient -> PatientDetailDTO.

**Futuro:** Read model separado (CQRS completo) com projecoes otimizadas.

### Entregaveis Fase 6:
- [ ] `PatientDetailDTO` com todos os campos
- [ ] Mapper `Patient -> PatientDetailDTO`
- [ ] Handler `GET /patients/{patientId}` no controller
- [ ] Testes

---

## FASE 7 — Cross-Cutting Concerns

### 7.1 Health Check

Endpoints `/health` e `/ready` (verifica conexao DB).

### 7.2 Request Logging Middleware

Logar: method, path, status, duration, request-id.

### 7.3 CORS Middleware

Configuravel via ENV. Necessario para front-end.

### 7.4 Auth Middleware (Bearer JWT)

Middleware que valida JWT e extrai claims.

### 7.5 Graceful Shutdown

Usar lifecycle hooks do Vapor para fechamento seguro.

### Entregaveis Fase 7:
- [ ] Health check + readiness endpoints
- [ ] Request logging middleware
- [ ] CORS middleware
- [ ] Auth middleware (placeholder ou JWT real)
- [ ] Graceful shutdown no ApplicationContext

---

## FASE 8 — Testes Completos + 95% Cobertura

**Estratégia de Testes Híbrida:**
- **Domain Layer:** Testes UNITÁRIOS exaustivos. Foco em lógica de negócio, VOs e Agregados. Sem dependências de IO.
- **Application Layer:** Testes de INTEGRAÇÃO em ambiente real/controlado. Uso de banco de dados (SQLite In-Memory ou Postgres Staging) para validar o fluxo completo (Handler -> Repository -> SQL -> Mapper). **Mocks manuais de repositório estão proibidos na Application.**
- **IO Layer:** Testes de integração de API (VaporTesting) contra a camada de Application real.

### 8.1 Testes de Domínio (Unit)
...

| Teste | Cobre |
|-------|-------|
| `UpdateWorkAndIncomeTests` | UC v2.0 |
| `UpdateEducationalStatusTests` | UC v2.0 |
| `UpdateHealthStatusTests` | UC v2.0 |
| `RegisterIngressInfoTests` | UC v2.0 |
| `RemoveFamilyMemberTests` | UC existente sem teste |
| `AssignPrimaryCaregiverTests` | UC existente sem teste |
| `UpdateSocialIdentityTests` | UC existente sem teste |
| `OutboxRelayTests` | Relay polling + processing |
| `ErrorMiddlewareTests` | Middleware de erro |
| `ResponseDTOTests` | Serialization round-trip |

### 8.2 Testes de Integracao HTTP (VaporTesting)

Usar `XCTVapor` ou similar para testar o fluxo completo.

### 8.3 Testes de Persistencia (DatabaseMapper)

Ja existem `DatabaseMapperTests` e `DatabaseReconstitutionTests`. Expandir para cobrir campos v2.0.

### Entregaveis Fase 8:
- [ ] ~10 novas suites de teste unitario
- [ ] ~8 testes de integracao HTTP
- [ ] Testes de mapper v2.0
- [ ] `make coverage` passando com >= 95%

---

## FASE 9 — Production Readiness

### 9.1 Docker Compose para Dev

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: social_care
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports: ["5432:5432"]

  app:
    build: .
    ports: ["8080:8080"]
    depends_on: [db]
    environment:
      DB_HOST: db
```

### 9.2 .env.example Completo

Garantir que `.env.example` lista TODAS as variaveis.

### 9.3 CI Pipeline Atualizado

Garantir que o workflow verifica cobertura >= 95%.

### 9.4 README Atualizado

Atualizar `README.md` com instruções Vapor.

### Entregaveis Fase 9:
- [ ] `docker-compose.yml` na raiz de social-care/
- [ ] `.env.example` completo
- [ ] CI atualizado
- [ ] README.md atualizado
- [ ] CHANGELOG.md atualizado

---

## Checklist Final

Quando TODOS os itens abaixo estiverem marcados, o microservico esta pronto para deploy:

### Domain
- [x] Todos os VOs com validacao no init
- [x] Agregado Patient com Event Sourcing
- [x] 7 eventos de dominio
- [x] Modulos v2.0 (WorkAndIncome, Educational, Health, Acolhimento, Ingress)
- [x] Analytics services (Financial, Housing, Education)

### Application
- [x] 14 use cases de escrita implementados
- [ ] 2+ use cases de leitura implementados
- [ ] Testes unitarios para TODOS os use cases

### HTTP (I/O - Vapor)
- [ ] Rotas implementadas conforme `front_end_forms/`
- [ ] Padrão **CRU** rigoroso (Delete desativado)
- [ ] Lógica **Metadata-Driven** (Benefícios/Violência)
- [ ] Cálculos automáticos no GET (Renda, Densidade, Vulnerabilidade)
- [ ] Validações cruzadas (Acolhimento/Idade, Saúde/Sexo)
- [ ] Middleware de erro global
- [ ] Health check + readiness
- [ ] CORS middleware
- [ ] Auth middleware (pelo menos placeholder)
- [ ] Request logging


### Persistencia (I/O)
- [x] Repository usando transacao SQL
- [x] Migration runner com tabela de controle
- [x] Todos os campos v2.0 persistidos
- [x] Indices de performance (PersonId, Outbox)
- [x] Mapper atualizado com round-trip testado

### Outbox / Events
- [x] Relay funcionando com polling real
- [x] Mensagens marcadas como processadas
- [x] Todos os 7 eventos registrados
- [x] Relay iniciado no boot

### Testes
- [ ] Testes unitarios para todos os 14+ use cases
- [ ] Testes de integracao HTTP
- [ ] Testes de mapper v2.0
- [ ] Cobertura >= 95%

### Producao
- [ ] docker-compose.yml
- [ ] .env.example completo
- [ ] CI pipeline completo
- [ ] README atualizado
- [ ] Graceful shutdown

---

## Ordem de Execucao Recomendada

```
Dia 1-2:   FASE 1 (transacao, migration runner, v2.0 migration)
Dia 3:     FASE 2 (queries de leitura)
Dia 4-6:   FASE 3 (HTTP Vapor & Forms) — maior fase
Dia 7-8:   FASE 4 (persistencia robusta)
Dia 9:     FASE 5 (outbox relay real)
Dia 10:    FASE 6 (read side)
Dia 11-13: FASE 7 (cross-cutting)
Dia 14-16: FASE 8 (testes ate 95%)
Dia 17:    FASE 9 (production readiness)
```
### 9.2 .env.example Completo

Garantir que `.env.example` lista TODAS as variaveis.

### 9.3 CI Pipeline Atualizado

Garantir que o workflow:
1. Roda migrations em DB de teste
2. Executa testes unitarios + integracao
3. Verifica cobertura >= 95%
4. Build release
5. Build Docker image

### 9.4 README Atualizado

Atualizar `README.md` com:
- Como rodar local (`docker compose up`)
- Como rodar testes
- Endpoints disponiveis
- Variaveis de ambiente

### Entregaveis Fase 9:
- [ ] `docker-compose.yml` na raiz de social-care/
- [ ] `.env.example` completo
- [ ] CI atualizado
- [ ] README.md atualizado
- [ ] CHANGELOG.md atualizado

---

## Checklist Final

Quando TODOS os itens abaixo estiverem marcados, o microservico esta pronto para deploy:

### Domain
- [x] Todos os VOs com validacao no init
- [x] Agregado Patient com Event Sourcing
- [x] 7 eventos de dominio
- [x] Modulos v2.0 (WorkAndIncome, Educational, Health, Acolhimento, Ingress)
- [x] Analytics services (Financial, Housing, Education)

### Application
- [x] 14 use cases de escrita implementados
- [ ] 2+ use cases de leitura implementados
- [ ] Testes unitarios para TODOS os use cases

### HTTP (I/O)
- [x] Paths alinhados com OpenAPI (Flat Pattern)
- [x] DELETE /family-members implementado
- [x] Response bodies seguem contrato (StandardResponse)
- [x] Middleware de erro global
- [x] Health check + readiness
- [ ] CORS middleware
- [ ] Auth middleware (pelo menos placeholder)
- [ ] Request logging


### Persistencia (I/O)
- [x] Repository usando transacao SQL
- [x] Migration runner com tabela de controle
- [x] Todos os campos v2.0 persistidos
- [x] Indices de performance (PersonId, Outbox)
- [x] Mapper atualizado com round-trip testado

### Outbox / Events
- [x] Relay funcionando com polling real
- [x] Mensagens marcadas como processadas
- [x] Todos os 7 eventos registrados
- [x] Relay iniciado no boot

### Testes
- [ ] Testes unitarios para todos os 14+ use cases
- [ ] Testes de integracao HTTP
- [ ] Testes de mapper v2.0
- [ ] Cobertura >= 95%

### Producao
- [ ] docker-compose.yml
- [ ] .env.example completo
- [ ] CI pipeline completo
- [ ] README atualizado
- [ ] Graceful shutdown

---

## Ordem de Execucao Recomendada

```
Dia 1-2:   FASE 1 (transacao, migration runner, v2.0 migration)
Dia 3:     FASE 2 (queries de leitura)
Dia 4-6:   FASE 3 (HTTP OpenAPI-compliant) — maior fase
Dia 7-8:   FASE 4 (persistencia robusta)
Dia 9:     FASE 5 (outbox relay real)
Dia 10:    FASE 6 (read side)
Dia 11-13: FASE 7 (cross-cutting)
Dia 14-16: FASE 8 (testes ate 95%)
Dia 17:    FASE 9 (production readiness)
```

> **Nota:** As fases podem ser paralelizadas. Ex: Fase 4 (persistencia) pode rodar junto com Fase 3 (HTTP) se duas pessoas trabalharem.
