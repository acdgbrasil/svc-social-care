# Gaps abertos — social-care

Substitui o `handbook/IMPLEMENTATION_PLAN.md` (657 linhas, quase todas o
histórico de fases já fechadas). Aqui fica só o que continua aberto.

**Verificado contra o código em 2026-09-01.** Cada linha traz o comando que a
remede — número sem comando envelhece calado.

## Gaps de infraestrutura HTTP

**G1–G17 fecharam.** Os três últimos saíram em 2026-09-01:

| Gap | Fechado por | Verificar |
|---|---|---|
| **G12** — logging/tracing | `RequestContextMiddleware` — correlação (`X-Request-Id`/`traceparent`) e log de acesso sem PII. [ADR-044](adr/ADR-044-request-correlation-and-access-log.md) | `grep -rl RequestContextMiddleware Sources/` |
| **G13** — CORS | `CORSPolicy` — opt-in por `CORS_ALLOWED_ORIGINS`, sempre allowlist. [ADR-045](adr/ADR-045-cors-allowlist.md) | `grep -rl CORSPolicy Sources/` |
| **G14** — rate limiting | `RateLimitMiddleware` — token bucket por IP, ligado por default. [ADR-046](adr/ADR-046-rate-limiting.md) | `grep -rl RateLimitMiddleware Sources/` |

**G10** (integração HTTP ponta a ponta) fechou também em 2026-09-01 — hoje
`Tests/social-care-sTests/IO/HTTP/` tem 31 testes:

```bash
swift test --filter "HTTPPipelineIntegrationTests|EdgeMiddlewareIntegrationTests"
```

### O que os três gaps deixaram em aberto

- **Métricas.** Não há `/metrics` nem `swift-metrics`. É a proposta #11 do
  backlog, que casava com o G12 e continua aberta.
  `grep -rliE "swift-metrics|prometheus" Package.swift Sources/`
- **Tracing de verdade.** O `correlation_id` liga logs; não há span nem
  collector. O `TracingMiddleware` do Vapor existe e está a uma linha de
  distância, mas exporta `url.query` (que carrega `?search=<nome/CPF>`) — ver
  "Alternativas consideradas" do ADR-044.
- **Correlação nas chamadas de saída.** `PeopleContextPersonValidator`
  encaminha o Bearer (ADR-023) e **não** encaminha o `X-Request-Id`.
  `grep -n "X-Request-Id" Sources/social-care-s/IO/PeopleContext/*.swift`
- **Rate limit por réplica.** Estado em memória: com N pods o teto efetivo é
  N × `RATE_LIMIT_REQUESTS`. Decisão a reabrir na 2ª réplica (ADR-046).

## Propostas promovidas ainda não implementadas

Vinham de `handbook/architecture/IMPROVEMENT_BACKLOG.md`, hoje em
`docs/adr/BACKLOG.md`, onde está a análise completa de cada uma.

| # | Proposta | Estado | Quando deixa de ser opcional |
|---:|---|---|---|
| 05 | `schemaVersion` no protocolo `DomainEvent` interno | Parcial — eventos externos já têm | Antes do 1º consumer externo do Outbox |
| 09 | Library target `ACDGKit` (reuso de `Domain/Kernel/`) | Aberto | Quando `people-context` nascer |
| 10 | ADR de encryption at rest (LGPD) | Aberto | **Antes do 1º PROD com dado real** |
| 11 | Métricas Prometheus em `/metrics` | Aberto | O G12 fechou sem ela — é o próximo passo de observabilidade |
| 12 | Retry com backoff + DLQ no Outbox | Parcial — falta `attempts`, `max_attempts`, `next_attempt_at`, `dlq_at` | Antes de volume de produção |
| 14 | Unit of Work cross-repository | Aberto, sem demanda | Se um caso de uso precisar escrever em dois agregados atomicamente |

⚠️ O **#10 não é coberto pelo ADR-039**: anonimizar PII sob demanda (erasure) e
cifrar em repouso são coisas diferentes.

## Dívida no registro de ADRs

Levantada em 2026-09-01 ao migrar o handbook, **resolvida no mesmo dia**:

- **`ADR-034` foi escrito** ([clock injetável](adr/ADR-034-injectable-clock.md)).
  As três âncoras no código (`JWKSRefresher.swift`, `JWKSRefreshTest.swift`,
  `ADR-040`) agora apontam para um arquivo que existe, e o
  `ClockInjectionTest` que o `Regression/DomainInvariants/README.md` prometia
  desde maio passou a existir.
- **`ADR-030` não foi escrito, e a âncora sumiu.** Quem o citava era o
  `StubUnitOfWork` do `RegressionFixture` — placeholder de uma decisão nunca
  tomada, cujos dois únicos testes exercitavam o próprio stub. Escrever o ADR
  seria inventar decisão; o stub foi removido e a proposta está no
  `docs/adr/BACKLOG.md` (#14). A atomicidade que ele prometia já é atendida
  pelo repositório, que grava agregado e eventos na mesma transação (ADR-014).
- **`ADR-001` e `ADR-003` seguem órfãos** — nenhum código, teste ou skill os
  cita. Não é problema: ADR é registro histórico, não índice de uso.

Remede com:

```bash
# ADRs citados que não existem
for a in $(grep -rho 'ADR-[0-9]\{3\}' Sources/ Tests/ | sort -u); do
  ls docs/adr/${a}-*.md >/dev/null 2>&1 || echo "$a citado, arquivo ausente"
done
```
