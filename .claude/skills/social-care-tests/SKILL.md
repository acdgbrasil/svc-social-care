---
name: social-care-tests
description: >
  Testes do social-care em `Tests/social-care-sTests/` com `swift-testing` (não
  XCTest) — testes de domínio, de use case com fakes in-memory, de IO e o suite
  de regressão do ADR-002. Use ao escrever ou corrigir qualquer teste, criar um
  fake, investigar teste vermelho ou decidir o que cobrir numa mudança.
when_to_use: >
  Gatilhos: teste, suite, swift-testing, @Test, @Suite, #expect, #require, fake, InMemory, fixture, regressao, cobertura, teste vermelho, TDD.
---

# Testes — `swift-testing`, e suite verde não é negociável

Verificado em 2026-09-01: 504 testes em 89 suites, verdes. Cobertura global
33,73% — `shared` 76,6%, `Domain` 58,6%, `Application` 47,6%, **`IO` 15,10%**
(era 9,1% antes do G10).

## A regra de ouro

Teste vermelho durante o seu ticket é **seu**, mesmo que você não o tenha
quebrado. Não existe "falha pré-existente, sigo em frente": pare, investigue,
conserte, valide a suite verde, continue. A única exceção é o usuário mandar
pular, explicitamente e com justificativa registrada.

## Framework

`swift-testing`, embutido no toolchain — **não XCTest**. Se você digitou
`XCTAssert`, está no framework errado.

```swift
import Testing
import Foundation
@testable import social_care_s

@Suite("RegisterPatient Command Handler")
struct RegisterPatientTests {
    @Test("Deve registrar paciente com dados minimos")
    func successfulMinimalRegistration() async throws {
        // arrange / act / assert
        #expect(patients.count == 1)
        let id = try #require(patients.first?.id)
    }
}
```

- `#expect` para asserção que pode seguir; `#require` para pré-condição cujo
  fracasso invalida o resto (ele lança).
- Nome do `@Test` em português, descrevendo a **regra**, não o método:
  "Deve recusar CPF com dígito verificador inválido".
- Erro esperado: `#expect(throws: CPFError.invalidCheckDigits(value: "...")) { ... }`.
- Suite que muta estado global precisa de `.serialized` — os testes rodam em
  paralelo por padrão. Exemplo real: `IO/Auth/OIDCJWTPayloadTests.swift`, que
  mexe no storage de validators.

## Onde cada teste mora

```
Tests/social-care-sTests/
├── Domain/v2/     VOs, agregados, analytics, invariantes
├── Application/   um arquivo por use case + TestDoubles/
├── IO/            audit trail, Auth (OIDC, JWKS, AuthenticatedUser),
│                  HTTP/ (integração ponta a ponta — G10)
└── Regression/    Concurrency, DataIntegrity, DomainInvariants,
                   ErrorMapping, EventPublication, Security
```

## Fakes

Vivem em `Application/TestDoubles/` e são reaproveitados, não recriados por
suite: `InMemoryPatientRepository`, `InMemoryPatientAssessmentRepository`,
`InMemoryLookupValidator` (e `AllowAllLookupValidator`),
`InMemoryLookupRequestRepository`, `InMemoryLookupAdminRepository`,
`PatientFixture`, `RegressionFixture`.

Fake de repositório é `actor` (o contrato é assíncrono) e expõe o que o teste
precisa inspecionar — `allPatients`, `publishedEvents`. Precisou de um fake
novo? Ele entra em `TestDoubles/`, não no arquivo do teste.

Dados de teste vêm de um `makeCommand(...)` estático com defaults e parâmetros
nomeados, para que cada teste sobrescreva só o campo que está exercitando.

## Teste de use case

Cobrir, no mínimo: caminho feliz, cada erro de validação que o handler mapeia, e
o efeito colateral (agregado salvo, evento registrado). Como o repositório fake
guarda os eventos, verificar publicação é `await repo.publishedEvents`.

## Regressão (ADR-002)

Todo bug corrigido e toda decisão estrutural ganham um teste em `Regression/`,
na subpasta do tema, que falharia na versão anterior. Alvo do suite inteiro:
**menos de 5 segundos** (`make regression`) — ele roda o tempo todo, então nada
de I/O real. Contexto em `Tests/social-care-sTests/Regression/README.md`.

## Cobertura

É termômetro, não gate: o CI reprova por teste vermelho, nunca por percentual.
Não persiga o número — persiga o caminho não exercitado. A leitura por camada
mostra onde ele está:

```bash
./scripts/check_coverage.sh report
```

`IO` ainda é o menor número, mas deixou de ser um vazio: o **G10 fechou em
2026-09-01** e a cadeia `SecurityHeaders → AppError → JWTAuth → RoleGuard →
controller` passou a ser exercitada ponta a ponta.

## Integração HTTP (`IO/HTTP/`)

`HTTPTestApp.withApp { app in ... }` sobe uma `Application` com a **mesma ordem
de middleware** de `configure.swift` — a ordem é a regra sob teste — e entrega
para `app.testing().test(.GET, "/rota") { res in }`.

```swift
try await HTTPTestApp.withApp { app in
    let token = try await HTTPTestApp.token(roles: ["worker"])
    try await app.testing().test(.GET, "/api/v1/patients", headers: .bearer(token)) { res async in
        #expect(res.status == .ok)
    }
}
```

Duas trocas deliberadas em relação a produção, e o que cada uma implica:

- **`StubSQLDatabase`** no lugar do PostgreSQL. Devolve zero linhas para toda
  query, com o `PostgresDialect` real — então serve para afirmar *que a
  requisição chegou no repositório* (`stub.executedSQL`), não para testar SQL.
  Existe porque `ServiceContainer.init` só aceita `any SQLDatabase`: não há
  ponto de injeção para fake de repositório.
- **HMAC local** no lugar do JWKS/RS256. O que se exercita é o pipeline
  (`verify` → roles → RoleGuard → controller), nunca a criptografia.

⚠️ **`OIDCJWTPayloadBootstrap.shared` é global de processo.** Os testes de
integração precisam dele preenchido; `OIDCJWTPayloadTests` o reseta a cada caso.
`.serialized` só ordena os casos *dentro* de uma suíte — entre suítes irmãs não
protege. Por isso todo teste que toca esse storage entra por
`OIDCBootstrapGate.withExclusiveAccess`. Esqueça o gate e o sintoma é um 401
intermitente que parece bug de auth.

## Comandos

```bash
make test                          # suite completa
swift test --filter NomeDoTeste    # um teste ou suite
make regression                    # só regressão, < 5s
./scripts/check_coverage.sh report # cobertura por camada
```
