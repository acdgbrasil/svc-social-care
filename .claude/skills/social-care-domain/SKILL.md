---
name: social-care-domain
description: >
  Camada `Sources/social-care-s/Domain/` do social-care — Value Objects,
  agregados, entidades, analytics services e contratos de repositório. Use ao
  criar ou alterar regra de negócio, VO com validação, evento de domínio,
  invariante de agregado, ou ao decidir onde um cálculo deve morar. Cobre os
  bounded contexts Registry, Assessment, Care, Protection, Configuration e o
  Kernel compartilhado.
---

# Domain — o núcleo sem infraestrutura

Verificado em 2026-08-31. Toda contagem aqui é reconstituível com o comando ao
lado; se divergir, o código vence.

## A regra que define a camada

`Domain/` importa **apenas `Foundation`**. Sem Vapor, sem SQLKit, sem JWT, sem
NIO, sem tipo vindo de `Application/` ou `IO/`. Antes de dar um `import`,
pergunte se o domínio ainda compilaria num executável sem servidor HTTP.

```bash
# deve retornar vazio
grep -rn "^import " Sources/social-care-s/Domain/ | grep -v "import Foundation"
```

## Organização

```
Domain/<BoundedContext>/
├── Aggregates/<Nome>/<Nome>.swift          + Errors/ + Events/
├── Entities/<Nome>/<Nome>.swift            + Errors/
├── ValueObjects/<Nome>/<Nome>.swift        + Errors/
├── Analytics/<Nome>Analytics.swift
└── Repository/<Nome>Repository.swift       (protocolo, não implementação)
```

Contextos: `Registry` (agregado `Patient` — o principal), `Assessment`
(`PatientAssessment` + VOs de avaliação social), `Care`
(`SocialCareAppointment`), `Protection` (`Referral`, `RightsViolationReport`),
`Configuration` (lookups), `Kernel` (11 VOs cross-cutting: `Address`, `CEP`,
`CNS`, `CPF`, `LookupId`, `Money`, `NIS`, `PersonId`, `ProfessionalId`,
`RGDocument`, `TimeStamp`).

Agregado grande é fatiado por extensão, não por herança — veja `Patient.swift`
ao lado de `PatientFamily.swift`, `PatientLifecycle.swift`,
`PatientAssessments.swift`, `PatientInterventions.swift`.

## Value Object

`struct` imutável, `Sendable`, que **valida no `init(_:) throws`** e é impossível
de existir em estado inválido. Referência viva: `Kernel/CPF/CPF.swift`.

- Conformances típicas: `Codable, Equatable, Hashable, Sendable`.
- Toda propriedade é `let`. `var` só como computada.
- Erros num enum irmão em `Errors/`, um caso por motivo de rejeição —
  `.empty`, `.invalidLength(value:expected:)`, `.invalidCheckDigits(value:)`.
  Motivo específico, não `.invalid`.
- Formatação de exibição é propriedade computada (`formatted`), nunca a
  representação interna: guarde o dado limpo, formate na saída.

## Agregado

- Encapsula invariante que não pode ser verificada olhando uma entidade só.
- Muta por método nomeado pela intenção de negócio (`discharge`, `readmit`,
  `withdrawFromWaitlist`), nunca por `var` público.
- Registra o fato ocorrido em `uncommittedEvents` via `EventSourcedAggregate`
  (ADR-004, composto por herança de protocolo — agregado que não implementa
  `addEvent`/`clearEvents` não compila).
- Carrega `version` para optimistic locking (ADR-005).
- **Não existe `EventBus`** para injetar: os eventos saem do agregado e são
  persistidos pelo repositório na mesma transação (ADR-014).

## Inteligência no domínio

Cálculo de negócio mora aqui, não no handler nem no controller: densidade
habitacional, indicadores financeiros, perfil etário, vulnerabilidades
educacionais. Ficam em `Analytics/` como serviço puro (entra estado, sai
resultado, sem I/O). O read-side apenas pede o resultado.

Se você se pegar escrevendo `if` de regra social dentro de um handler ou de um
DTO, o lugar certo é aqui.

## Erros

Enum `Sendable, Equatable` por tipo, e a tradução para `AppError` vive em
`extension ...: AppErrorConvertible` — código no formato `PAT-001`, `kind`,
`context` (pode ter PII, uso interno), `safeContext` (sem PII, sai na resposta),
`observability` e status HTTP. Ver `shared/Error/AppError.swift`.

## Contratos de repositório

O protocolo mora no domínio (`Registry/Repository/PatientRepository.swift`); a
implementação SQLKit mora em `IO/`. O domínio define o que precisa, a
infraestrutura obedece — nunca o inverso.

## CRU, no delete

Prontuário social não se apaga: inativa-se por flag e o histórico permanece. A
única erasure é a anonimização de PII disparada por LGPD (ADR-039).

## Antes de terminar

```bash
grep -rn "^import " Sources/social-care-s/Domain/ | grep -v "import Foundation"  # vazio
swift test --filter <SuaSuite>
make regression        # invariantes estruturais, alvo < 5s (ADR-002)
```

Mudou comportamento de domínio? O teste correspondente em
`Tests/social-care-sTests/Domain/v2/` é parte da entrega, não um passo seguinte.
