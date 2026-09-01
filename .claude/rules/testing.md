---
paths:
  - "Tests/social-care-sTests/**"
---

# Testes — o que vale sempre

Detalhe e exemplos ficam na skill `social-care-tests`. Aqui só o que precisa
estar em contexto sempre que você tocar um teste.

- **Framework é `swift-testing`, não XCTest.** Se digitou `XCTAssert`, está no
  framework errado. `import Testing`, `@Suite`, `@Test`, `#expect`, `#require`.
- **Test doubles são reaproveitados**, em `Application/TestDoubles/`. Fake novo
  entra lá, não no arquivo do teste.
- **Cobertura é termômetro, não gate.** O CI reprova por teste vermelho, nunca
  por percentual. Não persiga o número — persiga o caminho não exercitado.
  Leitura: `./scripts/check_coverage.sh report`.
- **Regressão (ADR-002)**: bug corrigido e decisão estrutural ganham teste em
  `Regression/`, que falharia na versão anterior. Alvo do suite: **< 5s** — sem
  I/O real.

## Duas armadilhas deste suite

**`OIDCJWTPayloadBootstrap.shared` é global de processo.** Os testes de
integração HTTP precisam dele preenchido; `OIDCJWTPayloadTests` o reseta a cada
caso. `.serialized` só ordena casos *dentro* de uma suíte — entre suítes irmãs,
que rodam em paralelo, não protege. Todo teste que toca esse storage entra por
`OIDCBootstrapGate.withExclusiveAccess`. Esquecer disso produz um 401
intermitente que parece bug de auth.

**Integração HTTP não usa PostgreSQL.** `HTTPTestApp.withApp { app in ... }`
sobe a `Application` com a mesma ordem de middleware de `configure.swift` — a
ordem *é* a regra sob teste. `StubSQLDatabase` devolve zero linhas com o
`PostgresDialect` real: serve para afirmar que a requisição chegou ao
repositório (`executedSQL`), não para testar SQL. O RS256/JWKS é trocado por
HMAC local.
