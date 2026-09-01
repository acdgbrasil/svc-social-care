# ADR-044: Correlação de requisição e log de acesso sem PII

**Data:** 2026-09-01
**Status:** Aceito
**Supersedes:** —

## Contexto

Gap **G12** de `docs/GAPS.md`: a observabilidade do serviço era `req.logger`
avulso. Na prática:

- **Duas linhas de log da mesma requisição não tinham como ser reunidas.** O
  Vapor gera um `request-id` interno por requisição, mas ele nasce e morre no
  processo: não vem do chamador, não volta ao chamador, e não aparece no log do
  BFF nem no do gateway. Investigar "o usuário viu erro às 14h03" exigia
  cruzamento manual por timestamp.
- **Requisição bem-sucedida não deixava rastro nenhum.** Não havia como
  responder "essa rota é lenta?", "quem chamou o quê?", "o 403 é frequente?".
- O serviço já tinha um erro **na frente** — o `AppErrorMiddleware` logava —, mas
  o erro sem correlação não fecha com o incidente que o cliente relatou.

Há uma restrição que descarta a solução de prateleira. O Vapor 4 traz um
`TracingMiddleware` pronto (`swift-distributed-tracing` já está no grafo de
dependências), e ele define, entre os atributos do span:

```swift
attributes["url.query"] = request.url.query
```

`GET /api/v1/patients?search=` carrega **nome e CPF** (`PatientController.list`).
Ligar o middleware pronto exportaria PII de paciente para o backend de tracing —
o mesmo vazamento que o ADR-017 fechou nos logs de erro, agora pela porta da
observabilidade. O stack de logs/traces não tem o controle de acesso que o banco
tem.

## Decisão

`RequestContextMiddleware`, próprio, registrado **logo depois** do
`SecurityHeadersMiddleware` e antes de todo o resto. Ele faz três coisas:

### 1. Correlação que atravessa serviços

```
X-Request-Id do chamador  →  senão trace-id do traceparent (W3C)  →  senão UUID novo
```

O valor entra no `Logger.Metadata` como **`correlation_id`** — nome escolhido
para não colidir com o `request-id` que o próprio Vapor injeta — e **sempre**
volta no header `X-Request-Id` da resposta, inclusive em 401, 404 e 429.

Aceitar o `traceparent` é o que permite ao serviço entrar numa cadeia de tracing
existente sem carregar um SDK de OpenTelemetry.

### 2. O id de fora passa por allowlist

`X-Request-Id` é entrada controlada por quem chama. Sem filtro,
`foo\nERROR linha forjada` injeta uma linha inteira no log agregado — mesma
classe de problema que o `LogSanitizer` trata nos erros. Aceitamos
`[A-Za-z0-9._:-]{1,128}` (alfabeto de UUID, ULID e trace-id do W3C); qualquer
outra coisa é descartada e geramos id novo.

### 3. Log de acesso deliberadamente pobre

Uma linha por requisição, com: `http_method`, `http_route`, `http_status`,
`duration_ms`, `correlation_id` e — quando a requisição já passou pela
autenticação — `actor_id`.

**O que fica de fora é a parte importante da decisão:**

| Não logamos | Por quê |
|---|---|
| Query string | `?search=` carrega nome e CPF |
| Corpo | payload de prontuário inteiro |
| Headers | `Authorization` no meio deles |
| Path de rota casada | prefere-se o **template** (`GET /api/v1/patients/:patientId`), que agrega no dashboard e não carrega identificador |

O path só entra quando **nenhuma** rota casa (404) — e sanitizado, porque aí ele
é entrada de quem chamou.

`actor_id` é o `sub` do JWT: o mesmo valor que já vai para `audit_trail`
(ADR-023). É pseudônimo do IdP, não PII direta, e sem ele o log de acesso não
serve para investigar incidente.

Probes (`/health`, `/ready`) são logadas em `debug`: o kubelet bate a cada poucos
segundos e afogaria o log de acesso real. Status ≥ 500 sobe para `error`.

## Alternativas consideradas

- **`TracingMiddleware` do Vapor.** Descartada nesta rodada: exporta `url.query`
  (PII) e, sem um collector configurado, o `InstrumentationSystem` fica no
  no-op — custo de span sem nada do outro lado. Volta a ser a escolha certa
  quando houver collector: aí registra-se com `setCustomAttributes` sobrescrevendo
  `url.query`, e este middleware fica só com o log de acesso.
- **`RouteLoggingMiddleware` do Vapor.** Loga a rota, não o resultado: sem
  status, sem duração, sem correlação.
- **Só propagar o `request-id` interno do Vapor.** Ele é `let`, gerado no
  construtor: não dá para adotar o id do chamador, que é o ponto da correlação.
- **Gerar o id no gateway (Caddy) e confiar nele.** Necessário mas não
  suficiente: o serviço precisa funcionar correlacionado mesmo quando chamado
  direto (dev, teste, outro serviço da malha). E confiar sem allowlist reabre o
  log injection.
- **Adotar OpenTelemetry inteiro agora** (`swift-otel` + collector). Descartada
  por ora: é infraestrutura a mais (collector, storage, retenção) para um
  serviço que ainda não tem nem `/metrics` (proposta #11 do backlog). O
  `traceparent` aceito aqui é o que garante que essa adoção depois não recomeça
  do zero.

## Consequências

### Positivas

- Um id único liga o que o cliente viu, o log de erro e o log de acesso — e
  atravessa BFF e gateway quando eles propagam o header.
- Latência por rota passa a existir como dado.
- O log de acesso nasce sem PII, em vez de nascer com e ser limpo depois.

### Negativas / custos

- Uma linha de log por requisição é volume — mitigado pelo `debug` nas probes.
- `duration_ms` mede o tempo **dentro** da cadeia de middlewares, não o tempo de
  rede do cliente. Para efeito de comparação entre rotas, serve; para SLO
  ponta a ponta, não.
- Middleware próprio é código nosso para manter, onde havia um pronto. O preço
  do `url.query`.

### Ações requeridas

- [x] `IO/HTTP/Middleware/RequestContextMiddleware.swift`
- [x] Registrado em `configure.swift` logo após o `SecurityHeadersMiddleware`
- [x] `X-Request-Id` exposto no CORS (ADR-045) para o front-end conseguir lê-lo
- [ ] **Futuro:** propagar o `correlation_id` nas chamadas de saída
      (`PeopleContextPersonValidator`) — hoje o Bearer é encaminhado, a
      correlação não
- [ ] **Futuro:** `/metrics` + `TracingMiddleware` com `url.query` sobrescrito,
      quando houver collector (backlog #11)

## Plano de adoção

1. Middleware + registro no boot + testes. Sem mudança de contrato: o header
   novo na resposta é aditivo.
2. BFF passa a mandar `X-Request-Id` nas chamadas ao social-care (aproveita o
   mesmo adapter que já encaminha o Bearer, ADR-023).
3. Quando houver collector, avaliar `TracingMiddleware` com atributos filtrados.

## Como reverter

`git revert`: remover o `app.middleware.use(RequestContextMiddleware())` e o
arquivo. O header some da resposta; nada depende dele para funcionar.

## Teste de regressão

`Tests/social-care-sTests/Regression/Security/RequestCorrelationRegressionTests.swift`:

1. `test_G12_access_log_never_reads_query_string()` — lint: o middleware não cita
   `url.query` nem `url.string`. É o teste que impede a regressão de PII.
2. `test_G12_context_runs_before_error_middleware()` — ordem no boot.
3. `test_G12_hostile_correlation_id_is_rejected()` — `\n`, espaço, vazio e id
   longo demais são recusados.
4. `test_G12_wellformed_correlation_id_is_kept()` / `test_G12_explicit_header_wins()`.
5. `test_G12_traceparent_yields_trace_id()` / `test_G12_invalid_traceparent_is_ignored()`
   — inclusive o trace-id "tudo zero" que a spec do W3C proíbe.
6. `test_G12_unmatched_path_is_sanitized()`, `test_G12_duration_uses_injected_clock()`.

Integração em `Tests/social-care-sTests/IO/HTTP/EdgeMiddlewareIntegrationTests.swift`:
header sempre presente, id do chamador preservado, id hostil substituído,
`traceparent` adotado, e **401 também correlacionado**.

## Better Pattern para skills

- **Skill atualizada:** `.claude/skills/social-care-io/SKILL.md` — seção
  "Observabilidade".
- **Regra resumida:** log de HTTP carrega método, template de rota, status,
  duração, `correlation_id` e `actor_id` — **nunca** query string, corpo ou
  header. Valor vindo de header do cliente passa por allowlist antes de virar
  conteúdo de log.

## Referências

- [ADR-017](ADR-017-log-sanitizer-no-pii-in-logs.md) — a mesma política, pelo
  lado dos erros
- [ADR-012](ADR-012-security-headers-and-body-size-limit.md) — a ordem dos
  middlewares de borda
- [ADR-034](ADR-034-injectable-clock.md) — o clock que mede a duração
- [ADR-045](ADR-045-cors-allowlist.md), [ADR-046](ADR-046-rate-limiting.md) — os
  outros dois middlewares de borda desta leva
- `docs/adr/BACKLOG.md` #11 — métricas Prometheus, que casa com este gap
- W3C Trace Context — https://www.w3.org/TR/trace-context/
- OpenTelemetry HTTP spans — https://opentelemetry.io/docs/specs/semconv/http/http-spans/
