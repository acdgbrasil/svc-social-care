# Code Review — Domain Layer (2026-03-06)

## Veredicto: BOM — achados pontuais a corrigir

---

## CRITICOS

### C1. HousingCondition — Erro semantico na validacao
**Arquivo:** `Assessment/ValueObjects/HousingCondition/HousingCondition.swift`
**Linhas:** 109-111, 118-119

1. Bedrooms negativos lancam `.negativeRooms` em vez de um erro proprio (`.negativeBedrooms` nao existe)
2. Bedrooms > Rooms lanca `.bathroomsExceedRooms` — o nome diz "bathrooms" mas a validacao e sobre "bedrooms"

**Correcao:**
- [x] Criar `.negativeBedrooms` e `.bedroomsExceedRooms` no enum `HousingConditionError`
- [x] Corrigir os throws no init
- [x] Teste de regressao

### C2. validatePlacementCompatibility — Validacao sem efeito
**Arquivo:** `Registry/Aggregates/Patient/PatientInterventions.swift:119-137`

O metodo detecta incompatibilidades mas nao lanca nenhum erro. Os blocos `if !hasAdolescent` e `if !hasMinor` estao vazios.

**Correcao:**
- [x] Lancar os erros de incompatibilidade
- [x] Corrigir typo `Situaton` -> `Situation` (M6 junto)
- [x] Teste de regressao

### C4. Cases de erro com nomes em portugues
**Arquivo:** `Registry/Aggregates/Patient/Errors/PatientErrors.swift`

Cases `incompatibleAfastamentoSituation` e `incompatibleGuardaSituation` misturam PT-BR com EN.
Viola a regra: "Ingles para todos os simbolos".

**Correcao:**
- [x] Renomear `incompatibleAfastamentoSituation` -> `incompatiblePlacementSituation`
- [x] Renomear `incompatibleGuardaSituation` -> `incompatibleGuardianshipSituation`
- [x] Atualizar todas as referencias (PatientInterventions, testes)

### C3. PlacementError — Faltam conformances obrigatorias
**Arquivo:** `Protection/Entities/PlacementHistory.swift:55-57`

Faltam `Sendable`, `Equatable`, `AppErrorConvertible` — unico erro do Domain que nao segue o padrao.

**Correcao:**
- [x] Adicionar conformances e implementar `asAppError`
- [x] Teste de regressao

---

## MODERADOS

### M3. IngressInfo — Sem validacao no init
**Arquivo:** `Care/ValueObjects/IngressInfo.swift`

`serviceReason` pode ser string vazia. Inconsistente com `Referral.reason` e `Diagnosis.description`.

**Correcao:**
- [x] Adicionar validacao de `serviceReason` non-empty
- [x] Criar erro `IngressInfoError`
- [x] Teste de regressao

### M4. WorkIncomeVO — Sem validacao de monthlyAmount
**Arquivo:** `Assessment/ValueObjects/WorkAndIncome/WorkAndIncome.swift`

`monthlyAmount` aceita valores negativos. Inconsistente com `SocialBenefit.amount`.

**Correcao:**
- [x] Adicionar validacao `monthlyAmount >= 0`
- [x] Criar erro `WorkIncomeError`
- [x] Teste de regressao

### M5. allFamilyMembers e redundante
**Arquivo:** `Registry/Aggregates/Patient/Patient.swift:93-95`

Computed property identica a `familyMembers` que ja e publica.

**Correcao:**
- [x] Remover `allFamilyMembers`
- [x] Verificar se ha referencias externas

### M6. Typo em case de erro (corrigido junto com C2)
**Arquivo:** `Registry/Aggregates/Patient/Errors/PatientErrors.swift:16`

`incompatibleAfastamentoSituaton` -> `incompatibleAfastamentoSituation`

---

## MENORES

### S1. addEvent e public mas e detalhe interno
**Arquivo:** `Patient.swift:124`
- [x] Reduzir para `internal` (PoP ja expoe via `recordEvent`)

### S2. Comentario orfao
**Arquivo:** `PatientInterventions.swift:139-142`
- [x] Remover comentario `// containsPerson movido...`

### S3. CollectiveSituations e SeparationChecklist sem init publico
**Arquivo:** `PlacementHistory.swift`
- [x] Adicionar `public init` explicitos

### S4. FamilyMember.init e throws mas nunca lanca
**Arquivo:** `FamilyMember.swift`
- [x] Remover `throws` do init

---

## BONUS: Testes existentes corrigidos

### PatientMutationsTests — APIs inexistentes
- `belongsToBoundary` -> `containsPerson` (nome real no codigo)
- `countInAgeRange(min:max:now:)` -> `countMembers(inAgeRange:at:)` (assinatura real)
- `try FamilyMember(...)` -> `FamilyMember(...)` (init nao lanca mais)

---

## ARQUIVOS ALTERADOS

### Domain (Sources)
- `Assessment/ValueObjects/HousingCondition/HousingCondition.swift` — C1
- `Assessment/ValueObjects/HousingCondition/Errors/HousingConditionErrors.swift` — C1
- `Assessment/ValueObjects/WorkAndIncome/WorkAndIncome.swift` — M4
- `Care/ValueObjects/IngressInfo.swift` — M3
- `Protection/Entities/PlacementHistory.swift` — C3, S3
- `Registry/Aggregates/Patient/Patient.swift` — M5, S1
- `Registry/Aggregates/Patient/PatientInterventions.swift` — C2, C4, S2
- `Registry/Aggregates/Patient/Errors/PatientErrors.swift` — C4, M6
- `Registry/Entities/FamilyMember/FamilyMember.swift` — S4

### Application (Sources)
- `Assessment/UpdateHousingCondition/Error/UpdateHousingConditionError.swift` — C1 (propagacao)
- `Assessment/UpdateHousingCondition/Error/UpdateHousingConditionMapperError.swift` — C1 (propagacao)
- `Assessment/UpdateWorkAndIncome/Services/UpdateWorkAndIncomeCommandHandler.swift` — M4 (try)
- `Care/RegisterIntakeInfo/Services/RegisterIntakeInfoCommandHandler.swift` — M3 (try)

### Tests
- `Domain/v2/CodeReviewRegressionTests.swift` — NOVO (18 testes de regressao)
- `Domain/v2/PatientMutationsTests.swift` — correcao de APIs inexistentes
- `Domain/v2/PatientDetailedTests.swift` — try IngressInfo
- `IO/DatabaseMapperTests.swift` — try WorkIncomeVO
- `IO/HTTP/AssessmentRoutesTests.swift` — try WorkIncomeVO

---

## STATUS
- **Inicio:** 2026-03-06
- **Conclusao:** 2026-03-06
- **Build:** PASSANDO (swift build)
- **Testes:** Ambiente requer CNIOLLHTTP (dependencia NIO). Build do target principal OK.
