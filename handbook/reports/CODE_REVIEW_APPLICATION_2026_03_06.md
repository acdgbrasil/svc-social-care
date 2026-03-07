# Code Review — Application Layer (2026-03-06)

## Veredicto: BOM — achados pontuais a corrigir

---

## CRITICOS

### C1. UpdatePlacementHistoryCommandHandler — Logica de dominio duplicada
**Arquivo:** `Protection/UpdatePlacementHistory/Services/UpdatePlacementHistoryCommandHandler.swift`
**Linhas:** 36-41

O handler replica inline a verificacao de adolescente em internacao:
```swift
if command.separationChecklist.adolescentInInternment {
    let hasAdolescent = patient.hasAnyMember(inAgeRange: 12...17)
    guard hasAdolescent else {
        throw UpdatePlacementHistoryError.incompatibleSeparationSituation
    }
}
```

Essa mesma logica ja existe no dominio em `Patient.validatePlacementCompatibility(_:now:)` (corrigida no code review de Domain). O handler tambem ignora a verificacao de `thirdPartyGuardReport` (guardianship) que o dominio faz.

**Violacao:** Principio DDD — logica de negocio deve residir no dominio, Application apenas orquestra.

**Correcao:**
- [x] Substituir a verificacao inline por chamada a `patient.validatePlacementCompatibility(history)`
- [x] Atualizar mapper para propagar `PatientError.incompatiblePlacementSituation` e `.incompatibleGuardianshipSituation`

### C2. AddFamilyMemberCommandHandler — ID hardcoded (mock)
**Arquivo:** `Registry/AddFamilyMember/Services/AddFamilyMemberCommandHandler.swift`
**Linha:** 51

```swift
let prId = try LookupId("00000000-0000-0000-0000-000000000001") // Mock ID para PR
```

O `primaryReferenceId` esta hardcoded com UUID zerado. Isso significa que `addMember` SEMPRE recebe o mesmo `prId`, ignorando o relacionamento real.

**Correcao:**
- [x] Adicionado `prRelationshipId` ao `AddFamilyMemberCommand`
- [x] Handler usa `command.prRelationshipId` em vez de UUID hardcoded

### C3. Query Error Enums — Faltam conformances obrigatorias
**Arquivo:** `Query/PatientQueries/GetPatientByIdQueryHandler.swift:12`
**Arquivo:** `Query/PatientQueries/GetPatientByPersonIdQueryHandler.swift:12`

Ambos os erros declaram apenas `Error, Equatable`. Faltam `Sendable` e `AppErrorConvertible`, quebrando o padrao de TODOS os outros erros da Application.

```swift
// Atual:
public enum GetPatientByIdError: Error, Equatable { ... }

// Esperado:
public enum GetPatientByIdError: Error, Sendable, Equatable, AppErrorConvertible { ... }
```

**Correcao:**
- [x] Adicionado `Sendable, AppErrorConvertible` a `GetPatientByIdError` (QPB-001)
- [x] Adicionado `Sendable, AppErrorConvertible` a `GetPatientByPersonIdError` (QPP-001, QPP-002)

### C4. PatientRegistrationError — Falta Equatable
**Arquivo:** `Query/PatientRegistration/PatientRegistrationError.swift:4`

Todos os erros da Application seguem `Error, Sendable, Equatable, AppErrorConvertible`. Este enum so tem `Error, Sendable, AppErrorConvertible` — falta `Equatable`.

**Correcao:**
- [x] Adicionado `Equatable` a `PatientRegistrationError`

---

## MODERADOS

### M1. PatientRegistrationService — Orquestracao incompleta
**Arquivo:** `Query/PatientRegistration/PatientRegistrationService.swift`

O `PatientRegistrationRequest` aceita `familyMembers: [FamilyMemberDraft]` mas o servico ignora completamente esse campo. A dependencia `AddFamilyMemberUseCase` sequer e injetada.

**Correcao:**
- [ ] Injetar `AddFamilyMemberUseCase` no service
- [ ] Iterar `request.familyMembers` e chamar `addFamilyMember.handle(...)` apos o registro
- [ ] Ou remover `familyMembers` do `PatientRegistrationRequest` se a feature nao esta pronta (marcar como TODO explicito)

### M2. PatientQueryDTO — DTOs rasos demais
**Arquivo:** `Query/PatientQueries/PatientQueryDTO.swift`

Os DTOs mapeiam apenas uma fracao dos campos do dominio:
- `PersonalDataDTO`: so `firstName`, `lastName` (falta: motherName, nationality, sex, socialName, birthDate, phone, cpf, nis, rg, civilDocuments, address)
- `HousingConditionDTO`: so `type` (falta: todos os 14 campos restantes)
- `WorkAndIncomeDTO`: so `totalWorkIncome` calculado (falta: membros individuais, beneficios)
- `FamilyMemberDTO`: so `personId`, `relationship` (falta: isPrimaryCaregiver, residesWithPatient, birthDate, hasDisability)
- `DiagnosisDTO`: so `icdCode`, `description` (falta: date)
- **Ausentes**: educationalStatus, healthStatus, socioEconomicSituation, placementHistory, intakeInfo, socialIdentity, communitySupportNetwork, socialHealthSummary, appointments, referrals, violationReports

**Correcao:**
- [ ] Expandir DTOs conforme necessario para a camada HTTP (pode ser feito junto com Phase 3 Vapor)
- [ ] No minimo adicionar `date` ao `DiagnosisDTO` e campos basicos ao `FamilyMemberDTO`

### M3. PatientRegistrationError — Variavel descartada sem uso
**Arquivo:** `Query/PatientRegistration/PatientRegistrationError.swift:21`

```swift
case .familyMemberFailed(let memberId, let e):
    let base = e.asAppError
    _ = memberId // contexto disponivel para enriquecimento futuro
    return base
```

O `memberId` e capturado e imediatamente descartado com `_ =`. Deveria ser incluido no contexto do `AppError` ou removido do case.

**Correcao:**
- [x] `memberId` agora incluido no `context` do AppError como `failedMemberId`

---

## MENORES

### S1. Inconsistencia find(byId:) vs find(byPersonId:)
**Handlers que usam `find(byId:)` com PatientId:**
- `RemoveFamilyMemberCommandHandler` (command.patientId -> PatientId)
- `UpdatePlacementHistoryCommandHandler` (command.patientId -> PatientId)
- `UpdateSocialIdentityCommandHandler` (command.patientId -> PatientId)

**Handlers que usam `find(byPersonId:)` com PersonId:**
- Todos os outros 10 handlers

Isso nao e um bug (sao repositorios com ambos metodos), mas a inconsistencia sugere que alguns commands recebem `patientId` (ID interno) e outros recebem `personId` (ID externo). A API HTTP deveria padronizar.

**Correcao:**
- [ ] Documentar qual tipo de ID cada endpoint espera
- [ ] Considerar padronizar na camada HTTP (Phase 3)

### S2. Numero de step duplicado
**Arquivo:** `Registry/AddFamilyMember/Services/AddFamilyMemberCommandHandler.swift`
**Linhas:** 28, 33

Steps numerados como: `// 1.`, `// 2.`, `// 3.` (Localizacao), `// 3.` (Unicidade), `// 4.`, `// 5.`, `// 6.`
O step 3 aparece duas vezes.

**Correcao:**
- [x] Steps renumerados de 1 a 7

### S3. PatientRegistrationRequest usa types do Command diretamente
**Arquivo:** `Query/PatientRegistration/PatientRegistrationRequest.swift:27-32`

O request referencia diretamente `RegisterPatientCommand.DiagnosisDraft`, `RegisterPatientCommand.PersonalDataDraft`, etc. Isso cria acoplamento entre o orchestrator e o command especifico.

**Correcao:**
- [ ] Considerar types proprios no Request (baixa prioridade, funciona como esta)

---

## ARQUIVOS A ALTERAR

### Application (Sources)
- `Protection/UpdatePlacementHistory/Services/UpdatePlacementHistoryCommandHandler.swift` — C1
- `Protection/UpdatePlacementHistory/Error/UpdatePlacementHistoryError.swift` — C1 (remover case se necessario)
- `Registry/AddFamilyMember/Services/AddFamilyMemberCommandHandler.swift` — C2, S2
- `Query/PatientQueries/GetPatientByIdQueryHandler.swift` — C3
- `Query/PatientQueries/GetPatientByPersonIdQueryHandler.swift` — C3
- `Query/PatientRegistration/PatientRegistrationError.swift` — C4, M3

### Nota sobre M1 e M2
- M1 (orquestracao incompleta) e M2 (DTOs rasos) sao achados de **design incompleto**, nao bugs. Podem ser resolvidos junto com Phase 3 (Vapor HTTP). Registrados aqui para rastreamento.

---

## BONUS: Correcoes extras encontradas durante as fixes
- Doc comment em `PatientInterventions.swift` ainda referenciava nomes antigos em PT (`incompatibleAfastamentoSituation`) — corrigido
- `AddFamilyMemberCommandHandler` usava `try FamilyMember(...)` mas init nao lanca mais (S4 do Domain review) — removido `try`

---

## ARQUIVOS ALTERADOS

### Application (Sources)
- `Protection/UpdatePlacementHistory/Services/UpdatePlacementHistoryCommandHandler.swift` — C1
- `Protection/UpdatePlacementHistory/Error/UpdatePlacementHistoryMapperError.swift` — C1 (mapper PatientError)
- `Registry/AddFamilyMember/Command/AddFamilyMemberCommand.swift` — C2 (novo campo prRelationshipId)
- `Registry/AddFamilyMember/Services/AddFamilyMemberCommandHandler.swift` — C2, S2 (mock removido, steps renumerados, try removido)
- `Query/PatientQueries/GetPatientByIdQueryHandler.swift` — C3 (Sendable + AppErrorConvertible)
- `Query/PatientQueries/GetPatientByPersonIdQueryHandler.swift` — C3 (Sendable + AppErrorConvertible)
- `Query/PatientRegistration/PatientRegistrationError.swift` — C4 (Equatable), M3 (memberId no context)

### Domain (Sources)
- `Registry/Aggregates/Patient/PatientInterventions.swift` — doc comment corrigido

---

## STATUS
- **Inicio:** 2026-03-06
- **Conclusao:** 2026-03-07
- **Build:** PASSANDO (swift build)
- **Testes:** 58 testes em 20 suites — PASSANDO
