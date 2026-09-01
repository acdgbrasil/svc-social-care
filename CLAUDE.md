# CLAUDE.md

Guia operacional do microserviço `social-care` (Swift 6.3 + Vapor 4).

## ⚠️ REGRA INVIOLÁVEL — teste falhando é de quem está no comando

**Não existe "esse teste já falhava".** Se um teste falha enquanto você executa
um ticket, consertá-lo é seu trabalho, mesmo que a quebra seja colateral.

- ❌ "não é do meu escopo, vou seguir"
- ❌ "já falhava antes, documento como pré-existente"
- ✅ "falhou — paro, investigo, conserto, valido a suite verde, sigo"

O CI não distingue falha sua de falha herdada: qualquer vermelho bloqueia merge.
E falha antiga esconde falha nova por fadiga visual. **Exceção:** só se o
usuário mandar pular, explicitamente, com justificativa que vira issue. Nunca
por iniciativa do agente.

## Fonte de verdade, em ordem

1. **O código.** Toda contagem e todo nome são reconstituíveis por um comando.
   Divergiu da doc? O código vence e a doc se corrige.
2. `docs/adr/` — decisões versionadas (índice em `docs/adr/README.md`).
3. `.claude/rules/` e `.claude/skills/` — como fazer, carregado sob demanda.
4. Este arquivo — índice operacional.

## Comandos

```bash
make build                          # build debug
make test                           # suite completa
make regression                     # só regressão (alvo < 5s, ADR-002)
swift test --filter NomeDoTeste     # um teste ou suite
./scripts/check_coverage.sh report  # cobertura por camada, sem gate
./scripts/check_harness.sh          # 14 checagens do harness (ADR-042)
make ci                             # deps → build-release → coverage
docker compose up postgres -d       # Postgres para rodar o serviço
```

## Arquitetura

Clean Architecture + DDD, CQRS e Transactional Outbox. Executável único
(`social-care-s`), fonte em `Sources/social-care-s/`.

```
Domain ← Application ← IO (HTTP, Persistence, EventBus)
                         ↑
                       shared (AppError, DomainProtocols, Ports)
```

- **Domain/** — VOs, agregados, entidades, analytics. Zero dependência externa.
  Bounded contexts: `Kernel/`, `Registry/`, `Assessment/`, `Care/`,
  `Protection/`, `Configuration/`.
- **Application/** — command e query handlers, um diretório por use case
  (`Command/`, `Services/`, `Error/`).
- **IO/** — `HTTP/` (controllers, DTOs, middleware, auth, bootstrap),
  `Persistence/SQLKit/`, `EventBus/`.
- **shared/** — `AppError`, `DomainProtocols`, `Ports/`.

### Invariantes (violar exige ADR, não opinião)

1. **`Domain/` só importa `Foundation`.** Sem Vapor, SQLKit, JWT, NIO.
2. **Dependência aponta só para dentro.** `IO` → `Application` → `Domain`.
3. **Command handler é `actor`**; query handler é `struct`; VOs e commands são
   `struct` imutáveis e `Sendable`.
4. **Todo comando de mutação carrega `actorId: String`**, vindo do `sub` do JWT
   via `req.extractActorId()`. Não existe header de identidade (ADR-023).
5. **Sequência no handler:** `parse (VOs) → validate → domínio → persistir →
   eventos`. Eventos na mesma transação do agregado (Outbox, ADR-014).
6. **CRU, sem delete.** Histórico social inativa-se por flag; a exceção é a
   anonimização LGPD (ADR-039).
7. **Erro de domínio implementa `AppErrorConvertible`**, com código (`PAT-001`),
   `safeContext` sem PII e status HTTP.
8. **Toda rota sob `RoleGuardMiddleware`.** Só `/health` e `/ready` são públicas.
   Roles: `worker`, `owner`, `admin`, `superadmin`.
9. **Suite verde é condição de saída.**

### Outros pontos que economizam descoberta

- **`PersistenceConflictError.uniqueViolation`**: repositório lança o erro
  genérico; o handler de Application traduz para o erro de negócio (ADR-010).
- **`ServiceContainer`** (`IO/HTTP/Bootstrap/`) é o composition root, acessível
  por `Request.services`.
- **`StandardResponse<T>`** com `meta.timestamp` envolve as respostas HTTP.
- **Multi-issuer OIDC (ADR-027, 029, 031)**: aceita Zitadel e Authentik em
  paralelo via `OIDC_JWKS_URLS`, `OIDC_ISSUERS`, `OIDC_AUDIENCES` (CSV).
  `OIDCJWTPayload` lê roles por precedência `roles` → `groups` → claim Zitadel.
- **Não existe `EventBus` injetável** — removido pelo ADR-014. Handler que
  recebe `eventBus:` no `init` é doc velha.

## Convenções

- **Branches**: `feat/<slug>`, `fix/<slug>`, `chore/...`, `docs/...`
- **Commits**: Conventional Commits.
- **Tags SemVer**: obrigatórias para `feat:` (minor) e `fix:` (patch) em `main`.
  Consulte `git tag --sort=-v:refname | head -1` antes de criar. `/release`
  automatiza.
- **Strict concurrency**: Swift 6.3, todas as checagens. Tipo que cruza boundary
  é `Sendable`. Toolchain fixada em `.swift-version` (6.3.3) via Swiftly.
- **Segredos**: nunca hardcoded. `<KEY>_FILE` tem precedência sobre a env.

### Quando criar um ADR

Decisão que (a) muda como se coda, testa ou opera, (b) tem trade-off não-óbvio,
(c) é difícil de reverter, ou (d) substitui decisão anterior → **ADR
obrigatório**. Bug fix e feature de produto **não** viram ADR.

1. Proposta ainda vaga → `docs/adr/BACKLOG.md`.
2. Decisão fechada → ADR novo a partir de `docs/adr/ADR-TEMPLATE.md`, indexado
   em `docs/adr/README.md` e citado no PR.
3. Decisão substituída → o ADR antigo vira `Superseded by ADR-XXX`. Não deletar.

## Onde está o quê

| Preciso de… | Vá para |
|---|---|
| Por que uma decisão é assim | `docs/adr/` (índice em `README.md`) |
| O que ainda está aberto | `docs/GAPS.md` |
| Proposta antes de virar ADR | `docs/adr/BACKLOG.md` |
| O que um campo significa para quem preenche | skill `social-care-suas` |
| Como mexer numa camada | skills `social-care-{domain,application,io,tests}` |
| Regra que vale sempre naquele path | `.claude/rules/` |

O `handbook/` foi aposentado em 2026-09-01 (ADR-043): 63 mil linhas, das quais
55 mil eram um espelho da doc do Swift e do Vapor — esta última em seis idiomas.
O que era conhecimento real virou ADR, rule ou skill.

## Harness (`.claude/`)

| Arquivo | Papel |
|---|---|
| `agents/social-care.md` | Roteador de camada. `memory: project`. |
| `agents/social-care-reviewer.md` | Revisor read-only do diff. `memory: project`. |
| `skills/social-care-{domain,application,io,tests}/` | Uma por camada. |
| `skills/social-care-suas/` | Norma do Prontuário SUAS (os 16 blocos). |
| `skills/novo-usecase/` | `/novo-usecase <BC> <Nome>` — os sete lugares a tocar. |
| `skills/revisar/` | `/revisar [alvo]` — reviewer num subagente isolado. |
| `skills/release/` | `/release` — bump SemVer, CHANGELOG e tag. |
| `rules/domain-analytics.md` | Carrega ao tocar `Domain/`. |
| `rules/testing.md` | Carrega ao tocar `Tests/`. |
| `hooks/regression-gate.sh` | `Stop`: bloqueia fim de turno com suite vermelha. |
| `hooks/domain-imports.sh` | `PostToolUse`: barra import proibido em `Domain/`. |
| `hooks/git-guard.sh` | `PreToolUse`: bloqueia force push. |
| `hooks/test-hooks.sh` | 29 casos cobrindo os hooks. |
| `scripts/check_harness.sh` | 14 checagens de que o harness não mente (ADR-042). |

Os hooks existem porque regra escrita depende de alguém lembrar. Regra de
permissão casa **texto**, não semântica de shell: `git push origin main --force`
escapa de um `deny` por prefixo — por isso o guard de verdade é o hook.

`cleanupPeriodDays: 7` encurta a retenção do transcript: a conversa carrega
trechos de payload de prontuário e o default são 30 dias.

Duas regras para manter isso vivo: **skill não repete ADR** (aponta), e **toda
contagem vem com o comando que a remede**. Para fato de biblioteca, leia a fonte
(`Package.resolved`, o header do módulo, a doc oficial).
