# ADR-040: Refresh de JWKS em runtime (periódico + on-demand por `kid`)

**Data:** 2026-07-04
**Status:** Aceito
**Supersedes:** —

> **Promoção → Aceito (ADR-003):** promovido em 2026-07-04 ao fechar o GREEN da
> issue #23 — o teste de regressão `JWKSRefreshTest`
> (`Tests/social-care-sTests/IO/Auth/JWKSRefreshTest.swift`) existe e passa, com
> a suíte inteira verde (468+ testes) e `make coverage` no exit 0
> (gate local de 30% restabelecido — ver "Teste de regressão").

## Contexto

O `social-care` carrega as chaves JWKS **uma única vez no boot**
(`configure.swift:223-255`): faz fetch de cada `OIDC_JWKS_URLS` com retry e chama
`app.jwt.keys.add(jwksJSON:)`. Depois disso o key store (`JWTKeyCollection`)
**nunca é atualizado** — não há refresh periódico nem re-fetch on-demand.

Quando o IdP (Authentik) **rotaciona** a chave de assinatura — operação
rotineira — os tokens novos passam a trazer um `kid` que o serviço não conhece.
Fatos verificados no **jwt-kit 5.3.0** (`JWTKeyCollection.swift`):

- `JWTKeyCollection` é um **`actor`** → mutação em runtime é thread-safe.
- `add(jwk:)` faz **upsert por `kid`** (`storage[kid] = signer`); chaves antigas
  cujo `kid` não veio no novo JWKS **permanecem** (não são removidas). Isso é
  desejável: durante a rotação o IdP serve a chave nova **e** a antiga por um
  tempo, e ambas coexistem no store.
- **Não há hook nativo** de "kid desconhecido → refetch". Pior: com `kid`
  desconhecido, `getSigner` cai no **default signer** (a 1ª chave carregada) e a
  verificação falha na **assinatura** — não existe um erro limpo de "kid ausente"
  para servir de gatilho.

Impacto (P1 — disponibilidade): após uma rotação, **todos os tokens novos são
rejeitados (401 em massa) até o próximo restart** do serviço. Ver issue #23.

Referência de comportamento esperado: o `svc-people-context` (lib `jose`) já faz
refresh automático — cooldown ~30s, cache ~10min, re-fetch ao ver `kid` novo.

## Decisão

Adotamos **refresh híbrido** de JWKS, espelhando o `people-context`:

1. **Periódico** — um background task no ciclo de vida da app re-fetcha todos os
   `OIDC_JWKS_URLS` a cada `intervalo` (default **10min**) e re-aplica via upsert
   por `kid`. Integrado ao `GracefulShutdownHandler` (cancelado no shutdown).
2. **On-demand por `kid`** — o `JWTAuthMiddleware`, ao falhar a verificação,
   extrai o `kid` do header do token (base64url do 1º segmento, sem verificar) e,
   se o `kid` **não** está entre os conhecidos, dispara um refresh (respeitando o
   **cooldown** ~30s) e **retenta a verificação uma vez**. Caminho de erro apenas —
   o caminho feliz (kid conhecido) não paga custo extra.

Componentes:

- **`actor JWKSRefresher`** (`IO/HTTP/Auth/`): estado `knownKids: Set<String>`,
  `lastRefresh`, `cooldown`, `interval`; métodos `refresh()` e
  `refreshIfKidUnknown(_:) -> Bool`. Clock **injetável** (ADR-034) para testar o
  cooldown sem tempo real.
- **`protocol JWKSFetching`** (port): `fetch(url:) async throws -> String`.
  Implementação HTTP via `app.client`; fake nos testes. Desacopla o refresher da
  rede (testável sem IdP).
- O key store é o próprio `app.jwt.keys` (`JWTKeyCollection`, já `actor`); os
  `kid` são extraídos decodificando `JWKS` do JWTKit (não parsing manual).

**Anti-hammering:** o `refreshIfKidUnknown` só re-fetcha se (a) o `kid` é
desconhecido **e** (b) passou o cooldown — um burst de tokens com `kid` inválido
gera no máximo 1 fetch por janela de cooldown por réplica.

## Alternativas consideradas

- **Só periódico (sem on-demand).** Descartada como solução final (mantida como
  MVP possível): cobre a rotação com atraso ≤ intervalo, mas na borda ainda pode
  rejeitar tokens válidos por até 10min. O on-demand fecha essa janela.
- **Só on-demand (sem periódico).** Descartada: sem o periódico, chaves órfãs
  nunca são limpas e o 1º token pós-rotação sempre paga a latência do fetch; o
  periódico mantém o store "morno".
- **Re-fetch em toda falha de verify (sem checar `kid`).** Descartada: um burst
  de tokens inválidos/expirados viraria um fetch-storm contra o IdP. Checar
  `kid ∉ knownKids` + cooldown evita isso.
- **Remover chaves antigas a cada refresh (substituir o set inteiro).**
  Descartada: quebraria tokens ainda válidos assinados com a chave anterior
  durante a janela de rotação. Upsert (mantendo as antigas) é o correto.
- **Depender de um mecanismo nativo do JWTKit.** Não existe (verificado no
  código 5.3.0) — precisa ser implementado.

## Consequências

- **Positivas:** elimina o 401-em-massa pós-rotação (disponibilidade); paridade
  de comportamento com o `people-context`; refresher testável (ports + clock
  injetável); custo zero no caminho feliz.
- **Negativas / custos:** introduz um background task (mais um ponto no
  lifecycle) e estado mutável de `knownKids` (isolado no `actor`); o
  `JWTAuthMiddleware` ganha um caminho de retry no `catch` (hot path de erro);
  precisa de cuidado com anti-hammering (cooldown) para não martelar o IdP.
- **Ações requeridas:** (1) `JWKSRefresher` + `JWKSFetching`; (2) agendamento no
  lifecycle; (3) hook no middleware; (4) `JWKSRefreshTest`; (5) envs de tuning
  opcionais (`OIDC_JWKS_REFRESH_INTERVAL`, `OIDC_JWKS_REFRESH_COOLDOWN`) com
  defaults sãos.

## Plano de adoção

1. [x] `JWKSRefreshTest` (RED) — contrato do refresher com fakes
   (`Tests/social-care-sTests/IO/Auth/JWKSRefreshTest.swift`; fakes `FakeJWKSFetcher`/`FakeKeyStore` + `TestClock`).
2. [x] `protocol JWKSFetching` + `JWKSRefresher` (actor) com clock injetável
   (`Sources/social-care-s/IO/HTTP/Auth/JWKSRefresher.swift`). Inclui `protocol JWKSKeyStore`
   + conformance de `JWTKeyCollection` via extension e `HTTPJWKSFetcher` (impl HTTP via `app.client`).
3. [x] Agendamento periódico no lifecycle via `JWKSRefreshScheduler` (`LifecycleHandler`)
   — `didBoot` inicia o `runPeriodic`; `shutdown` cancela a `Task`.
4. [x] Hook on-demand no `JWTAuthMiddleware` (extrair `kid` do header base64url →
   `refreshIfKidUnknown` → retry 1x; 401 permanece genérico).
5. [x] Ligar no `configure.swift` (bloco "JWKS runtime refresh"); envs
   `OIDC_JWKS_REFRESH_INTERVAL` / `OIDC_JWKS_REFRESH_COOLDOWN` documentadas no `.env.example`.
6. [x] `make coverage` verde → ADR promovido para `Aceito`.

**Desvio de design (documentado):** ao criar o refresher no boot, `knownKids` é
**semeado** com os `kid` já carregados na inicialização (`seedKnownKids(fromJWKS:)`,
a partir dos JSONs coletados no fetch de boot), porque o `JWTKeyCollection` do JWTKit
não expõe API para listar os `kid` do store. Sem a semente, o primeiro token que
falhasse a verificação por outro motivo (ex.: expirado) dispararia um refresh
desnecessário (ainda assim limitado pelo cooldown). A semente elimina esse custo.

## Como reverter

`git revert` do refresher + do hook no middleware + do agendamento. O boot volta
a carregar JWKS só na inicialização (comportamento atual). Sem migração de dados;
reversível sem efeito colateral.

## Teste de regressão

> **Obrigatória (ADR-003).** Presente — por isso o ADR está `Aceito`.

`Tests/social-care-sTests/IO/Auth/JWKSRefreshTest.swift` — garante:
- `refresh()` re-aplica o JWKS no key store e atualiza `knownKids`.
- `refreshIfKidUnknown(kidNovo)` **dispara** refresh (kid desconhecido, fora do cooldown) e retorna `true`.
- `refreshIfKidUnknown(kidConhecido)` **não** dispara (retorna `false`).
- `refreshIfKidUnknown` dentro do **cooldown** **não** dispara (anti-hammering), usando clock injetável.
- **Ciclo completo da rotação** (`rotationMakesRealKeyStoreAcceptNewToken`): um
  token assinado com a chave nova é **rejeitado** por um `JWTKeyCollection` real
  e, após o refresh disparar pelo `kid` desconhecido, **o mesmo token passa a ser
  aceito** — sem restart. É a asserção que prova a tese do ADR; os demais casos
  cobrem as partes isoladas. Usa ECDSA P-256 gerada no próprio teste (o JWTKit só
  materializa JWK de `kty` RSA/EC/OKP — não há `oct`/HMAC em JWKS).

`Tests/social-care-sTests/IO/Auth/JWKSRuntimeRefreshIntegrationTests.swift` —
cobre o que depende do runtime do Vapor: `HTTPJWKSFetcher` (sucesso, corpo vazio,
corpo não-JSON), `JWKSRefreshScheduler` no lifecycle, o storage
`Application.jwksRefresher`, `extractKid` (header válido, token ausente,
malformado, sem `kid`, header não-JSON) e o ramo on-demand do middleware.

## Better Pattern para skills

- **Skill:** `.claude/skills/swift-io-implementer/SKILL.md` — entrada na tabela
  "Lições Aprendidas" apontando para este ADR e o teste.
- **Regra resumida:** chaves de IdP (JWKS) carregadas no boot **precisam** de
  refresh em runtime — periódico (upsert por `kid`, mantendo as antigas) +
  on-demand em `kid` novo com **cooldown** (anti-hammering). Desacoplar o fetch
  atrás de um port (`JWKSFetching`) e usar clock injetável para testar sem rede
  nem tempo real. Nunca substituir o set inteiro de chaves (quebra tokens em voo).

## Referências

- Código atual: `IO/HTTP/Bootstrap/configure.swift:223-255` (bootstrap JWKS),
  `IO/HTTP/Middleware/JWTAuthMiddleware.swift` (verify), `GracefulShutdownHandler`.
- jwt-kit 5.3.0: `JWTKeyCollection.swift` (actor; `add(jwk:)` upsert por `kid`;
  `getSigner` cai no default se `kid` ausente).
- Referência de comportamento: `svc-people-context` (lib `jose` — cooldown 30s /
  cache 10min / re-fetch em `kid` novo).
- ADRs relacionados: **ADR-027** (multi-issuer OIDC), **ADR-031** (verify
  defense-in-depth), **ADR-034** (clock injetável). Issue **#23**.
- Numeração: tema novo fora da faixa reservada 026-038 → ID **≥040** (o T-029/
  ADR-029 do pipeline foi materializado para *precedência de roles*, não para
  JWKS-refresh). Ver `DECISIONS.md`.
