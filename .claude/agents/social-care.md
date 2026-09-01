---
name: social-care
description: >
  Ponto de entrada para qualquer trabalho no microserviço `social-care`
  (Swift 6.3 + Vapor 4; Clean Architecture + DDD, CQRS, Transactional Outbox).
  Roteia para as skills de camada (`social-care-domain`, `social-care-application`,
  `social-care-io`, `social-care-tests`), aplica as invariantes do projeto e a
  sequência obrigatória dos command handlers. Use quando a tarefa tocar
  `Sources/social-care-s/` ou `Tests/social-care-sTests/`.
---

# social-care — roteador de camada

Microserviço de prontuário social da ACDG. Swift 6.3 strict concurrency, Vapor 4,
PostgreSQL via SQLKit. Executável único: `social-care-s`.

## Fonte de verdade, em ordem

1. **O código.** Toda contagem e todo nome nesta pasta são reconstituíveis por um
   comando — se doc e código divergirem, o código vence e a doc se corrige.
2. `handbook/architecture/DECISIONS/ADR-NNN-*.md` — decisões versionadas.
3. `handbook/architecture/README.md` — princípios v2.0.
4. `CLAUDE.md` — índice operacional.

Estas skills **não repetem** o handbook: elas dizem o que fazer e apontam o
arquivo-âncora. Se você precisar do porquê de uma decisão, leia o ADR.

## Mapa (medido em 2026-08-31 — o comando ao lado remede)

| Fato | Valor | Como remedir |
|---|---|---|
| Camadas | `Domain/`, `Application/`, `IO/`, `shared/` | `ls Sources/social-care-s/` |
| Bounded contexts | Registry, Assessment, Care, Protection, Configuration (+ Kernel) | `ls Sources/social-care-s/Domain/` |
| Use cases de escrita | 25 | `find Sources/social-care-s/Application -type d -name Command \| wc -l` |
| Controllers | 6 | `ls Sources/social-care-s/IO/HTTP/Controllers/` |
| Rotas | 35 | `grep -rhoE "\.(get\|post\|put\|patch\|delete)\(" Sources/social-care-s/IO/HTTP/Controllers/ \| wc -l` |
| Migrations | 21 (+ `Migration.swift` e o runner) | `ls Sources/social-care-s/IO/Persistence/SQLKit/Migrations/` |
| Testes | 487 em 88 suites, verdes | `swift test` |
| Cobertura | 30,72% global — `IO` 9,1%, `Application` 47,6%, `Domain` 58,6%, `shared` 76,6% | `./scripts/check_coverage.sh report` |

## Roteamento

| A tarefa toca… | Skill |
|---|---|
| VO, agregado, entidade, regra de negócio, analytics, contrato de repositório | `social-care-domain` |
| Command, Query, handler, orquestração, mapeamento de erro | `social-care-application` |
| Controller, DTO, middleware, auth/JWT, SQLKit, migration, Outbox, cliente HTTP | `social-care-io` |
| Qualquer teste, fake, fixture, regressão | `social-care-tests` |

Tarefa que atravessa camadas segue o fluxo de dependência: **Domain → Application
→ IO → testes**. Não comece pelo controller.

## Invariantes (violar exige ADR, não opinião)

1. **`Domain/` não importa nada além de `Foundation`.** Sem Vapor, SQLKit, JWT,
   NIO. É o limite que mantém o domínio testável sem infraestrutura.
2. **Fluxo de dependência só aponta para dentro.** `IO` conhece `Application`
   conhece `Domain`. Nunca o contrário.
3. **Command handler é `actor`.** Query handler é `struct`. VOs e Commands são
   `struct` imutáveis e `Sendable`.
4. **Todo comando de mutação carrega `actorId: String`**, derivado do `sub` do
   JWT via `req.extractActorId()`. Não existe header de identidade (ADR-023).
5. **Sequência obrigatória no handler:** `parse (VOs) → validate (lookups,
   existência) → lógica de domínio → persistir → eventos`. Eventos vão na mesma
   transação do agregado (Outbox, ADR-014).
6. **CRU, no delete.** Histórico social não se apaga; inativa-se por flag. A
   exceção é a anonimização de PII por LGPD (ADR-039).
7. **Erro de domínio implementa `AppErrorConvertible`** e nasce com código
   (`PAT-001`), `safeContext` sem PII e status HTTP.
8. **Toda rota fica sob `RoleGuardMiddleware`.** Só `/health` e `/ready` são
   públicas.
9. **Suite verde é condição de saída.** Teste vermelho durante um ticket é seu,
   mesmo que você não o tenha quebrado — ver `CLAUDE.md`.

## Comandos

```bash
make build                        # build debug
make test                         # suite completa
make regression                   # só o suite de regressão (alvo < 5s, ADR-002)
swift test --filter NomeDoTeste   # um teste
./scripts/check_coverage.sh report # cobertura por camada, sem gate
make ci                           # deps → build-release → coverage (piso local 25%)
docker compose up postgres -d      # Postgres para rodar o serviço
```

## Armadilhas — coisas que a documentação antiga afirmava e são falsas

Este harness foi reescrito do zero em 2026-08-31 porque o anterior ensinava
padrões que o código já tinha abandonado. Cuidado especificamente com:

- **Não existe `EventBus` injetável.** Foi removido pelo ADR-014; o repositório
  persiste os eventos na mesma transação. Handler que recebe `eventBus:` no
  `init` é código morto de doc velha — confira em
  `Sources/social-care-s/shared/Domain/DomainProtocols.swift`.
- **As roles são `worker`, `owner`, `admin`, `superadmin`** — não `social_worker`.
  `AuthenticatedUser.hasRole` aceita chave composta: `social-care:worker`
  satisfaz `worker`, e `superadmin` faz bypass de todos os guards.
- **Cobertura é termômetro, não gate.** O CI reprova por teste vermelho; não há
  meta de 95% (a promessa existiu por meses sem nunca ter sido rodada).
- **Não existe "reference network".** O `settings.json` antigo apontava para
  `../infra/reference-network`, inexistente, e o `CLAUDE.md` mandava consultar
  agentes `acdg-ref:*` que não existem neste repo. Para fato de biblioteca, leia
  a fonte: `Package.resolved`, o header do módulo, ou a doc oficial.
- **Swift é 6.3.3** (`.swift-version`), não 6.2. Container: `swift:6.3-jammy`.
