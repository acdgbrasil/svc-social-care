---
name: social-care-application
description: >
  Camada `Sources/social-care-s/Application/` do social-care — Commands,
  Queries, handlers (`actor` para escrita, `struct` para leitura), portas de
  validação e mapeamento de erro. Use ao criar ou alterar um caso de uso,
  orquestrar domínio + repositório, adicionar validação de lookup ou de
  existência, ou traduzir erro de persistência em erro de negócio.
when_to_use: >
  Gatilhos: use case, caso de uso, command, query, handler, actor, CQRS, mapError, LookupValidating, PersonExistenceValidating, orquestracao, parse-validate-persist.
---

# Application — orquestração, nunca regra de negócio

Verificado em 2026-08-31: 25 use cases de escrita
(`find Sources/social-care-s/Application -type d -name Command | wc -l`), mais o
read-side em `Query/`.

## Anatomia de um use case

Uma pasta por caso de uso, dentro do bounded context:

```
Application/<BC>/<UseCase>/
├── Command/<UseCase>Command.swift      struct Sendable, tudo `let`
├── UseCase/<UseCase>UseCase.swift      protocolo do handler
├── Services/<UseCase>CommandHandler.swift   actor que implementa
├── Services/<Porta>Validating.swift    portas extras, quando houver
└── Error/<UseCase>Error.swift          + AppErrorConvertible
```

Referência viva completa: `Application/Registry/RegisterPatient/`.

## Command

`struct` conformando a `Command` ou `ResultCommand` (com
`associatedtype Result`). Todas as propriedades `let`. Payloads aninhados
entram como `Draft` (`PersonalDataDraft`, `AddressDraft`) — tipos burros de
transporte, com `String`/`Date` crus. **O command não valida**: quem valida é o
VO, no parse.

**Todo comando de mutação carrega `actorId: String`.** Sem exceção — é o audit
trail. Query não precisa.

## Handler

`actor` (exclusão mútua sob concorrência), conformando a `CommandHandling<C>` ou
`ResultCommandHandling<C>` — ambos exigem `Actor`. Dependências entram pelo
`init` como `any Protocolo`; portas opcionais entram como `(any P)? = nil`.

Handler de leitura é `struct` conformando a `QueryHandling<Q>` — sem estado
mutável, sem `actor`.

## A sequência é obrigatória, nesta ordem

```
1. parse      Strings/Datas do command viram VOs (init throws)
2. validate   lookups (LookupValidating), existência externa (PersonExistenceValidating)
3. domain     chama o método de intenção no agregado
4. persist    repository.save(...) — evento vai na MESMA transação (ADR-014)
5. eventos    já saíram no passo 4; não há publish paralelo
```

Inverter os passos 1 e 2 gera erro errado na resposta (400 de parse quando o
caso era 404 de referência inexistente). Fazer regra de negócio no passo 3 fora
do agregado espalha domínio pela orquestração — é o erro mais comum aqui.

## Erros

Todo o corpo do `handle` fica num `do/catch`, e o `catch` chama uma função
`mapError` **local ao handler**. Ela traduz:

- erro de VO (`CPFError`, `ICDCodeError`) → erro do caso de uso;
- `PersistenceConflictError.uniqueViolation` → o erro de negócio específico
  ("CPF já cadastrado"), nunca vazando o erro genérico (ADR-010);
- `PersistenceConflictError.optimisticLockFailed` → conflito 409.

O erro do caso de uso implementa `AppErrorConvertible`; o `AppErrorMiddleware`
traduz na fronteira HTTP. Handler não conhece status HTTP — ele conhece o
`AppError`, que carrega o status.

## Portas

Validação que precisa sair do processo entra como protocolo `Sendable` definido
aqui, com implementação em `IO/`:

- `LookupValidating` — o valor existe na tabela de domínio? (metadata-driven:
  as opções vivem no banco, não em `enum` estático).
- `PersonExistenceValidating` — a pessoa existe no people-context. Retorna
  **tri-state** `.exists / .notFound / .unknown(reason:)` e **não lança**
  (ADR-011). O `.unknown` vira 503, nunca "assume que existe": fail-secure. O
  `bearer` recebido é encaminhado (ADR-023).

## Read-side

`Query/` tem os handlers de leitura e seus DTOs (`GetPatientById`,
`GetPatientByPersonId`, `ListPatients` com paginação por cursor). O read-side
**não recalcula** regra: pede o resultado ao analytics service do domínio.

## Antes de terminar

```bash
swift test --filter <UseCase>Tests
make regression
```

Todo use case novo entra com suite própria em
`Tests/social-care-sTests/Application/`, usando os fakes de `TestDoubles/` —
ver a skill `social-care-tests`.
