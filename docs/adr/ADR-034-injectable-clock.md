# ADR-034: Clock injetável em toda leitura de tempo que decide

**Data:** 2026-09-01
**Status:** Aceito
**Supersedes:** —

> **Nota de origem.** Este ADR nasce com atraso. O código já citava `ADR-034`
> em três lugares (`JWKSRefresher.swift`, `JWKSRefreshTest.swift`,
> `ADR-040`) e o arquivo **não existia** — dívida levantada em `docs/GAPS.md`
> ao aposentar o handbook (ADR-043). O ticket **T-034** do
> `REMEDIATION_PIPELINE_2026_05_14.md` reservava esse ID para exatamente este
> tema (achado **S-H-A2**, teste `ClockInjectionTest`, conforme
> `Tests/social-care-sTests/Regression/DomainInvariants/README.md`). A prática
> já era seguida; o que faltava era o registro e o teste que a enforça.

## Contexto

Achado **S-H-A2**: código que lê o relógio do sistema no meio da própria lógica
não é testável deterministicamente. Quem quisesse testar "o cooldown já
passou?", "o crédito voltou?" ou "com que hora o evento foi carimbado?" teria
duas saídas, ambas ruins:

- **dormir** — `try await Task.sleep(for: .seconds(30))` num teste de cooldown
  torna o suite lento e flaky, e colide frontalmente com o alvo de **< 5s** do
  suite de regressão (ADR-002);
- **não testar** — e a regra temporal fica sem rede.

O problema tem duas naturezas, que exigem tratamentos diferentes:

1. **Carimbo** — o instante entra num campo (`occurredAt` do evento,
   `meta.timestamp` da resposta, `reviewed_at` da linha). Não muda decisão
   nenhuma, mas o teste precisa saber qual valor esperar.
2. **Decisão** — o instante determina o comportamento: o cooldown do refresh de
   JWKS (ADR-040), a janela do rate limit (ADR-046), a duração no log de acesso
   (ADR-044). Aqui, sem controle do relógio, não há teste possível sem `sleep`.

## Decisão

**Toda leitura de tempo que carimba ou decide entra por um parâmetro, nunca por
uma chamada ao relógio no meio do corpo.** Em dois formatos, conforme a camada:

### Domínio — default de parâmetro

```swift
public mutating func updateHousingCondition(
    _ condition: HousingCondition?,
    actorId: String,
    at date: TimeStamp = .now      // ← o gancho
) throws {
    ...
    self.recordEvent(HousingConditionUpdatedEvent(..., occurredAt: date.date))
}
```

O default mantém a chamada curta em produção; o parâmetro dá ao teste o
instante congelado (`RegressionFixture.frozenTimestamp`). O domínio **não**
recebe closure: um VO não deve carregar dependência, e `TimeStamp = .now`
resolve no ponto de chamada.

### Componentes que decidem por tempo — closure no `init`

```swift
init(..., now: @escaping @Sendable () -> Date = { Date() })
```

Closure, e não um `Date` fixo, porque o componente é de vida longa e lê o
relógio muitas vezes (o refresher roda em loop; o limitador atende cada
requisição). O par de teste é o `TestClock`
(`Tests/social-care-sTests/Application/TestDoubles/TestClock.swift`), que avança
na mão.

### Fora do escopo, deliberadamente

`Date()` usado como **carimbo em adaptador de saída** — `meta.timestamp` do
`StandardResponse`, `reviewed_at` do `SQLKitLookupRequestRepository`, o `now` do
`SQLKitOutboxRelay`. Ali o instante não muda decisão e não há teste do outro
lado que dependa dele; injetar clock em cada adaptador seria cerimônia sem
contrapartida. Se algum deles passar a **decidir** por tempo (uma política de
expiração, por exemplo), migra para a regra acima.

## Alternativas consideradas

- **`Clock` do Swift (`ContinuousClock`/`SuspendingClock`) como abstração.**
  Descartada: resolve espera (`sleep(until:)`), não leitura de "que horas são".
  O que precisamos é do instante corrente, e `Date` é o tipo que já atravessa o
  domínio (`TimeStamp` embrulha `Date`).
- **Injetar um protocolo `ClockProviding` em vez de closure.** Descartada —
  protocolo de um método só, cujo fake é sempre a mesma coisa. A closure
  `@Sendable () -> Date` é o mesmo contrato sem o cerimonial, e já é o que o
  `JWKSRefresher` usava.
- **Substituir o relógio global no teste (swizzling / variável de ambiente).**
  Descartada: estado global de processo, com o mesmo problema de paralelismo que
  já morde o `OIDCJWTPayloadBootstrap` — testes irmãos rodam em paralelo e um
  atropelaria o outro.
- **Congelar o relógio só no domínio e aceitar `sleep` no IO.** Descartada — é
  justamente no IO que estão as decisões temporais (cooldown, janela), e um
  `sleep` de 30s num teste de cooldown estoura sozinho o alvo do suite.

## Consequências

### Positivas

- Cooldown, janela e duração ganham teste determinístico, sem `sleep`: o suite
  de regressão inteiro roda em ~0,05s.
- O carimbo de evento vira asserção exata (`event.occurredAt == frozen.date`),
  em vez de "está entre antes e depois".
- Um fake único (`TestClock`) serve a todos os casos.

### Negativas / custos

- Mais um parâmetro em cada assinatura que lida com tempo. É ruído real, pago
  pelo default (`= .now`, `= { Date() }`), que mantém o call site limpo.
- A fronteira "carimbo em adaptador fica de fora" é uma linha de julgamento, não
  mecânica: quem adicionar decisão temporal num adaptador precisa lembrar de
  entrar na lista do teste. O teste falha alto quando o caminho some, mas não
  adivinha um componente novo.

### Ações requeridas

- [x] `TestClock` sai do arquivo de teste do JWKS e vira double reaproveitável
      em `Tests/social-care-sTests/Application/TestDoubles/TestClock.swift`
- [x] `ClockInjectionTest` criado (o `Regression/DomainInvariants/README.md` já
      o prometia desde 2026-05-14)
- [x] Âncoras `ADR-034` no código passam a apontar para um arquivo existente
- [x] Componentes novos da borda (ADR-044, ADR-046) nascem com clock injetável

## Plano de adoção

1. Extrair o `TestClock` para `TestDoubles/` e apontar o `JWKSRefreshTest` para lá.
2. Escrever o `ClockInjectionTest`: lint do domínio + prova de carimbo + lista
   dos componentes que decidem por tempo.
3. Ao criar componente com decisão temporal, incluir `now:` no `init` e a
   entrada na lista do teste.

## Como reverter

`git revert` do teste e das assinaturas. Reverter não é reverter uma migração —
não há dado envolvido — mas devolve o serviço ao estado em que regra temporal
não tem teste. Não há razão prevista para isso.

## Teste de regressão

`Tests/social-care-sTests/Regression/DomainInvariants/ClockInjectionTest.swift`:

1. `test_S_H_A2_domain_never_reads_the_clock_inline()` — lint: em
   `Sources/social-care-s/Domain/`, `Date()` e `.now` só aparecem como default
   de parâmetro (exceção: `TimeStamp.swift`, que **define** `.now`).
2. `test_S_H_A2_aggregate_stamps_with_injected_instant()` — o evento sai com
   exatamente o instante injetado; se o agregado voltar a ler o relógio, falha.
3. `test_S_H_A2_time_driven_components_inject_the_clock()` — os componentes que
   decidem por tempo (`JWKSRefresher`, `RateLimitMiddleware`,
   `RequestContextMiddleware`) declaram `@Sendable () -> Date` no `init`.
4. `test_S_H_A2_test_clock_advances_without_sleeping()` — o gancho funciona.

Complementos que exercitam a decisão de verdade:
`JWKSRefreshTest.swift` (cooldown sem dormir, ADR-040) e
`RateLimitRegressionTests.swift` (janela sem dormir, ADR-046).

## Better Pattern para skills

- **Skill atualizada:** `.claude/skills/social-care-tests/SKILL.md` — entrada
  sobre o `TestClock` e a proibição de `sleep` em teste de regra temporal.
- **Regra resumida:** quem carimba recebe `at:`/`now:` com default `.now`; quem
  **decide** por tempo recebe `now: @escaping @Sendable () -> Date` no `init`.
  Teste injeta `TestClock` e avança na mão — teste de regra temporal nunca
  dorme.

## Referências

- [ADR-002](ADR-002-regression-test-policy.md) — alvo de 5s do suite de regressão
- [ADR-040](ADR-040-jwks-runtime-refresh.md) — cooldown do refresh de JWKS, o
  primeiro consumidor do clock injetável
- [ADR-046](ADR-046-rate-limiting.md) — janela do token bucket
- [ADR-044](ADR-044-request-correlation-and-access-log.md) — duração no log de acesso
- `Tests/social-care-sTests/Regression/DomainInvariants/README.md` § T-034 —
  onde o teste estava prometido
- `docs/GAPS.md` — dívida "ADR-030 e ADR-034 citados e inexistentes", que este
  ADR fecha pela metade
