# Changelog

Todas as mudanças relevantes deste serviço serão registradas aqui.

## [Unreleased]

> **Reconstrução histórica (2026-08-31).** As versões 0.5.4 até 0.16.0 estavam
> ausentes deste arquivo — o CHANGELOG parou em 0.7.0 enquanto as tags seguiram
> até v0.16.0. As entradas abaixo foram reconstruídas a partir das tags e do
> histórico de commits, **conferidas contra o código** (não apenas contra as
> mensagens de commit). Onde a mensagem divergia do resultado final, vale o
> código — os casos estão anotados na própria entrada.
>
> Duas inconsistências encontradas na reconstrução:
> - **0.1.0 a 0.4.0 não existem como git tag.** Estão documentadas no final
>   deste arquivo, mas a primeira tag do repositório é `v0.5.0`.
> - **`v0.14.3` não é ancestral de `v0.15.0`.** A adoção da AGPL saiu numa linha
>   paralela e só entrou na linha principal em `v0.16.0`.

## [0.17.0] - 2026-09-01

### Adicionado
- **Correlação e log de acesso (G12, ADR-044)** — `RequestContextMiddleware`
  adota o `X-Request-Id` do chamador (ou o `trace-id` de um `traceparent` do
  W3C), devolve o header em toda resposta e emite uma linha de log por
  requisição com rota, status e duração. **Sem query string, corpo ou header**:
  `?search=` carrega nome e CPF. Id vindo de fora passa por allowlist — sem ela,
  um `\n` no header injeta linha no log agregado.
- **CORS opt-in por allowlist (G13, ADR-045)** — `CORSPolicy` monta a
  configuração a partir de `CORS_ALLOWED_ORIGINS`; sem a variável, o middleware
  não entra na cadeia. Sempre `.any([...])`, nunca o `.originBased` do default
  do Vapor, que ecoa qualquer origem. `*` é recusado em produção.
- **Rate limiting (G14, ADR-046)** — token bucket por IP em memória do processo,
  ligado por default (300 req/60s), antes da autenticação. Responde 429 com
  `Retry-After` e anexa `X-RateLimit-*` a toda resposta. `TRUST_PROXY` controla
  o uso de `X-Forwarded-For`; o log guarda a faixa do IP (`/24`, `/48`), não o
  endereço.
- **ADR-034 (clock injetável)** — o código citava esse ADR em três lugares e o
  arquivo não existia. Escrito, com o `ClockInjectionTest` que o
  `Regression/DomainInvariants/README.md` prometia desde maio.
- 45 testes novos (550 no total, 94 suites). Cobertura de `IO` de 9,1% para
  18,4%.

### Alterado
- `AppErrorMiddleware` expõe `errorResponse(...)` como envelope de erro
  compartilhado — o 429 do rate limit responde no mesmo formato — e propaga os
  headers de um `Abort`, que antes eram descartados.
- Ordem dos middlewares:
  `SecurityHeaders → RequestContext → CORS → RateLimit → AppError → JWTAuth`.
  Lint estrutural em `Regression/Security/` falha se ela mudar.
- `TestClock` sai do arquivo de teste do JWKS e vira double reaproveitável em
  `Tests/social-care-sTests/Application/TestDoubles/`.

### Removido
- `RegressionFixture.StubUnitOfWork` e seus dois testes. Era placeholder de um
  "ticket T-030 / ADR-030" que nunca virou decisão, e a única coisa que os testes
  exercitavam era o próprio stub. A atomicidade que ele prometia já é atendida
  pelo repositório (ADR-014); a proposta ficou registrada em `docs/adr/BACKLOG.md`
  (#14).

## [0.16.0] - 2026-07-28

### Adicionado
- **Refresh de JWKS em runtime (ADR-040)** — atualização periódica das chaves
  públicas mais busca sob demanda por `kid` desconhecido. Antes o JWKS era
  buscado só no boot: rotação de chave no IdP derrubava a validação de token até
  o próximo restart. Implementado em `IO/HTTP/Auth/JWKSRefresher.swift`.

### Complementar
- Handbook reconciliado com a v0.15.0; ADRs de OIDC materializados.
- Manuais SUAS adicionados ao handbook (prontuário + orientação de fluxo).
- Planos e casos de teste de QA; `.mcp.json` com servidores aninhados sob
  `mcpServers`.
- Bumps: `actions/checkout` 6.0.2 → 7.0.0, `sql-kit` 3.35.0 → 3.36.0,
  `vapor` 4.121.3 → 4.121.4.
- Traz para a linha principal a adoção da AGPL-3.0 tagueada em `v0.14.3`.

## [0.15.0] - 2026-06-25

### Adicionado
- **Erasure LGPD (ADR-039)** — caso de uso `AnonymizePatientPII`, que anonimiza
  PII ao consumir o evento `people.person.deleted`. Nota histórica: a feature foi
  introduzida, revertida e reaplicada dentro deste mesmo ciclo; o estado final em
  `main` contém a implementação (`Application/Registry/AnonymizePatientPII/`).
- Evolução do bounded context **Assessment** e endurecimento de segurança (S-C5).

### Complementar
- Handbook versionado: `DECISIONS/` com ADRs, backlog, features, tooling e reports.
- Tooling: verticais Swift, pipeline SDD e pin de toolchain via `.swift-version`.
- CI: corrigido `startup_failure` do PR Size Guard (permissions no caller).

## [0.14.3] - 2026-05-27

### Complementar
- **Licença AGPL-3.0 adotada** para o serviço core (ADR-BV-001) — o repositório
  estava sem licença. Ver `LICENSE`.
- Esta tag **não é ancestral de `v0.15.0`**: saiu numa linha paralela e só
  alcançou a linha principal em `v0.16.0`.

## [0.14.2] - 2026-04-16

### Corrigido
- **Validação de RG relaxada para estados fora de SP.** O documento de RG não tem
  padrão nacional — a regra anterior rejeitava documentos legítimos de outras UFs.
- Mascaramento de PII em mensagens de erro, correção de valor em erro e ajuste de
  texto, vindos de code review.

### Complementar
- CI: Kodus review e PR Size Guard passam a ser pulados em PRs do Dependabot.

## [0.14.1] - 2026-04-14

### Corrigido
- **RBAC com papéis compostos e bypass de superadmin.** O guard anterior não
  reconhecia papéis no formato composto, negando acesso a usuários legítimos.

## [0.14.0] - 2026-04-13

### Alterado
- **Paciente passa a nascer com status ativo no registro.** Antes exigia uma
  transição explícita após o cadastro.

## [0.13.3] - 2026-04-13

### Corrigido
- **`PatientError` de ciclo de vida mapeado para `patientNotActive`** em todos os
  casos de uso afetados (16 use cases), unificando a semântica de erro.

### Complementar
- Chaves de motivo legíveis por máquina, melhorias de observabilidade e
  padronização de estilo de teste (review do PR #12).

## [0.13.2] - 2026-04-13

### Corrigido
- Proteção de PII, semântica de erros e lacunas de contexto (review do PR #11).

## [0.13.1] - 2026-04-13

### Corrigido
- Achados de review dos PRs #8, #9 e #10.

## [0.13.0] - 2026-04-13

### Adicionado
- **Ciclo de vida do paciente**: alta (`DischargePatient`) e readmissão
  (`ReadmitPatient`).
- **Lista de espera**: admissão (`AdmitPatient`) e desistência
  (`WithdrawFromWaitlist`), com a migration `2026_04_12_AddWaitlistSupport`.

### Corrigido
- Erros inesperados deixam de ser mascarados; código morto removido; migration
  documentada.

### Complementar
- CI: workflow PR Size Guard adicionado; workflow de auto-version removido.

## [0.12.1] - 2026-04-11

### Corrigido
- **Remediação de achados críticos e altos de auditoria de segurança** (PR #7):
  - Container deixa de rodar como root — `appuser`/`appgroup` sem shell de login,
    binário com `--chown`, mais `HEALTHCHECK` no Dockerfile.
  - `VERBOSE_ERRORS` passa a ser ignorado quando `ENVIRONMENT=production`,
    impedindo vazamento de detalhe interno em produção.
  - Payload de erro passa a expor `safeContext` em vez do contexto bruto.
  - Fail-fast no boot quando faltam `DB_HOST`/`DB_USER`/`DB_PASSWORD`/`DB_NAME`.
  - Validação explícita de `iss` e `aud` no payload JWT.

### Complementar
- Geração de SBOM no pipeline de CI; configuração do Dependabot; gate do Kodus CLI;
  GitHub Actions pinadas por SHA; regras de review do Kodus.
- Bumps: imagem `swift` 6.2-jammy-slim → 6.3-jammy-slim, `sql-kit` 3.34.0 → 3.35.0,
  `actions/checkout` 4.3.1 → 6.0.2, `setup-swift`.

## [0.12.0] - 2026-04-06

### Adicionado
- **Validação de `PersonId` contra o people-context** antes do registro de
  paciente, evitando prontuário órfão apontando para pessoa inexistente.

## [0.11.0] - 2026-04-06

### Adicionado
- **Consumo do evento `people.person.registered`** para vincular `PatientId` ao
  `PersonId` correspondente.

### Complementar
- Especificação de domínio adicionada à documentação.

## [0.10.0] - 2026-04-01

### Adicionado
- Opção de gênero **"outro"**.

### Alterado
- Validação de gestação ajustada para acompanhar a nova opção de gênero.

## [0.9.0] - 2026-03-31

### Adicionado
- **CNS (Cartão Nacional de Saúde)** no cadastro.
- Flag **`isHomeless`** (situação de rua).
- Suporte a **diagnóstico em investigação** via CID `Z03.9`.

## [0.8.0] - 2026-03-31

### Adicionado
- **CRUD de lookup tables e sistema de governança de solicitações** — fluxo de
  solicitação/aprovação/rejeição de itens de lookup (bounded context
  `Configuration`).

## [0.7.0] - 2026-03-30

### Adicionado
- **Endpoint de listagem de pacientes** `GET /api/v1/patients` com paginação cursor-based e busca server-side. Query params: `search` (filtra por firstName, lastName ou CPF, case-insensitive), `cursor` (UUID para paginação), `limit` (1-100, default 20). Retorna `PaginatedResponse<[PatientSummaryResponse]>` com meta de paginação (`pageSize`, `totalCount`, `hasMore`, `nextCursor`).
- `ListPatientsQueryHandler` na camada Application (CQRS query) com validação de cursor e limite. Códigos de erro: `QLP-001` (cursor inválido), `QLP-002` (limite fora do range).
- `PatientSummary` como projeção leve no Domain: `patientId`, `personId`, `firstName`, `lastName`, `primaryDiagnosis`, `memberCount`. Evita carregar o agregado completo (10+ tabelas filhas).
- `PatientListResult` com metadados de paginação no protocolo `PatientRepository`.
- `PaginatedResponse<T>` genérico com `PaginatedMeta` separado do `StandardResponse` existente.
- Implementação SQL otimizada no `SQLKitPatientRepository.list()`: 3 queries batch (count + list + diagnoses/members) em vez de N+1 com `loadAggregate()`.
- 14 novos testes no `ListPatientsTests`: lista vazia, resultados, fullName, diagnóstico, busca por nome/sobrenome, case-insensitive, paginação com cursor, validação de erros, pacientes sem personalData.
- Total de testes: **149 em 39 suites** (todos passando).

### Complementar
- Header `X-Build-Version` em todas as respostas HTTP (sucesso e erro) via `AppErrorMiddleware`, lendo `BUILD_SHA` do environment (default: `dev`). Permite verificar qual versão do backend está rodando sem acesso ao cluster Kubernetes.

## [0.6.0] - 2026-03-17

### Adicionado
- **Publicação de eventos NATS via Outbox Relay.** O `SQLKitOutboxRelay` passa a
  entregar as mensagens do outbox para o NATS.
- ⚠️ **Atenção ao ler o histórico de commits desta versão.** A implementação
  começou com a biblioteca `nats.swift` e exigiu três commits só para compilar
  `libsodium` (AEGIS/IpCrypt). O commit final (`508f609`) **descartou essa
  abordagem** e substituiu tudo por um publisher TCP mínimo escrito direto em
  SwiftNIO. O resultado em `main` é `public actor NATSEventPublisher`
  (`IO/EventBus/NATSEventPublisher.swift`), e **não há dependência de `nats.swift`
  nem de `libsodium`** no `Package.swift` — o que se confirma inspecionando o
  manifesto. Os commits de libsodium são caminho abandonado, não entrega.

## [0.5.5] - 2026-03-16

### Corrigido
- **Retry com backoff para migrations e busca de JWKS no startup.** Sem isso, um
  banco ou IdP ainda subindo derrubava o serviço no boot.

## [0.5.4] - 2026-03-13

### Corrigido
- **`find(byId:)` no lugar de `find(byPersonId:)` em 12 command handlers.** Os
  handlers de mutação buscavam o agregado pela chave errada, usando `PersonId`
  onde o correto é o `PatientId` do agregado.

### Complementar
- Header `X-Build-Version` nas respostas HTTP para verificação de deploy.
  (Removido depois na 0.12.1, junto com a remediação de segurança.)

## [0.5.3] - 2026-03-13

### Corrigido
- **Queries SELECT sem colunas geravam `DecodingError` (HTTP 400).** O SQLKit 3.34.0 não emite `*` quando nenhuma coluna é especificada no builder (`SQLSelect.serialize` ignora a cláusula de colunas quando o array está vazio). Todas as queries de leitura do `SQLKitPatientRepository` (`find(byId:)`, `find(byPersonId:)`, e as 13 queries do `loadAggregate()`) e do `SQLKitOutboxRelay` (`pollAndDistribute()`) geravam `SELECT FROM table` em vez de `SELECT * FROM table`. O PostgreSQL retorna rows com zero colunas, o `SQLRowDecoder` falha no primeiro campo obrigatório (`id: UUID`) com `DecodingError.keyNotFound("id")`, e o Vapor 4 converte `DecodingError` para `AbortError(.badRequest)` — resultando no erro `400: "No such key 'id' at path ''"` reportado pelo frontend. Corrigido adicionando `.column("*")` explícito em todas as 16 queries afetadas. O `SQLColumn("*")` é tratado corretamente pelo SQLKit: o init converte `"*"` para `SQLLiteral.all` (wildcard não-quoted).

## [0.5.2] - 2026-03-13

### Corrigido
- Migration `ConvertJsonbToText` expandida para incluir `outbox_messages.payload` e `audit_trail.payload`, que também sofriam do mismatch JSONB/TEXT e causavam falha silenciosa no outbox relay e no registro de audit trail.

## [0.5.1] - 2026-03-13

### Corrigido
- **Colunas JSONB causavam erro de tipo no PostgresKit.** O SQLKit `.model()` serializa campos `String` do Swift como TEXT, mas as colunas `required_documents` (family_members), `shs_functional_dependencies` e `hs_constant_care_member_ids` (patients) estavam definidas como JSONB no PostgreSQL. O PostgresKit rejeitava o bind com type mismatch. Corrigido com migration `ConvertJsonbToText` que converte essas colunas de JSONB para TEXT via `ALTER COLUMN ... TYPE TEXT USING ...::text`.

### Complementar (sem tag)
- `AppErrorMiddleware` passou a incluir `details` no body de erro quando `VERBOSE_ERRORS=true`, para facilitar debug no HML.
- Colunas JSONB dos modelos `PatientDatabaseModels` alteradas de `Data` para `String` para alinhar com o tipo TEXT do PostgreSQL.

### Complementar entre v0.5.0 e v0.5.1 (sem tag)

#### 2026-03-07 — Infraestrutura de deploy
- `fix: usar primaryKey(autoIncrement: false) em colunas UUID` — PostgreSQL requer flag explícita para PKs não-autoincrementadas com SQLKit.
- `fix: bind server on 0.0.0.0 and lower coverage gate to 30%` — servidor bindava em localhost, inacessível dentro do container Docker/K8s.
- `fix: read PORT env var for K8s container port alignment` — porta fixa impedia configuração via Kubernetes.

#### 2026-03-07 — Autenticação e RBAC
- `feat: add JWT authentication and RBAC middleware with Zitadel integration` (PR #1) — `JWTAuthMiddleware` valida tokens JWT via JWKS do Zitadel. `RoleGuardMiddleware` implementa RBAC por rota. `ZitadelJWTPayload` extrai roles do claim `urn:zitadel:iam:org:project:roles`. `AuthenticatedUser` armazenado no request storage.

#### 2026-03-11 — Service Accounts e persistência
- `feat: add Zitadel Token Introspection fallback for service accounts` — fallback de introspecção OAuth2 para service accounts que não carregam roles no JWT. Configurável via `ZITADEL_INTROSPECT_CLIENT_ID/SECRET` e `ALLOWED_SERVICE_ACCOUNTS`.
- `feat: add service account allowlist + remove CI coverage gate` — allowlist de service accounts confiáveis e remoção temporária do gate de cobertura no CI para desbloquear deploys.
- `fix(persistence): replace Data with String for JSONB columns to fix REGP-024` — campos JSONB nos modelos de banco usavam `Data` (bytes) em vez de `String`, causando falha na serialização do PostgresKit.

## [0.5.0] - 2026-03-07

### Adicionado
- Camada HTTP completa com Vapor 4: 6 controllers, 23 rotas
- `HealthController` com endpoints `/health` (liveness) e `/ready` (readiness com check de DB)
- `PatientController` com 8 rotas (CRUD de paciente, família, caregiver, social identity, audit trail)
- `AssessmentController` com 7 rotas PUT para módulos de avaliação
- `ProtectionController` com 3 rotas (placement history, violation reports, referrals)
- `CareController` com 2 rotas (appointments, intake info)
- `LookupController` com GET genérico para 13 tabelas de domínio
- `StandardResponse<T>` wrapper com `meta.timestamp` em todos os endpoints de sucesso
- `AppErrorMiddleware` para padronização global de respostas de erro
- `MetadataValidator` para validação dinâmica contra flags em lookup tables (`dominio_tipo_beneficio`, `dominio_tipo_violacao`)
- `CrossValidator` para validações cruzadas (saúde/sexo-gestante, acolhimento/idade)
- `GracefulShutdownHandler` compatível com SIGTERM do Kubernetes
- Cálculos automáticos no GET: densidade habitacional, 4 indicadores financeiros, perfil etário (8 faixas), vulnerabilidades educacionais (6 indicadores)
- Audit trail com before/after diff nos eventos de assessment e filtro por `?eventType=`
- Obrigatoriedade de `X-Actor-Id` header em todas as mutations
- Migration `NormalizeSchema`: JSONB blobs normalizados para colunas diretas + 8 tabelas filhas + 5 novas lookup tables com metadata
- Migration `CreateAuditTrail`: tabela audit_trail com actor_id
- Migration `AddPerformanceIndexes`: índices de performance
- `docker-compose.yml` para desenvolvimento local (PostgreSQL + app)
- `.env.example` completo com todas as variáveis de ambiente
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
- `SQLKitOutboxRelay` otimizado com processamento em lote, audit trail automático e `processed_at`
- `README.md` atualizado para refletir estado completo do serviço (135 testes, 38 suites)
- `DomainEventRegistryBootstrap` expandido para 17 eventos

## [0.4.0] - 2026-02-24
- Implementação da camada de **Infrastructure** com **SQLKit** e **PostgresKit**.
- Implementação do **Pattern Transactional Outbox** para garantia de entrega de eventos.
- Criação do **SQLKitOutboxRelay** (Actor) para polling assíncrono e distribuição via **AsyncStream**.
- Implementação de **DomainEventRegistry** para decodificação segura de eventos heterogêneos.
- Sistema de **Migrations** programático e idempotente para PostgreSQL.
- Refatoração de eventos de domínio para suporte a `Codable`.

## [0.3.0] - 2026-02-24
- Migração completa da camada de **Application** de TypeScript para Swift 6.
- Implementação de 8 Casos de Uso com *Structured Concurrency* e *Typed Throws*.
- Refatoração de Mappers de erro para um padrão centralizado (`mapError`).
- Suite de testes de aplicação concluída com 100% de cobertura lógica nos serviços.
- Alcance do nível **Platinum (95.95%)** de confiabilidade global do projeto.
- Testes de cobertura adicionados para todos os Enums de erro e Value Objects (PatientId).

## [0.2.0] - 2026-02-24
- Migração de CI de Bun para Swift/Linux com SwiftPM.
- Remoção de setup/login/sync de contracts no pipeline de CI.
- Atualização do workflow de release GHCR para imagem do serviço Swift.
- Migração do Dockerfile para build e runtime baseados em Swift.
- Atualização de `.dockerignore` e `.gitignore` para artefatos Swift.
- Domínio da aplicação concluído (Aggregates, Entities, Value Objects e testes).

## [0.1.0] - 2026-02-22
- Baseline inicial de repositório ACDG.
