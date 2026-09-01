# Changelog

Todas as mudancas relevantes deste servico serao registradas aqui.

## [Unreleased]

> **Reconstrucao historica (2026-08-31).** As versoes 0.5.4 ate 0.16.0 estavam
> ausentes deste arquivo — o CHANGELOG parou em 0.7.0 enquanto as tags seguiram
> ate v0.16.0. As entradas abaixo foram reconstruidas a partir das tags e do
> historico de commits, **conferidas contra o codigo** (nao apenas contra as
> mensagens de commit). Onde a mensagem divergia do resultado final, vale o
> codigo — os casos estao anotados na propria entrada.
>
> Duas inconsistencias encontradas na reconstrucao:
> - **0.1.0 a 0.4.0 nao existem como git tag.** Estao documentadas no final
>   deste arquivo, mas a primeira tag do repositorio e `v0.5.0`.
> - **`v0.14.3` nao e ancestral de `v0.15.0`.** A adocao da AGPL saiu numa linha
>   paralela e so entrou na linha principal em `v0.16.0`.

## [0.16.0] - 2026-07-28

### Adicionado
- **Refresh de JWKS em runtime (ADR-040)** — atualizacao periodica das chaves
  publicas mais busca sob demanda por `kid` desconhecido. Antes o JWKS era
  buscado so no boot: rotacao de chave no IdP derrubava a validacao de token ate
  o proximo restart. Implementado em `IO/HTTP/Auth/JWKSRefresher.swift`.

### Complementar
- Handbook reconciliado com a v0.15.0; ADRs de OIDC materializados.
- Manuais SUAS adicionados ao handbook (prontuario + orientacao de fluxo).
- Planos e casos de teste de QA; `.mcp.json` com servidores aninhados sob
  `mcpServers`.
- Bumps: `actions/checkout` 6.0.2 → 7.0.0, `sql-kit` 3.35.0 → 3.36.0,
  `vapor` 4.121.3 → 4.121.4.
- Traz para a linha principal a adocao da AGPL-3.0 tagueada em `v0.14.3`.

## [0.15.0] - 2026-06-25

### Adicionado
- **Erasure LGPD (ADR-039)** — caso de uso `AnonymizePatientPII`, que anonimiza
  PII ao consumir o evento `people.person.deleted`. Nota historica: a feature foi
  introduzida, revertida e reaplicada dentro deste mesmo ciclo; o estado final em
  `main` contem a implementacao (`Application/Registry/AnonymizePatientPII/`).
- Evolucao do bounded context **Assessment** e endurecimento de seguranca (S-C5).

### Complementar
- Handbook versionado: `DECISIONS/` com ADRs, backlog, features, tooling e reports.
- Tooling: verticais Swift, pipeline SDD e pin de toolchain via `.swift-version`.
- CI: corrigido `startup_failure` do PR Size Guard (permissions no caller).

## [0.14.3] - 2026-05-27

### Complementar
- **Licenca AGPL-3.0 adotada** para o servico core (ADR-BV-001) — o repositorio
  estava sem licenca. Ver `LICENSE`.
- Esta tag **nao e ancestral de `v0.15.0`**: saiu numa linha paralela e so
  alcancou a linha principal em `v0.16.0`.

## [0.14.2] - 2026-04-16

### Corrigido
- **Validacao de RG relaxada para estados fora de SP.** O documento de RG nao tem
  padrao nacional — a regra anterior rejeitava documentos legitimos de outras UFs.
- Mascaramento de PII em mensagens de erro, correcao de valor em erro e ajuste de
  texto, vindos de code review.

### Complementar
- CI: Kodus review e PR Size Guard passam a ser pulados em PRs do Dependabot.

## [0.14.1] - 2026-04-14

### Corrigido
- **RBAC com papeis compostos e bypass de superadmin.** O guard anterior nao
  reconhecia papeis no formato composto, negando acesso a usuarios legitimos.

## [0.14.0] - 2026-04-13

### Alterado
- **Paciente passa a nascer com status ativo no registro.** Antes exigia uma
  transicao explicita apos o cadastro.

## [0.13.3] - 2026-04-13

### Corrigido
- **`PatientError` de ciclo de vida mapeado para `patientNotActive`** em todos os
  casos de uso afetados (16 use cases), unificando a semantica de erro.

### Complementar
- Chaves de motivo legiveis por maquina, melhorias de observabilidade e
  padronizacao de estilo de teste (review do PR #12).

## [0.13.2] - 2026-04-13

### Corrigido
- Protecao de PII, semantica de erros e lacunas de contexto (review do PR #11).

## [0.13.1] - 2026-04-13

### Corrigido
- Achados de review dos PRs #8, #9 e #10.

## [0.13.0] - 2026-04-13

### Adicionado
- **Ciclo de vida do paciente**: alta (`DischargePatient`) e readmissao
  (`ReadmitPatient`).
- **Lista de espera**: admissao (`AdmitPatient`) e desistencia
  (`WithdrawFromWaitlist`), com a migration `2026_04_12_AddWaitlistSupport`.

### Corrigido
- Erros inesperados deixam de ser mascarados; codigo morto removido; migration
  documentada.

### Complementar
- CI: workflow PR Size Guard adicionado; workflow de auto-version removido.

## [0.12.1] - 2026-04-11

### Corrigido
- **Remediacao de achados criticos e altos de auditoria de seguranca** (PR #7):
  - Container deixa de rodar como root — `appuser`/`appgroup` sem shell de login,
    binario com `--chown`, mais `HEALTHCHECK` no Dockerfile.
  - `VERBOSE_ERRORS` passa a ser ignorado quando `ENVIRONMENT=production`,
    impedindo vazamento de detalhe interno em producao.
  - Payload de erro passa a expor `safeContext` em vez do contexto bruto.
  - Fail-fast no boot quando faltam `DB_HOST`/`DB_USER`/`DB_PASSWORD`/`DB_NAME`.
  - Validacao explicita de `iss` e `aud` no payload JWT.

### Complementar
- Geracao de SBOM no pipeline de CI; configuracao do Dependabot; gate do Kodus CLI;
  GitHub Actions pinadas por SHA; regras de review do Kodus.
- Bumps: imagem `swift` 6.2-jammy-slim → 6.3-jammy-slim, `sql-kit` 3.34.0 → 3.35.0,
  `actions/checkout` 4.3.1 → 6.0.2, `setup-swift`.

## [0.12.0] - 2026-04-06

### Adicionado
- **Validacao de `PersonId` contra o people-context** antes do registro de
  paciente, evitando prontuario orfao apontando para pessoa inexistente.

## [0.11.0] - 2026-04-06

### Adicionado
- **Consumo do evento `people.person.registered`** para vincular `PatientId` ao
  `PersonId` correspondente.

### Complementar
- Especificacao de dominio adicionada a documentacao.

## [0.10.0] - 2026-04-01

### Adicionado
- Opcao de genero **"outro"**.

### Alterado
- Validacao de gestacao ajustada para acompanhar a nova opcao de genero.

## [0.9.0] - 2026-03-31

### Adicionado
- **CNS (Cartao Nacional de Saude)** no cadastro.
- Flag **`isHomeless`** (situacao de rua).
- Suporte a **diagnostico em investigacao** via CID `Z03.9`.

## [0.8.0] - 2026-03-31

### Adicionado
- **CRUD de lookup tables e sistema de governanca de solicitacoes** — fluxo de
  solicitacao/aprovacao/rejeicao de itens de lookup (bounded context
  `Configuration`).

## [0.7.0] - 2026-03-30

### Adicionado
- **Endpoint de listagem de pacientes** `GET /api/v1/patients` com paginacao cursor-based e busca server-side. Query params: `search` (filtra por firstName, lastName ou CPF, case-insensitive), `cursor` (UUID para paginacao), `limit` (1-100, default 20). Retorna `PaginatedResponse<[PatientSummaryResponse]>` com meta de paginacao (`pageSize`, `totalCount`, `hasMore`, `nextCursor`).
- `ListPatientsQueryHandler` na camada Application (CQRS query) com validacao de cursor e limite. Codigos de erro: `QLP-001` (cursor invalido), `QLP-002` (limite fora do range).
- `PatientSummary` como projecao leve no Domain: `patientId`, `personId`, `firstName`, `lastName`, `primaryDiagnosis`, `memberCount`. Evita carregar o agregado completo (10+ tabelas filhas).
- `PatientListResult` com metadados de paginacao no protocolo `PatientRepository`.
- `PaginatedResponse<T>` generico com `PaginatedMeta` separado do `StandardResponse` existente.
- Implementacao SQL otimizada no `SQLKitPatientRepository.list()`: 3 queries batch (count + list + diagnoses/members) em vez de N+1 com `loadAggregate()`.
- 14 novos testes no `ListPatientsTests`: lista vazia, resultados, fullName, diagnostico, busca por nome/sobrenome, case-insensitive, paginacao com cursor, validacao de erros, pacientes sem personalData.
- Total de testes: **149 em 39 suites** (todos passando).

### Complementar
- Header `X-Build-Version` em todas as respostas HTTP (sucesso e erro) via `AppErrorMiddleware`, lendo `BUILD_SHA` do environment (default: `dev`). Permite verificar qual versao do backend esta rodando sem acesso ao cluster Kubernetes.

## [0.6.0] - 2026-03-17

### Adicionado
- **Publicacao de eventos NATS via Outbox Relay.** O `SQLKitOutboxRelay` passa a
  entregar as mensagens do outbox para o NATS.
- ⚠️ **Atencao ao ler o historico de commits desta versao.** A implementacao
  comecou com a biblioteca `nats.swift` e exigiu tres commits so para compilar
  `libsodium` (AEGIS/IpCrypt). O commit final (`508f609`) **descartou essa
  abordagem** e substituiu tudo por um publisher TCP minimo escrito direto em
  SwiftNIO. O resultado em `main` e `public actor NATSEventPublisher`
  (`IO/EventBus/NATSEventPublisher.swift`), e **nao ha dependencia de `nats.swift`
  nem de `libsodium`** no `Package.swift` — o que se confirma inspecionando o
  manifesto. Os commits de libsodium sao caminho abandonado, nao entrega.

## [0.5.5] - 2026-03-16

### Corrigido
- **Retry com backoff para migrations e busca de JWKS no startup.** Sem isso, um
  banco ou IdP ainda subindo derrubava o servico no boot.

## [0.5.4] - 2026-03-13

### Corrigido
- **`find(byId:)` no lugar de `find(byPersonId:)` em 12 command handlers.** Os
  handlers de mutacao buscavam o agregado pela chave errada, usando `PersonId`
  onde o correto e o `PatientId` do agregado.

### Complementar
- Header `X-Build-Version` nas respostas HTTP para verificacao de deploy.
  (Removido depois na 0.12.1, junto com a remediacao de seguranca.)

## [0.5.3] - 2026-03-13

### Corrigido
- **Queries SELECT sem colunas geravam `DecodingError` (HTTP 400).** O SQLKit 3.34.0 nao emite `*` quando nenhuma coluna e especificada no builder (`SQLSelect.serialize` ignora a clausula de colunas quando o array esta vazio). Todas as queries de leitura do `SQLKitPatientRepository` (`find(byId:)`, `find(byPersonId:)`, e as 13 queries do `loadAggregate()`) e do `SQLKitOutboxRelay` (`pollAndDistribute()`) geravam `SELECT FROM table` em vez de `SELECT * FROM table`. O PostgreSQL retorna rows com zero colunas, o `SQLRowDecoder` falha no primeiro campo obrigatorio (`id: UUID`) com `DecodingError.keyNotFound("id")`, e o Vapor 4 converte `DecodingError` para `AbortError(.badRequest)` — resultando no erro `400: "No such key 'id' at path ''"` reportado pelo frontend. Corrigido adicionando `.column("*")` explicito em todas as 16 queries afetadas. O `SQLColumn("*")` e tratado corretamente pelo SQLKit: o init converte `"*"` para `SQLLiteral.all` (wildcard nao-quoted).

## [0.5.2] - 2026-03-13

### Corrigido
- Migration `ConvertJsonbToText` expandida para incluir `outbox_messages.payload` e `audit_trail.payload`, que tambem sofriam do mismatch JSONB/TEXT e causavam falha silenciosa no outbox relay e no registro de audit trail.

## [0.5.1] - 2026-03-13

### Corrigido
- **Colunas JSONB causavam erro de tipo no PostgresKit.** O SQLKit `.model()` serializa campos `String` do Swift como TEXT, mas as colunas `required_documents` (family_members), `shs_functional_dependencies` e `hs_constant_care_member_ids` (patients) estavam definidas como JSONB no PostgreSQL. O PostgresKit rejeitava o bind com type mismatch. Corrigido com migration `ConvertJsonbToText` que converte essas colunas de JSONB para TEXT via `ALTER COLUMN ... TYPE TEXT USING ...::text`.

### Complementar (sem tag)
- `AppErrorMiddleware` passou a incluir `details` no body de erro quando `VERBOSE_ERRORS=true`, para facilitar debug no HML.
- Colunas JSONB dos modelos `PatientDatabaseModels` alteradas de `Data` para `String` para alinhar com o tipo TEXT do PostgreSQL.

### Complementar entre v0.5.0 e v0.5.1 (sem tag)

#### 2026-03-07 — Infraestrutura de deploy
- `fix: usar primaryKey(autoIncrement: false) em colunas UUID` — PostgreSQL requer flag explicita para PKs nao-autoincrementadas com SQLKit.
- `fix: bind server on 0.0.0.0 and lower coverage gate to 30%` — servidor bindava em localhost, inacessivel dentro do container Docker/K8s.
- `fix: read PORT env var for K8s container port alignment` — porta fixa impedia configuracao via Kubernetes.

#### 2026-03-07 — Autenticacao e RBAC
- `feat: add JWT authentication and RBAC middleware with Zitadel integration` (PR #1) — `JWTAuthMiddleware` valida tokens JWT via JWKS do Zitadel. `RoleGuardMiddleware` implementa RBAC por rota. `ZitadelJWTPayload` extrai roles do claim `urn:zitadel:iam:org:project:roles`. `AuthenticatedUser` armazenado no request storage.

#### 2026-03-11 — Service Accounts e persistencia
- `feat: add Zitadel Token Introspection fallback for service accounts` — fallback de introspeccao OAuth2 para service accounts que nao carregam roles no JWT. Configuravel via `ZITADEL_INTROSPECT_CLIENT_ID/SECRET` e `ALLOWED_SERVICE_ACCOUNTS`.
- `feat: add service account allowlist + remove CI coverage gate` — allowlist de service accounts confiavies e remocao temporaria do gate de cobertura no CI para desbloquear deploys.
- `fix(persistence): replace Data with String for JSONB columns to fix REGP-024` — campos JSONB nos modelos de banco usavam `Data` (bytes) em vez de `String`, causando falha na serializacao do PostgresKit.

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
