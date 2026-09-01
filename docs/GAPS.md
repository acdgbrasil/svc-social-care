# Gaps abertos — social-care

Substitui o `handbook/IMPLEMENTATION_PLAN.md` (657 linhas, quase todas o
histórico de fases já fechadas). Aqui fica só o que continua aberto.

**Verificado contra o código em 2026-09-01.** Cada linha traz o comando que a
remede — número sem comando envelhece calado.

## Gaps de infraestrutura HTTP

| Gap | O que falta | Verificar |
|---|---|---|
| **G12** | Middleware de request logging / tracing. Observabilidade hoje é só `req.logger`. | `grep -rliE "tracing\|swift-metrics" Sources/social-care-s/IO/HTTP/Middleware/` |
| **G13** | `CORSMiddleware`. Necessário se o front-end consumir o serviço direto (hoje passa pelo BFF). | `grep -rl CORSMiddleware Sources/` |
| **G14** | Rate limiting. | `grep -rliE "ratelimit\|rate_limit" Sources/` |

G1–G11 e G15–G17 fecharam. **G10** (integração HTTP ponta a ponta) fechou em
2026-09-01 — 17 testes em `Tests/social-care-sTests/IO/HTTP/`.

## Propostas promovidas ainda não implementadas

Vinham de `handbook/architecture/IMPROVEMENT_BACKLOG.md`, hoje em
`docs/adr/BACKLOG.md`, onde está a análise completa de cada uma.

| # | Proposta | Estado | Quando deixa de ser opcional |
|---:|---|---|---|
| 05 | `schemaVersion` no protocolo `DomainEvent` interno | Parcial — eventos externos já têm | Antes do 1º consumer externo do Outbox |
| 09 | Library target `ACDGKit` (reuso de `Domain/Kernel/`) | Aberto | Quando `people-context` nascer |
| 10 | ADR de encryption at rest (LGPD) | Aberto | **Antes do 1º PROD com dado real** |
| 11 | Métricas Prometheus em `/metrics` | Aberto | Casa com G12 |
| 12 | Retry com backoff + DLQ no Outbox | Parcial — falta `attempts`, `max_attempts`, `next_attempt_at`, `dlq_at` | Antes de volume de produção |

⚠️ O **#10 não é coberto pelo ADR-039**: anonimizar PII sob demanda (erasure) e
cifrar em repouso são coisas diferentes.

## Dívida no registro de ADRs

Levantada em 2026-09-01 ao migrar o handbook:

- **`ADR-030` e `ADR-034` são citados pelo código e não existem.**
  `JWKSRefresher.swift:70` e `JWKSRefreshTest.swift` citam ADR-034 (clock
  injetável); `RegressionFixture.swift:76` cita ADR-030 (ticket T-030). Ou o
  ADR foi escrito e nunca commitado, ou a âncora nasceu de uma decisão que não
  virou documento. Escrever os dois, ou corrigir as âncoras.
- **`ADR-001` e `ADR-003` são órfãos** — nenhum código, teste ou skill os cita.
  Não é problema por si: ADR é registro histórico, não índice de uso.

Remede com:

```bash
# ADRs citados que não existem
for a in $(grep -rho 'ADR-[0-9]\{3\}' Sources/ Tests/ | sort -u); do
  ls docs/adr/${a}-*.md >/dev/null 2>&1 || echo "$a citado, arquivo ausente"
done
```
