# Changelog

Todas as mudancas relevantes deste servico serao registradas aqui.

## [Unreleased]

## [0.5.0] - 2026-03-07

### Adicionado
- Camada HTTP completa com Vapor 4: 6 controllers, 23 rotas
- `HealthController` com endpoints `/health` (liveness) e `/ready` (readiness com check de DB)
- `PatientController` com 8 rotas (CRUD de paciente, familia, caregiver, social identity, audit trail)
- `AssessmentController` com 7 rotas PUT para modulos de avaliacao
- `ProtectionController` com 3 rotas (placement history, violation reports, referrals)
- `CareController` com 2 rotas (appointments, intake info)
- `LookupController` com GET generico para 13 tabelas de dominio
- `StandardResponse<T>` wrapper com `meta.timestamp` em todos os endpoints de sucesso
- `AppErrorMiddleware` para padronizacao global de respostas de erro
- `MetadataValidator` para validacao dinamica contra flags em lookup tables (`dominio_tipo_beneficio`, `dominio_tipo_violacao`)
- `CrossValidator` para validacoes cruzadas (saude/sexo-gestante, acolhimento/idade)
- `GracefulShutdownHandler` compativel com SIGTERM do Kubernetes
- Calculos automaticos no GET: densidade habitacional, 4 indicadores financeiros, perfil etario (8 faixas), vulnerabilidades educacionais (6 indicadores)
- Audit trail com before/after diff nos eventos de assessment e filtro por `?eventType=`
- Obrigatoriedade de `X-Actor-Id` header em todas as mutations
- Migration `NormalizeSchema`: JSONB blobs normalizados para colunas diretas + 8 tabelas filhas + 5 novas lookup tables com metadata
- Migration `CreateAuditTrail`: tabela audit_trail com actor_id
- Migration `AddPerformanceIndexes`: indices de performance
- `docker-compose.yml` para desenvolvimento local (PostgreSQL + app)
- `.env.example` completo com todas as variaveis de ambiente
- 17 request DTOs com `toCommand(actorId:)`
- Response DTOs com `computedAnalytics` (housing, financial, ageProfile, educationalVulnerabilities)
- Suite de testes completa: **135 testes em 38 suites** cobrindo Domain, Application e IO
- Testes de Application: 17 suites para todos os command handlers (RegisterPatient, AddFamilyMember, RemoveFamilyMember, AssignPrimaryCaregiver, UpdateSocialIdentity, UpdateHousingCondition, UpdateSocioEconomicSituation, UpdateWorkAndIncome, UpdateEducationalStatus, UpdateHealthStatus, UpdateCommunitySupportNetwork, UpdateSocialHealthSummary, UpdatePlacementHistory, ReportRightsViolation, CreateReferral, RegisterAppointment, RegisterIntakeInfo)
- Testes de IO: `AuditTrailTests` (DomainEventRegistry, outbox mapper, AuditTrailEntryResponse, round-trip encode/decode)
- Test doubles: `InMemoryPatientRepository`, `InMemoryEventBus`, `InMemoryLookupValidator`, `AllowAllLookupValidator`, `PatientFixture`
- Testes de Domain: `LookupIdTests`, `LookupValidatingTests`, `TimeStampAgeTests`, `DomainAnalyticsSpecificationTests`, `AnalyticsConsistencyTests`

### Alterado
- Schema normalizado: 13 JSONB blobs convertidos para ~50 colunas escalares + 8 tabelas filhas relacionais
- `PatientDatabaseMapper` reescrito para schema normalizado (colunas diretas + tabelas filhas)
- `PatientDatabaseModels` reescrito com modelos para 8 tabelas filhas
- `SQLKitPatientRepository.save()` atualizado para persistir tabelas filhas (delete-and-insert)
- `SQLKitOutboxRelay` otimizado com processamento em lote, audit trail automatico e `processed_at`
- `README.md` atualizado para refletir estado completo do servico (135 testes, 38 suites)
- `DomainEventRegistryBootstrap` expandido para 17 eventos

## [0.4.0] - 2026-02-24
- Implementacao da camada de **Infrastructure** com **SQLKit** e **PostgresKit**.
- Implementacao do **Pattern Transactional Outbox** para garantia de entrega de eventos.
- Criacao do **SQLKitOutboxRelay** (Actor) para polling assincrono e distribuicao via **AsyncStream**.
- Implementacao de **DomainEventRegistry** para decodificacao segura de eventos heterogeneos.
- Sistema de **Migrations** programatico e idempotente para PostgreSQL.
- Refatoracao de eventos de dominio para suporte a `Codable`.

## [0.3.0] - 2026-02-24
- Migracao completa da camada de **Application** de TypeScript para Swift 6.
- Implementacao de 8 Casos de Uso com *Structured Concurrency* e *Typed Throws*.
- Refatoracao de Mappers de erro para um padrao centralizado (`mapError`).
- Suite de testes de aplicacao concluida com 100% de cobertura logica nos servicos.
- Alcance do nivel **Platinum (95.95%)** de confiabilidade global do projeto.
- Testes de cobertura adicionados para todos os Enums de erro e Value Objects (PatientId).

## [0.2.0] - 2026-02-24
- Migracao de CI de Bun para Swift/Linux com SwiftPM.
- Remocao de setup/login/sync de contracts no pipeline de CI.
- Atualizacao do workflow de release GHCR para imagem do servico Swift.
- Migracao do Dockerfile para build e runtime baseados em Swift.
- Atualizacao de `.dockerignore` e `.gitignore` para artefatos Swift.
- Dominio da aplicacao concluido (Aggregates, Entities, Value Objects e testes).

## [0.1.0] - 2026-02-22
- Baseline inicial de repositorio ACDG.
