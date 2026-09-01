---
name: novo-usecase
description: Cria um use case de escrita completo no social-care — Command, protocolo, handler `actor`, erro, registro no ServiceContainer, rota e teste. Use ao adicionar um caso de uso novo em qualquer bounded context.
argument-hint: "[BoundedContext] [NomeDoUseCase]"
arguments: bc nome
disable-model-invocation: true
---

# Novo use case: `$nome` em `$bc`

Criar um use case toca **sete** lugares. Esquecer um deles compila e passa nos
testes — e some do audit trail, ou fica sem rota. Esta é a lista fechada.

Se `$bc` ou `$nome` vieram vazios, pergunte antes de criar arquivo. Bounded
contexts válidos: `Registry`, `Assessment`, `Care`, `Protection`,
`Configuration`.

## Antes de escrever

Leia o use case mais próximo do seu como referência viva — não copie deste
arquivo, copie do código, que é o que está atualizado:

```bash
ls Sources/social-care-s/Application/$bc/
find Sources/social-care-s/Application/Registry/RegisterPatient -type f
```

Se o caso de uso muda um agregado que ainda não tem o método de intenção
correspondente, **comece pelo domínio** (skill `social-care-domain`): o handler
orquestra, não decide.

## Os sete lugares

**1. `Application/$bc/$nome/Command/$nomeCommand.swift`**
`struct` conformando a `Command` (sem retorno) ou `ResultCommand` (com
`associatedtype Result`). Tudo `let`. Campos crus (`String`, `Date`) em structs
`Draft` aninhadas — quem valida é o VO, no handler. **Inclua `actorId: String`**:
é mutação, logo tem audit trail.

**2. `Application/$bc/$nome/UseCase/$nomeUseCase.swift`**
O protocolo do handler, para o controller depender da abstração.

**3. `Application/$bc/$nome/Services/$nomeCommandHandler.swift`**
`public actor` implementando o protocolo. Dependências por `init` como
`any Protocolo`. O corpo do `handle` segue a sequência, nesta ordem:

```
parse (VOs, init throws) → validate (LookupValidating / existência)
→ método de intenção no agregado → repository.save(...) → fim
```

Não existe `EventBus` para injetar: o repositório persiste os eventos na mesma
transação (ADR-014). Todo o corpo vai num `do/catch` cujo `catch` chama uma
função `mapError` local.

**4. `Application/$bc/$nome/Error/$nomeError.swift`**
`enum ... : Error, Sendable, Equatable` + `extension: AppErrorConvertible`, com
código `XXX-NNN` novo (confira os existentes no BC para não repetir), `kind`,
`context`, `safeContext` **sem PII** e status HTTP. Mapeie
`PersistenceConflictError.uniqueViolation` para o erro de negócio específico
(ADR-010).

**5. `IO/HTTP/Bootstrap/ServiceContainer.swift`**
Um `let` na struct e a instanciação no `init`. Sem isso o handler existe e
ninguém o alcança.

**6. `IO/HTTP/Controllers/<Área>Controller.swift`**
Rota dentro de um grupo com `RoleGuardMiddleware` (`worker` para escrita).
Handler `@Sendable private func` que decodifica o DTO, monta o command com
`actorId: try req.extractActorId()` e devolve `StandardResponse`. Se o payload
for novo, o DTO entra em `IO/HTTP/DTOs/RequestDTOs.swift`.

**7. `Tests/social-care-sTests/Application/$nomeTests.swift`**
`@Suite` com `makeCommand(...)` estático de defaults nomeados. Cobrir: caminho
feliz, cada erro que o `mapError` traduz, e o efeito colateral (agregado salvo,
evento registrado). Fakes de `TestDoubles/` — nada de repositório novo dentro do
arquivo de teste.

## Fechamento

```bash
swift build
swift test --filter $nomeTests
make regression
```

Ao terminar, diga em uma linha quais dos sete lugares você tocou e por que
deixou algum de fora, se for o caso. Rota ausente ou `actorId` faltando são as
duas omissões que ninguém percebe até produção.
