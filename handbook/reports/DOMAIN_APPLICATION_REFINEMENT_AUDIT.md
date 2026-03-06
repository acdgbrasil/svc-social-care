# Auditoria de Refinamento: Domínio e Application (social-care)

Este documento detalha as mudanças necessárias para alinhar o núcleo do microserviço `social-care` com o [Swift API Design Guidelines](../tooling/swift/api-design-guidelines/index.md) e o [Guia CQRS](../tooling/swift/CQRS/index.md).

---

## 1. Visão Geral das Inconsistências

| Categoria | Problema Identificado | Referência da Diretriz |
|-----------|-----------------------|------------------------|
| **Nomenclatura** | Uso de Português (`tipoId`, `Cpf`) e redundâncias (`patientId`). | [Naming - Omit Needless Words](../tooling/swift/api-design-guidelines/index.md#omit-needless-words) |
| **Arquitetura** | Handlers de Comando implementados como `struct` em vez de `actor`. | [CQRS - CommandHandler como actor](../tooling/swift/CQRS/index.md#4-commandhandler-como-actor--mutating-não-existe-em-classesactors) |
| **Fluência** | Métodos como `execute(command:)` não formam frases gramaticais. | [Fluent Usage](../tooling/swift/api-design-guidelines/index.md#strive-for-fluent-usage) |
| **Tipagem** | Uso excessivo de `any Protocol` onde `some Protocol` é preferível. | [CQRS - some vs any](../tooling/swift/CQRS/index.md#some-vs-any-em-cqrs--tabela-de-decisão-rápida) |
| **CQRS** | Protocols de Use Case não herdam de `Actor`. | [CQRS - associatedtype e herança](../tooling/swift/CQRS/index.md#1-definir-os-protocolos-base-com-associatedtype-e-herança-correta) |

---

## 2. Detalhamento por Camada

### 2.1 Camada de Kernel (Value Objects)

#### Mudança: Tradução Total e Padronização
- **Onde:** `Domain/Kernel/Cpf/Cpf.swift`, `Domain/Kernel/RgDocument/RgDocument.swift`, `Domain/Kernel/Nis/Nis.swift`, `Domain/Kernel/Cep/Cep.swift`.
- **O que mudar:** 
    - `Cpf` -> `CPF` (Acronyms uppercase conforme Swift Guidelines).
    - `RgDocument` -> `RG` ou `RGDocument`.
    - `Nis` -> `NIS`.
    - `Cep` -> `CEP`.
    - `tipoId` -> `typeId`.
- **Por que:** Swift Guidelines recomendam que acrônimos sejam uniformemente maiúsculos ou minúsculos.
- **Referência:** [Swift Design Guidelines - Follow Case Conventions](../tooling/swift/api-design-guidelines/index.md#follow-case-conventions).

### 2.2 Camada de Domínio (Aggregates & Entities)

#### Mudança: Refinamento de Propriedades e Métodos
- **Onde:** `Domain/Registry/Aggregates/Patient/Patient.swift` e outros agregados.
- **O que mudar:** 
    - Renomear propriedades redundantes: `Patient.patientId` -> `Patient.id` (já feito, mas verificar consistência em outros agregados).
    - Renomear métodos para fluência: `belongsToBoundary(_:)` está bom, mas `countInAgeRange(min:max:)` poderia ser `countMembers(inAgeRange:)`.
- **Por que:** "Clarity at the point of use is your most important goal."
- **Referência:** [Fundamentals - Clarity at the point of use](../tooling/swift/api-design-guidelines/index.md#clarity-at-the-point-of-use).

### 2.3 Camada de Application (Commands & Services)

#### Mudança: Conversão de Handlers para Actors
- **Onde:** Todos os arquivos em `Application/*/Services/*.swift`.
- **O que mudar:** Mudar de `public struct XService` para `public actor XCommandHandler`.
- **Por que:** Handlers de comando mudam estado e devem garantir exclusão mútua e isolamento.
- **Referência:** [Guia CQRS - CommandHandler como actor](../tooling/swift/CQRS/index.md#4-commandhandler-como-actor--mutating-não-existe-em-classesactors).

#### Mudança: Padronização de Protocolos de Use Case
- **Onde:** Todos os arquivos em `Application/*/UseCase/*.swift`.
- **O que mudar:** 
    - Herdar de `Actor`.
    - Usar `associatedtype C: Command`.
    - Renomear método para `handle(_ command: C)`.
- **Por que:** Padronização CQRS e segurança de concorrência.
- **Referência:** [Guia CQRS - Definir protocolos base](../tooling/swift/CQRS/index.md#1-definir-os-protocolos-base-com-associatedtype-e-herança-correta).

#### Mudança: Commands e ResultCommands
- **Onde:** `Application/*/Command/*.swift`.
- **O que mudar:** Garantir conformidade explícita a `Command` ou `ResultCommand`.
- **Por que:** Detecção em tempo de compilação de conformidade `Sendable`.
- **Referência:** [Guia CQRS - Commands como struct](../tooling/swift/CQRS/index.md#2-commands-como-struct--swift-sintetiza-sendable-e-equatable-gratuitamente).

---

## 3. Plano de Ação (Refactor Checklist)

### Fase 0.1: Kernel & Acronyms
- [ ] Renomear `Cpf` -> `CPF`.
- [ ] Renomear `Nis` -> `NIS`.
- [ ] Renomear `Cep` -> `CEP`.
- [ ] Revisar todos os erros associados (ex: `CpfError` -> `CPFError`).

### Fase 0.2: Application Infrastructure
- [ ] Atualizar protocolos base de CQRS (se existirem globalmente) ou criar em `shared`.
- [ ] Converter `RegisterPatientService` para `RegisterPatientCommandHandler` (actor).
- [ ] Renomear `execute(command:)` para `handle(_:)`.

### Fase 0.3: Domain Refinement
- [ ] Revisar documentação `///` seguindo o formato Markdown do Swift.
- [ ] Garantir que todos os Aggregate IDs usem o padrão `Id` (ex: `PatientId`, `PersonId`).

---

## 4. Referências Cruzadas Rápidas

- **Para Nomes:** `api-design-guidelines/index.md#naming`
- **Para Concorrência:** `api-design-guidelines/concurrency.md`
- **Para CQRS:** `CQRS/index.md`
- **Para Protocolos:** `api-design-guidelines/protocols.md`
