# ADR-046: Rate limiting por token bucket em memória do processo

**Data:** 2026-09-01
**Status:** Aceito
**Supersedes:** —

## Contexto

Gap **G14** de `docs/GAPS.md`: o serviço não tinha teto de requisições. Sem ele,
sai de graça para quem ataca:

- **Força bruta de token** — martelar `/api/v1/patients` com JWTs forjados. Cada
  tentativa custa uma verificação de assinatura RS256 (CPU) e, com `kid`
  desconhecido, pode disparar refresh de JWKS (o cooldown do ADR-040 limita o
  fetch, não a requisição).
- **Varredura de identificadores** — iterar `patients/<uuid>` atrás de um 200.
- **Exaustão de recursos barata** — cada requisição autenticada abre conexão do
  pool PostgreSQL. O teto de payload (ADR-012) limita o tamanho de cada uma, não
  a quantidade.

O serviço roda em K3s atrás do Caddy, com uma réplica hoje. Não há Redis nem
qualquer store compartilhado no desenho atual.

## Decisão

`RateLimitMiddleware` + `RateLimiter` (actor), **token bucket por chave, em
memória do processo**, ligado por default.

### Token bucket, não janela fixa

Janela fixa deixa passar 2× o limite na virada: o burst do fim de uma janela
soma com o do começo da seguinte. O balde repõe crédito continuamente
(`limit / window` por segundo), absorve burst legítimo até a capacidade e não
tem essa borda. Clock injetável (ADR-034) — o teste avança o tempo em vez de
dormir.

### A chave é o IP, e o limitador vem antes da autenticação

O `sub` do JWT seria a chave ideal, mas só existe **depois** da validação, e
chave tirada de token não validado é forjável — o que anula o limite. Então:
chave = IP, e o middleware roda antes do `JWTAuthMiddleware`. Um limitador
depois do auth nunca veria a força bruta de token: ela morre no 401.

### O ponto desconfortável: atrás de proxy, o IP é do proxy

Com `TRUST_PROXY=false` (default), o IP visto é o do Caddy, e **todos os
usuários compartilham um balde**. Duas escolhas decorrem disso:

- o default de `RATE_LIMIT_REQUESTS` é folgado (**300 por 60s**), calibrado para
  não estorvar o uso real de uma equipe, mesmo somado num balde só;
- o boot **avisa no log** quando o limite está ligado sem `TRUST_PROXY`, para que
  isso seja uma escolha e não uma surpresa.

`TRUST_PROXY=true` só deve ser ligado quando um proxy reescreve
`X-Forwarded-For`. Se qualquer cliente puder falar direto com o serviço, o header
é escolha do atacante e o limite deixa de existir. O primeiro IP da lista é o
cliente (os seguintes são a cadeia de proxies), e o valor passa por validação de
formato antes de virar chave — header é entrada de fora, e string arbitrária
vira entrada nova no dicionário do limitador.

### Posição na cadeia e formato da resposta

`SecurityHeaders → RequestContext → CORS → **RateLimit** → AppError → JWTAuth`.

Por fora do `AppErrorMiddleware`, o limitador recebe a resposta **pronta** —
inclusive as de erro — e anexa a cota a todas elas: quem está queimando crédito
em 401 repetido enxerga isso. Em troca, o 429 é montado aqui, pelo envelope de
erro compartilhado (`AppErrorMiddleware.errorResponse`), e não por tradução de
`Abort`. Um segundo formato de erro, ainda que parecido, viraria dois contratos
para o BFF tratar.

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
(epoch) em toda resposta; `Retry-After` no 429.

### Isenções e teto de memória

`/health` e `/ready` são isentas: o kubelet bate em intervalo fixo e seria o
primeiro a tomar 429 — derrubando o pod que estava saudável. A lista coincide
com as rotas públicas do `JWTAuthMiddleware`, mas o critério é outro (quem chama
é a infra, não um cliente).

O dicionário de baldes tem teto (10.000 chaves). Ao estourar, descarta primeiro
os baldes cheios — balde cheio não deve nada, esquecê-lo não muda decisão — e, se
ainda sobrar, os menos recentes. Nunca os que estão perto do limite.

### Configuração

| Variável | Default | Efeito |
|---|---|---|
| `RATE_LIMIT_ENABLED` | ligado | `false`/`0`/`no`/`off` desliga |
| `RATE_LIMIT_REQUESTS` | `300` | créditos por janela, por chave |
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | tamanho da janela |
| `TRUST_PROXY` | `false` | chave sai de `X-Forwarded-For`/`X-Real-IP` |

Ligado por default porque serviço público sem teto é DoS de custo zero. Desligar
é explícito.

## Alternativas consideradas

- **Deixar rate limit só no Caddy/ingress.** É a camada certa para volume bruto e
  continua valendo. Descartada como única camada pela razão do ADR-012: chamada
  interna na malha não passa pelo gateway, e o serviço fica sem defesa própria.
- **Redis (ou Postgres) como store compartilhado.** É o que dá limite global com
  N réplicas. Descartada agora: acrescenta dependência de infra e um ponto de
  falha na borda — se o store cai, ou o limite abre (fail-open) ou o serviço cai
  junto (fail-closed). Com uma réplica, o ganho é zero. Revisitar ao escalar
  horizontalmente: o teto efetivo é N × `limit`.
- **Janela deslizante com lista de timestamps por chave.** Precisão maior, custo
  de memória proporcional ao número de requisições, não de clientes. O balde
  guarda dois números por chave.
- **Chavear pelo `sub` do JWT após a autenticação.** Não protege o caminho não
  autenticado, que é o mais atacado. Cabe como **segunda** camada, depois desta
  — anotado como evolução, não feito.
- **Ler o `sub` do token sem validar assinatura, só para chavear.** Descartada:
  atacante manda um `sub` novo a cada requisição e escapa do limite; e passaríamos
  a tratar como identidade algo que o serviço declarou não confiar.
- **Desligado por default, opt-in.** Descartada — contraria o fail-secure que o
  ADR-011 estabeleceu. O risco real (indisponibilidade por limite mal calibrado
  atrás de proxy) foi tratado com default folgado e aviso no boot.

## Consequências

### Positivas

- Força bruta e varredura passam a ter custo.
- O cliente recebe cota e `Retry-After` — dá para implementar backoff no BFF.
- Sem dependência nova: o limitador é um `actor` e um dicionário.

### Negativas / custos

- **Por réplica.** Com N pods, o teto efetivo é N × `limit`. Documentado; vira
  problema no dia da segunda réplica.
- **Atrás de proxy sem `TRUST_PROXY`, o balde é comum a todos.** Um cliente
  abusivo consome a cota dos demais. Mitigado pelo default folgado e pelo aviso
  no boot; resolvido de verdade por `TRUST_PROXY=true` com o Caddy preenchendo
  `X-Forwarded-For`.
- **Estado em memória some no restart.** Um deploy zera todos os baldes. Para
  proteção contra abuso, aceitável.
- IPv6: um cliente com /64 tem, na prática, muitos "clientes". Agrupar por
  prefixo fica para quando houver abuso real observado.

### Ações requeridas

- [x] `IO/HTTP/Middleware/RateLimitMiddleware.swift` (config + `RateLimiter` + middleware)
- [x] `AppErrorMiddleware.errorResponse` extraído como envelope compartilhado
- [x] Registro em `configure.swift` com aviso quando falta `TRUST_PROXY`
- [x] Cota exposta no CORS (ADR-045)
- [x] Variáveis documentadas no `README.md`
- [ ] **Ao ligar `TRUST_PROXY`:** confirmar que o Caddy **sobrescreve** (não
      apenas repassa) o `X-Forwarded-For` do cliente
- [ ] **Antes da 2ª réplica:** decidir entre store compartilhado e dividir o
      limite por número de réplicas
- [ ] **Futuro:** segunda camada por `sub`, depois da autenticação

## Plano de adoção

1. Middleware + testes, ligado com o default folgado.
2. Observar o log `rate_limit_exceeded` (traz a **faixa** do IP, não o IP) por
   alguns dias. Se aparecer com tráfego legítimo, é sinal de que o balde comum do
   proxy está apertado: subir `RATE_LIMIT_REQUESTS` ou ligar `TRUST_PROXY`.
3. Ao escalar para duas réplicas, reabrir a decisão do store compartilhado.

## Como reverter

`RATE_LIMIT_ENABLED=false` — sem deploy de código. Reversão completa é remover o
bloco do `configure.swift` e o arquivo.

## Teste de regressão

`Tests/social-care-sTests/Regression/Security/RateLimitRegressionTests.swift`:

1. `test_G14_limit_is_enforced_and_refills()` — o teto vale; o crédito volta com
   o tempo (clock falso, sem `sleep`).
2. `test_G14_refill_is_gradual_not_windowed()` — em 15s de uma janela de 60s com
   limite 4 volta **exatamente um** crédito. É o teste que impede a regressão
   para janela fixa.
3. `test_G14_buckets_are_per_client()` — um cliente abusivo não bloqueia os outros.
4. `test_G14_tracked_keys_are_capped()` — o dicionário tem teto.
5. `test_G14_forwarded_header_ignored_without_trust_proxy()` — o bypass mais
   fácil que existe, fechado.
6. `test_G14_first_forwarded_ip_is_the_client()` / `test_G14_garbage_forwarded_header_is_discarded()`.
7. `test_G14_log_masks_client_address()` — o log guarda a faixa (`/24`, `/48`),
   não o endereço (LGPD).
8. `test_G14_enabled_by_default()` / `test_G14_configuration_from_environment()`.
9. `test_G14_runs_before_authentication()` e `test_G14_uses_shared_error_envelope()`
   — lint de ordem e de formato.

Integração em `EdgeMiddlewareIntegrationTests.swift`: 429 no envelope padrão com
`Retry-After`, cota em resposta permitida **e** em resposta de erro, `/health`
isenta, e nenhum header quando desligado.

## Better Pattern para skills

- **Skill atualizada:** `.claude/skills/social-care-io/SKILL.md` — seção
  "Middlewares de borda".
- **Regra resumida:** rate limit é token bucket por IP, em memória, antes do
  auth e por fora do `AppErrorMiddleware`. Nunca confie em `X-Forwarded-For` sem
  `TRUST_PROXY`; nunca chaveie por claim de token não validado; nunca logue o IP
  inteiro — logue a faixa. Probes de orquestrador são isentas.

## Referências

- [ADR-011](ADR-011-people-context-fail-secure-and-bearer-forwarding.md) — o
  fail-secure que sustenta o "ligado por default"
- [ADR-012](ADR-012-security-headers-and-body-size-limit.md) — teto de payload;
  este ADR é o teto de frequência
- [ADR-034](ADR-034-injectable-clock.md) — o clock da janela
- [ADR-040](ADR-040-jwks-runtime-refresh.md) — o cooldown que este limite
  complementa
- [ADR-044](ADR-044-request-correlation-and-access-log.md),
  [ADR-045](ADR-045-cors-allowlist.md) — a mesma leva de borda
- OWASP API Security Top 10 — API4:2023 Unrestricted Resource Consumption
- IETF draft `ratelimit-headers` — os nomes `X-RateLimit-*` seguem o uso de fato
  dos provedores, não o draft
