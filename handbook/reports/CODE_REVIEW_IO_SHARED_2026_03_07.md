# Code Review — IO (Infrastructure) + shared (2026-03-07)

## Veredicto: BOM — achados pontuais a corrigir

A camada IO segue corretamente a arquitetura descrita no README:
- SQLKit Adapters para persistencia relacional
- Transactional Outbox para relay de eventos
- Lookup Repository para tabelas de dominio (Metadata-Driven)
- Separacao clara entre modelos de banco e dominio via Mapper

---

## CRITICOS

### C1. Force unwrap em massa — crash em dados corrompidos
**Arquivos:**
- `Persistence/SQLKit/SQLKitPatientRepository.swift:61,88,113`
- `Persistence/SQLKit/Mappers/PatientDatabaseMapper.swift:17,21,50,62,65,74,77,78,87,91`

14 ocorrencias de `UUID(uuidString: ...)!` que causam crash se o banco retornar um UUID mal-formado. Alem disso, 4 ocorrencias de `rawValue)!` para enums no mapper (linhas 140, 153, 155, 166).

Dados de producao podem ter inconsistencias por migracoes manuais ou bugs anteriores. Um force unwrap transforma isso em crash do servico inteiro.

**Correcao:**
- [ ] Substituir `UUID(uuidString:)!` por `guard let` com erro descritivo
- [ ] Substituir `(rawValue:)!` por `guard let` com erro descritivo
- [ ] Criar erro dedicado `DatabaseMappingError` para falhas de conversao

### C2. Coluna com nome em portugues — `acolhimento_history`
**Arquivo:** `Persistence/SQLKit/Models/PatientDatabaseModels.swift:42`
**Arquivo:** `Persistence/SQLKit/Migrations/2026_03_06_AddV2AssessmentFields.swift:14,24`

A coluna `acolhimento_history` no banco esta em portugues enquanto TODAS as outras colunas estao em ingles (`placement_history`, `work_and_income`, etc.). O `CodingKey` mapeia `placement_history` -> `"acolhimento_history"` silenciosamente.

Viola a regra "Ingles para todos os simbolos" e gera confusao — desenvolvedores veem `placement_history` no Swift mas `acolhimento_history` no SQL.

**Correcao:**
- [ ] Criar nova migration renomeando a coluna: `ALTER TABLE patients RENAME COLUMN acolhimento_history TO placement_history`
- [ ] Atualizar o CodingKey para `case placement_history` (sem valor custom)

### C3. Faltam access modifiers — Repository e Mapper sao `internal`
**Arquivos:**
- `Persistence/SQLKit/SQLKitPatientRepository.swift:5` — `struct SQLKitPatientRepository` (sem `public`)
- `Persistence/SQLKit/SQLKitLookupRepository.swift:8` — `struct SQLKitLookupRepository` (sem `public`)
- `Persistence/SQLKit/Mappers/PatientDatabaseMapper.swift:4` — `struct PatientDatabaseMapper` (sem `public`)
- `Persistence/SQLKit/Models/PatientDatabaseModels.swift` — todos os models (sem `public`)

Dentro do mesmo module Swift isso funciona, mas se futuramente os targets forem separados (o que e pratica comum em Clean Architecture), nada compila.

Mais importante: viola o padrao de PoP onde implementacoes concretas devem ser `public` para serem injetaveis na composicao de dependencias. O `social_care_s.main()` precisa instanciar `SQLKitPatientRepository` — e hoje so consegue por estar no mesmo target.

**Correcao:**
- [ ] Adicionar `public` ao `SQLKitPatientRepository` e seu `init`
- [ ] Adicionar `public` ao `SQLKitLookupRepository` e seu `init`
- [ ] Manter `PatientDatabaseMapper` e models como `internal` (detalhe de implementacao)

---

## MODERADOS

### M1. Codigo duplicado nos metodos `find(byPersonId:)` e `find(byId:)`
**Arquivo:** `Persistence/SQLKit/SQLKitPatientRepository.swift:60-110`

Os dois metodos sao quase identicos — a unica diferenca e a clausula WHERE (`person_id` vs `id`). As 5 queries de listas filhas sao identicas.

**Correcao:**
- [ ] Extrair metodo privado `fetchAggregate(patientId: UUID)` que carrega listas filhas
- [ ] `find(byPersonId:)` e `find(byId:)` apenas buscam o `PatientModel` e delegam ao metodo compartilhado

### M2. DomainEventError — Faltam conformances
**Arquivo:** `shared/Domain/DomainEventRegistry.swift:30-32`

```swift
public enum DomainEventError: Error {
    case unregisteredEventType(String)
}
```

Faltam `Sendable`, `Equatable` e `AppErrorConvertible`. Inconsistente com todos os outros erros do projeto.

**Correcao:**
- [ ] Adicionar `Sendable, Equatable, AppErrorConvertible`

### M3. `DomainEventRegistryBootstrap` — extension no shared a partir do IO
**Arquivo:** `IO/Persistence/SQLKit/Outbox/DomainEventRegistryBootstrap.swift`

A extension `DomainEventRegistry.bootstrap()` registra eventos concretos do Domain (ex: `PatientCreatedEvent`). Isso esta correto como composicao no IO, mas `bootstrap()` cria um metodo `public` no actor singleton que qualquer camada pode chamar sem saber se ja foi chamado.

**Correcao:**
- [ ] Considerar guard contra re-registro (idempotencia) ou tornar o metodo chamavel apenas uma vez

### M4. `ensureMetaTableExists` engole erros silenciosamente
**Arquivo:** `Persistence/SQLKit/Migrations/SQLKitMigrationRunner.swift:43-51`

```swift
private func ensureMetaTableExists() async throws {
    do {
        try await db.create(table: "migrations_meta")...
    } catch {
        // Se falhar porque a tabela ja existe, ignoramos.
    }
}
```

Engolir QUALQUER erro (nao so "table already exists") pode esconder falhas de conexao, permissao, disco cheio, etc.

**Correcao:**
- [ ] Usar `CREATE TABLE IF NOT EXISTS` em vez de try/catch generico
- [ ] Ou verificar o tipo especifico do erro antes de ignorar

### M5. `print()` para logging — nao usa Logger
**Arquivos:**
- `SQLKitMigrationRunner.swift:30,37` — `print("... Applying migration...")`
- `SQLKitOutboxRelay.swift:58` — `print("... Outbox Relay Error...")`
- `SQLKitOutboxRelay.swift:97` — `print("... Failed to decode...")`

O entry point `social_care_s.swift` importa `Logging` mas o IO usa `print()`. Em producao, `print()` nao vai para logs estruturados e nao tem nivel de severidade.

**Correcao:**
- [ ] Injetar `Logger` nos componentes ou usar `Logger(label:)` interno
- [ ] Substituir `print(...)` por `logger.info(...)` / `logger.error(...)`

---

## MENORES

### S1. `FamilyMember` reconstitution usa `try` desnecessario
**Arquivo:** `Persistence/SQLKit/Mappers/PatientDatabaseMapper.swift:123`

```swift
return try FamilyMember(...)
```

Apos a correcao S4 do Domain review, `FamilyMember.init` nao lanca mais. O `try` e desnecessario (compila como warning).

**Correcao:**
- [ ] Remover `try` de `FamilyMember(...)` na reconstituicao

### S2. `OutboxEventBus.publish()` e no-op
**Arquivo:** `IO/EventBus/OutboxEventBus.swift:13-18`

O metodo `publish` nao faz nada (eventos ja foram salvos pelo repository). E um metodo vazio que existe para satisfazer o protocolo `EventBus`.

Nao e um bug — a arquitetura Transactional Outbox funciona assim. Mas poderia sinalizar o relay para poll imediata ao inves de esperar o intervalo.

**Correcao:**
- [ ] Considerar injetar referencia ao `SQLKitOutboxRelay` para `triggerPoll()` (melhoria futura, nao urgente)

### S3. `PatientRepository` definido no Domain
**Arquivo:** `Domain/Registry/Repository/PatientRepository.swift`

O protocolo do repositorio esta no Domain, o que e correto para Clean Architecture (Dependency Inversion). Apenas anotando como ponto positivo.

---

## SHARED — ACHADOS

### shared/Error/AppError.swift — Ja revisado (Domain review)
Sem achados novos.

### shared/Domain/DomainProtocols.swift — Bem estruturado
- `CommandHandling<C>: Actor` — correto
- `QueryHandling<Q>: Sendable` (struct) — correto
- `EventSourcedAggregate` com default implementation via PoP — correto
- Unico ponto de atencao: `EventSourcedAggregateInternal.addEvent` e `public` mas e detalhe interno (ja documentado no Domain review S1)

### shared/Domain/DomainEventRegistry.swift — Ver M2

---

## PONTOS POSITIVOS

1. **Transactional Outbox correto** — eventos persistidos na mesma transacao que o agregado
2. **Mapper separado** — `PatientDatabaseMapper` isola conversao domain<->db
3. **Migration system robusto** — com metadados, prevencao de duplicatas, transacoes por migration
4. **Lookup tables com seed data** — 8 tabelas de dominio com dados iniciais
5. **Performance indexes** — unique index em person_id, partial index no outbox, indexes de busca
6. **Delete-and-Insert pattern** — correto para listas filhas de agregados (diagnoses, family, etc.)
7. **Bulk update no outbox** — marca lote inteiro como processado em uma query

---

## STATUS
- **Inicio:** 2026-03-07
- **Conclusao:** pendente (somente report por enquanto)
- **Build:** PASSANDO
- **Testes:** 58 testes em 20 suites — PASSANDO
