# ADR-045: CORS opt-in, por allowlist explícita

**Data:** 2026-09-01
**Status:** Aceito
**Supersedes:** —

## Contexto

Gap **G13** de `docs/GAPS.md`: o serviço não registrava `CORSMiddleware`. Isso
**não** é um bug hoje — o consumidor é o BFF (`frontend/apps/social_care_bff`,
Dart), que fala servidor a servidor, e o gateway Caddy encerra o TLS. Navegador
nenhum chama o social-care direto, e sem navegador não existe CORS.

O gap existe porque isso muda no dia em que um front-end web chamar o serviço
direto — e o caminho de menor esforço nesse dia é o errado. O default de fábrica
do Vapor:

```swift
CORSMiddleware.Configuration.default()   // allowedOrigin: .originBased
```

`.originBased` **ecoa a origem que a requisição mandou**. Ou seja: qualquer site
que tenha conseguido um token do usuário passa a poder chamar a API do navegador
dele. É a configuração que aparece em todo tutorial, e é uma allowlist de
tamanho infinito.

## Decisão

Middleware **opt-in**, com allowlist explícita, montada por `CORSPolicy`:

```swift
if let cors = try CORSPolicy.configuration(
    originsCSV: Environment.get("CORS_ALLOWED_ORIGINS"),
    isProduction: isProduction
) {
    app.middleware.use(CORSMiddleware(configuration: cors))
}
```

1. **Sem `CORS_ALLOWED_ORIGINS`, o middleware não entra na cadeia.** A resposta
   sai sem header de CORS — que é o estado correto enquanto o consumidor for o
   BFF. Nada de "ligado com um default permissivo".
2. **A origem permitida é sempre `.any([...])`**, nunca `.originBased`. O Vapor
   ecoa a origem apenas se ela estiver na lista; fora dela, não emite o header e
   o navegador bloqueia.
3. **`*` é recusado em produção**, com fail-fast no boot (o mesmo padrão de
   `OIDC_ISSUERS` vazio). Fora de produção é aceito, para o front-end local.
4. **`allowCredentials` é `false` e não é configurável.** A autenticação é
   `Authorization: Bearer` (ADR-023/027) — não há cookie de sessão para o
   navegador anexar. Ligar credentials ampliaria a superfície de CSRF sem
   habilitar nada que o serviço use.
5. **Registrado antes do `AppErrorMiddleware`** (o próprio Vapor documenta):
   resposta de erro sem header de CORS chega no navegador como falha de rede
   opaca — o front-end vê "network error" em vez do 403 real.
6. **`exposedHeaders`** inclui `X-Request-Id` (ADR-044) e a cota de rate limit
   (ADR-046). Sem isso o JS enxerga só os headers seguros do CORS, e nem a
   correlação nem a cota chegam ao cliente.
7. Origens são normalizadas (espaços e barra final). O header `Origin` do
   navegador nunca traz barra: uma allowlist com `https://app.org/` nunca casaria,
   e o sintoma seria "CORS não funciona" sem erro nenhum.

## Alternativas consideradas

- **Deixar CORS só no Caddy.** É o que o `README.md` descreve hoje ("CORS/SSL:
  Caddy na VPS gateway"), e continua valendo como primeira camada. Descartada
  como *única* camada, pela mesma razão do ADR-012 quanto aos security headers:
  se o proxy for reconfigurado, trocado ou contornado (chamada interna na malha),
  o serviço fica sem política própria. Aqui as duas convivem — e enquanto o env
  não é setado, o custo de manter isso no serviço é zero.
- **`CORSMiddleware.Configuration.default()`.** É `.originBased`. Ver contexto.
- **Ligar CORS por default com a origem do front-end atual hardcoded.**
  Descartada: hardcode de ambiente no código é a origem do foot-gun que o
  code-review M1 já corrigiu no bootstrap OIDC (dev apontando para IdP de
  produção).
- **`allowCredentials: true` "para o caso de precisar".** Descartada — não há
  cookie no fluxo; seria ampliar superfície por hipótese.

## Consequências

### Positivas

- No dia em que o front-end web chegar, ligar CORS é uma variável de ambiente, e
  a versão segura é a única disponível.
- `.originBased` deixa de ser alcançável por descuido — há teste que falha.
- Cliente de navegador enxerga `X-Request-Id` e a cota de rate limit.

### Negativas / custos

- Uma variável de ambiente a mais para documentar e configurar por ambiente.
- Um preflight `OPTIONS` responde **antes** da autenticação (é o comportamento
  correto — o navegador não manda `Authorization` no preflight), o que expõe a
  existência das rotas a quem já tem uma origem permitida. Aceito: é o desenho do
  CORS, e a resposta não revela nada além do conjunto de métodos.
- Origem errada na lista dá erro silencioso no navegador (sem log no serviço) —
  daí a normalização da barra final.

### Ações requeridas

- [x] `IO/HTTP/Middleware/CORSPolicy.swift`
- [x] Registro condicional em `configure.swift`, antes do `AppErrorMiddleware`
- [x] `CORS_ALLOWED_ORIGINS` documentada no `README.md`
- [ ] **Ao ligar:** conferir se o Caddy não emite os mesmos headers em duplicata
      (dois `Access-Control-Allow-Origin` fazem o navegador rejeitar a resposta)

## Plano de adoção

1. Middleware + política + testes, com o env **não** setado — comportamento em
   produção idêntico ao de antes.
2. Quando um front-end web precisar: setar `CORS_ALLOWED_ORIGINS` com as origens
   reais e verificar, no navegador, que o preflight passa e que não há header
   duplicado vindo do Caddy.

## Como reverter

Remover o bloco condicional do `configure.swift` e o arquivo. Se o problema for
só a configuração, apagar a variável de ambiente já devolve o serviço ao estado
anterior — sem deploy de código.

## Teste de regressão

`Tests/social-care-sTests/Regression/Security/CORSPolicyRegressionTests.swift`:

1. `test_G13_cors_is_opt_in()` — sem env (ou com CSV vazio), não há configuração.
2. `test_G13_never_origin_based()` — a origem permitida é sempre uma lista.
3. `test_G13_configure_does_not_use_vapor_default()` — lint: `configure.swift`
   não chama `CORSMiddleware.Configuration.default()` e passa pela `CORSPolicy`.
4. `test_G13_cors_runs_before_error_middleware()` — ordem no boot.
5. `test_G13_wildcard_rejected_in_production()` / `..._allowed_outside_production()`.
6. `test_G13_never_allows_credentials()`.
7. `test_G13_origins_are_normalized()`.

Integração em `EdgeMiddlewareIntegrationTests.swift`: origem da lista recebe
`Access-Control-Allow-Origin`, origem de fora não recebe, preflight `OPTIONS`
responde 200 sem token, e sem env nenhum header de CORS aparece.

## Better Pattern para skills

- **Skill atualizada:** `.claude/skills/social-care-io/SKILL.md` — seção
  "Middlewares de borda".
- **Regra resumida:** CORS neste serviço é opt-in por `CORS_ALLOWED_ORIGINS` e
  sempre `.any([...])` — `.originBased` e `*` em produção são erro. Sem
  credentials: a autenticação é Bearer. Registrar antes do `AppErrorMiddleware`.

## Referências

- [ADR-012](ADR-012-security-headers-and-body-size-limit.md) — defesa em
  profundidade na borda, mesmo com proxy na frente
- [ADR-023](ADR-023-created-updated-at-on-root-tables.md) e
  [ADR-027](ADR-027-oidc-multi-issuer.md) — a autenticação é Bearer, não cookie
- [ADR-044](ADR-044-request-correlation-and-access-log.md),
  [ADR-046](ADR-046-rate-limiting.md) — os headers expostos
- Vapor `CORSMiddleware` — "Make sure this middleware is inserted before all
  your error/abort middlewares"
- MDN CORS — https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
