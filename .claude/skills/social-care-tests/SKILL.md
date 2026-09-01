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

Verificado em 2026-08-31: 487 testes em 88 suites, verdes. Cobertura global
30,72% — `Domain` 58,6%, `Application` 47,6%, `shared` 76,6%, **`IO` 9,1%**.

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
├── IO/            audit trail, Auth (OIDC, JWKS, AuthenticatedUser)
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

O buraco conhecido é `IO`: **não existe nenhum teste de integração HTTP**
(`app.test` do VaporTesting não aparece no repo). Toda a cadeia
`SecurityHeaders → AppError → JWTAuth → RoleGuard → controller` nunca foi
exercitada ponta a ponta — é o gap G10 do `handbook/IMPLEMENTATION_PLAN.md`.

## Comandos

```bash
make test                          # suite completa
swift test --filter NomeDoTeste    # um teste ou suite
make regression                    # só regressão, < 5s
./scripts/check_coverage.sh report # cobertura por camada
```
