# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Comandos

```bash
make deps              # Resolver dependências SwiftPM
make build             # Build debug
make build-release     # Build release (--product social-care-s)
make dev               # swift run social-care-s (requer PostgreSQL rodando)
make test              # Executar todos os testes
make coverage          # Testes + gate de cobertura (30% local, 95% no CI)
make ci                # Pipeline completo: deps → build-release → coverage

# Teste individual
swift test --filter NomeDoTeste

# PostgreSQL via Docker para dev local
docker compose up postgres -d
```

## Arquitetura

Microserviço Swift 6.2 / Vapor 4 com Clean Architecture + DDD, CQRS e Transactional Outbox. Código fonte em `Sources/social-care-s/`, testes em `Tests/social-care-sTests/`.

### Camadas e fluxo de dependência

```
Domain ← Application ← IO (HTTP, Persistence, EventBus)
                         ↑
                       shared (AppError, DomainProtocols, Ports)
```

- **Domain/** — Value Objects, Agregados, Entidades, Analytics services. Zero dependências externas. Organizado por bounded context: `Kernel/` (VOs cross-cutting), `Registry/`, `Assessment/`, `Care/`, `Protection/`, `Configuration/`.
- **Application/** — Command/Query handlers. Cada use case segue a estrutura `<UseCase>/Command/`, `<UseCase>/UseCase/` (protocolo), `<UseCase>/Services/` (handler `actor`), `<UseCase>/Error/`. Organizado por BC: `Registry/`, `Assessment/`, `Care/`, `Protection/`, `Configuration/`, `Query/`.
- **IO/** — Adapters. `HTTP/` (Controllers, DTOs, Middleware, Auth, Validation, Bootstrap), `Persistence/SQLKit/` (repositórios, mappers, migrations), `EventBus/` (Outbox).
- **shared/** — `AppError` (erro padronizado com código tipo PAT-001, category, severity), `DomainProtocols` (Command, Query, EventBus, EventSourcedAggregate), `Ports/` (protocolos de integração), `PersistenceConflictError`.

### Padrões-chave

- **Use cases são `actor`**: garantem exclusão mútua. Implementam `CommandHandling<C>` ou `ResultCommandHandling<C>`.
- **VOs e Commands são `struct Sendable`**: imutáveis, seguros para concorrência.
- **Validação de VOs via `init(_ raw:) throws`**: CPF, NIS, CEP, etc. fazem parsing no construtor.
- **Erros de domínio implementam `AppErrorConvertible`**: traduzem para `AppError` na fronteira IO.
- **`PersistenceConflictError.uniqueViolation`**: repositórios lançam este erro genérico para violações de unicidade; o handler de Application mapeia para o erro de negócio específico.
- **Repository contracts são `protocol`** definidos em Domain (ex: `PatientRepository` em `Domain/Registry/Repository/`).
- **`ServiceContainer`** em `IO/HTTP/Bootstrap/` é o composition root — instancia todos os handlers e repositórios, acessível via `Request.services`.
- **StandardResponse\<T\>** com `meta.timestamp` envolve todas as respostas HTTP.
- **Header `X-Actor-Id`** obrigatório em mutações (auditoria/audit trail).

### Sequência obrigatória em command handlers

```
parse (VOs) → validate (lookups, existence) → domain logic → persist → publish events
```

Erros são capturados com `do/catch` no handler e mapeados via função `mapError` local.

### Testes

- Framework: `swift-testing` (não XCTest)
- Test doubles em `Tests/social-care-sTests/Application/TestDoubles/`: `InMemoryPatientRepository`, `InMemoryEventBus`, `InMemoryLookupValidator`, `PatientFixture`
- Cobertura mínima: **95%** enforçada no CI via `scripts/check_coverage.sh`
- Testes de domínio em `Tests/.../Domain/v2/`, de application em `Tests/.../Application/`, de IO em `Tests/.../IO/`

## Convenções

- **Branches**: `feat/<slug>`, `fix/<slug>`, `chore/...`
- **Commits**: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`)
- **Tags SemVer**: obrigatórias para `feat:` (minor bump) e `fix:` (patch bump) em `main`. Consultar `git tag --sort=-v:refname | head -1` antes de criar nova tag.
- **Strict concurrency**: Swift 6.2 com todas as checks habilitadas. Todo tipo público que cruza boundary de concorrência deve ser `Sendable`.
