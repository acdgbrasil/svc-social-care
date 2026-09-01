---
name: social-care-io
description: >
  Camada `Sources/social-care-s/IO/` do social-care — controllers Vapor, DTOs,
  middlewares, autenticação OIDC/JWT e RBAC, repositórios SQLKit, migrations,
  Outbox/NATS e o cliente people-context. Use ao criar ou alterar rota, DTO,
  middleware, validação HTTP, tabela, mapper, migration, publicação de evento ou
  integração HTTP de saída.
---

# IO — adaptadores, e o único lugar que conhece o mundo externo

Verificado em 2026-08-31: 6 controllers, 35 rotas, 21 migrations.

> **Esta é a camada menos testada do serviço: 9,1% de cobertura em 7.132
> linhas**, sem nenhum teste de integração HTTP (`app.test`). Ao mexer aqui,
> assuma que a rede de proteção não existe — leia o código vizinho antes de
> supor comportamento.

## Mapa

```
IO/
├── HTTP/
│   ├── Bootstrap/     configure.swift (composition root), ServiceContainer
│   ├── Controllers/   6 controllers, um por área
│   ├── DTOs/          RequestDTOs.swift, ResponseDTOs.swift
│   ├── Middleware/    SecurityHeaders, AppError, JWTAuth, RoleGuard
│   ├── Auth/          OIDCJWTPayload, AuthenticatedUser, JWKSRefresher, TokenIntrospector
│   ├── Validation/    CrossValidator, MetadataValidator
│   └── Extensions/    Request+ActorId
├── Persistence/SQLKit/  repositórios, Mappers/, Models/, Migrations/, Outbox/
├── EventBus/            NATSEventPublisher
└── PeopleContext/       cliente HTTP de saída
```

## Controller

`struct` conformando a `RouteCollection`. O `boot` agrupa por permissão, e **todo
grupo passa por `RoleGuardMiddleware`** (só `/health` e `/ready` escapam, via
`JWTAuthMiddleware.publicPaths`). Padrão em `PatientController.swift`:

```swift
let read  = patients.grouped(RoleGuardMiddleware("worker", "owner", "admin"))
let write = patients.grouped(RoleGuardMiddleware("worker"))
```

Roles reais: `worker`, `owner`, `admin`, `superadmin` — **não** `social_worker`.
`hasRole` aceita chave composta (`social-care:worker` satisfaz `worker`) e
`superadmin` faz bypass.

Handler é `@Sendable private func` que: decodifica o DTO → monta o command com
`actorId: try req.extractActorId()` → chama `req.services.<useCase>.handle(...)`
→ devolve `StandardResponse`/`PaginatedResponse`.

**Toda mutação extrai o `actorId` do JWT** (ADR-023). Nunca aceite identidade de
header, query ou body — não existe `X-Actor-Id`.

Regra transversal de request vive em `Validation/`: `CrossValidator` (coerências
inter-campo, ex. gestante × sexo, idade × acolhimento) e `MetadataValidator`
(flags das lookup tables). Regra de negócio, não: essa é do domínio.

## Autenticação

Multi-issuer durante a migração Zitadel → Authentik (ADR-027/029/031):
`OIDC_JWKS_URLS`, `OIDC_ISSUERS`, `OIDC_AUDIENCES` em CSV. `OIDCJWTPayload` lê
roles por **precedência de presença**: `roles` → `groups` →
`urn:zitadel:iam:org:project:roles`; `roles` vazio **não** cai para o próximo.
`OIDCJWTPayloadBootstrap` registra os validators globalmente para que
`verify(using:)` cheque iss/aud/exp/nbf em qualquer codepath, não só no
middleware (ADR-031). `JWKSRefresher` atualiza chaves em runtime, periódico e
sob demanda por `kid` desconhecido (ADR-040).

Aberto e conhecido: não há pin de `alg` nem leeway de clock skew (issue #25), e
`org_id` é lido mas não enforçado (issue #26).

## Persistência

- Repositório é `struct` que recebe `any SQLDatabase` e implementa o protocolo
  definido no domínio.
- `save` roda dentro de `db.transaction { tx in ... }` e faz, na ordem:
  `SELECT version ... FOR UPDATE` (optimistic lock, ADR-005) → upsert do
  agregado e das tabelas filhas → `INSERT INTO outbox_messages` **na mesma
  transação** (ADR-014). Evento fora da transação é bug, não otimização.
- Violação de unicidade sobe como `PersistenceConflictError.uniqueViolation`
  genérico; quem traduz para o erro de negócio é o handler de Application
  (ADR-010).
- Identidade de entidade-filha usa `DeterministicUUID` + upsert por diff, para
  que atualizar não recrie linha (ADR-021).
- JSONB para payload, `TIMESTAMPTZ` para operacional, `DATE` para conceitual;
  `JSONCodec` é o codec padrão (ADR-022).

## Migration

Arquivo `Migrations/AAAA_MM_DD_NomeDescritivo.swift`, `struct` conformando a
`Migration` com `name`, `prepare(on:)` e `revert(on:)`. Registre em
`configure.swift` — **a ordem da lista é a ordem de execução** e há dependências
reais entre elas (trigger `touch_updated_at()`, FKs de lookup). Controle em
`_migrations` via `SQLKitMigrationRunner`.

Toda tabela tem PK declarada (ADR-006); coluna `*_id` com identidade semântica é
tipada e ganha FK (ADR-007/008); tabela raiz tem `created_at`/`updated_at`
automáticos (ADR-023 do handbook local).

## Outbox e eventos

`SQLKitOutboxRelay` faz polling com `SELECT ... FOR UPDATE SKIP LOCKED`, publica
via `NATSEventPublisher` com header `Nats-Msg-Id` (dedup no JetStream) e marca
`processed_at` — at-least-once, ADR-013. Não há retry com backoff nem
dead-letter: é lacuna conhecida (backlog #12).

## Saída HTTP

Cliente de saída encaminha `Authorization: Bearer <jwt>` do request original
(ADR-023). O `PeopleContext` é fail-secure: indisponibilidade vira
`.unknown(reason:)` → 503, nunca "assume que existe" (ADR-011).

## Log

Erro em camada com PII passa por `LogSanitizer` (`shared/Error/LogSanitizer.swift`,
ADR-017). Nunca interpole `"\(error)"` cru em log de HTTP, persistência ou
event bus.

## Antes de terminar

```bash
swift build
swift test
./scripts/check_coverage.sh report   # confira se IO subiu ou desceu
```

Mexeu em rota? Confirme que o grupo tem `RoleGuardMiddleware` e que a mutação
usa `req.extractActorId()`. São as duas falhas que o compilador não pega.
