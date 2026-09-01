# Architecture Decision Records — social-care

Índice de ADRs (Architecture Decision Records) do microserviço. Cada decisão
estrutural tem um arquivo dedicado em `docs/adr/ADR-NNN-<slug>.md`.

> **Quando criar um ADR?** Qualquer decisão que: (a) afeta a forma de codar /
> testar / operar; (b) tem trade-offs que outra pessoa precisará entender no
> futuro; (c) seria difícil de reverter; (d) substitui ou contradiz uma
> decisão anterior. Bug fixes e features de produto não viram ADR — vão no
> commit e no PR.
>
> Para propostas **ainda não aceitas**, use [`BACKLOG.md`](BACKLOG.md).
> Quando uma proposta vira decisão fechada, promova para um ADR aqui.

## Índice

| # | Título | Status | Data | Supersedes |
|---:|---|:-:|---|---|
| [001](ADR-001-swift-6-3-upgrade.md) | Upgrade para Swift 6.3 | Aceito | 2026-05-14 | — |
| [002](ADR-002-regression-test-policy.md) | Política de testes de regressão | Aceito | 2026-05-14 | — |
| [003](ADR-003-adr-structure-enforces-test-and-pattern.md) | ADR carrega obrigatoriamente teste de regressão e Better Pattern | Aceito | 2026-05-14 | — |
| [004](ADR-004-event-sourced-aggregate-composite-protocol.md) | Eventos de domínio via protocolo composto sem cast dinâmico | Aceito | 2026-05-14 | — |
| [005](ADR-005-optimistic-locking-via-version.md) | Optimistic Locking via coluna `version` | Aceito | 2026-05-14 | — |
| [006](ADR-006-primary-keys-for-aggregate-tables.md) | Toda tabela é uma relação com PK declarada | Aceito | 2026-05-14 | — |
| [007](ADR-007-typed-foreign-keys-for-semantic-identity.md) | Colunas que carregam identidade semântica usam tipo nativo + FK | Aceito | 2026-05-14 | — |
| [008](ADR-008-foreign-keys-for-lookup-tables.md) | FK declarada para toda coluna *_id que aponta para lookup table | Aceito | 2026-05-14 | — |
| [009](ADR-009-money-vo-replaces-double.md) | Money VO substitui Double em todo valor monetário | Aceito | 2026-05-14 | — |
| [010](ADR-010-universal-persistence-conflict-mapping.md) | Mapeamento universal de PersistenceConflictError nos handlers | Aceito | 2026-05-14 | — |
| [011](ADR-011-people-context-fail-secure-and-bearer-forwarding.md) | PeopleContext fail-secure tri-state com Bearer forwarding | Aceito | 2026-05-14 | — |
| [012](ADR-012-security-headers-and-body-size-limit.md) | Security headers obrigatórios e body size limit no boot | Aceito | 2026-05-14 | — |
| [013](ADR-013-outbox-for-update-skip-locked.md) | Outbox at-least-once com FOR UPDATE SKIP LOCKED + Nats-Msg-Id | Aceito | 2026-05-14 | — |
| [014](ADR-014-outbox-events-via-repository.md) | Outbox Pattern — persistência atômica de eventos via Repository | Aceito | 2026-05-14 | — |
| [015](ADR-015-audit-trail-distinct-id-from-outbox.md) | `audit_trail.id` distinto de `outbox.id` + `outbox_message_id` para rastreio | Aceito | 2026-05-14 | — |
| [016](ADR-016-nats-publisher-bidirectional-handler.md) | `NATSEventPublisher` adota handler bidirecional NIO (PING/PONG real) | Aceito | 2026-05-14 | — |
| [017](ADR-017-log-sanitizer-no-pii-in-logs.md) | `LogSanitizer` é a porta única de log de erro em camadas com PII | Aceito | 2026-05-14 | — |
| [018](ADR-018-no-unchecked-sendable-on-boundary.md) | Banimento de `@unchecked Sendable` em estruturas de fronteira | Aceito | 2026-05-14 | — |
| [019](ADR-019-decomposition-of-patient-god-aggregate.md) | Decomposição estrutural do god aggregate `Patient` — plano de adoção da Fase 4 | Aceito | 2026-05-14 | — |
| [020](ADR-020-required-documents-1nf-and-try-map.md) | `required_documents` em tabela filha 1NF + `try map` em vez de `compactMap` | Aceito | 2026-05-14 | — |
| [021](ADR-021-deterministic-uuid-and-diff-based-upsert.md) | `DeterministicUUID` + diff-based upsert preservam identidade de entidades-filhas | Aceito | 2026-05-14 | — |
| [022](ADR-022-jsonb-and-temporal-types.md) | JSONB para payloads, TIMESTAMPTZ para operacionais, DATE para conceituais; `JSONCodec` padrão | Aceito | 2026-05-14 | — |
| [023](ADR-023-created-updated-at-on-root-tables.md) | Auditoria operacional via `created_at`/`updated_at` automáticos em tabelas raiz | Aceito | 2026-05-14 | — |
| [024](ADR-024-patient-assessment-aggregate-expand.md) | `PatientAssessment` aggregate — estágio EXPAND da decomposição da Fase 4 | Aceito | 2026-05-14 | — |
| [025](ADR-025-patient-assessment-dual-write.md) | `PatientAssessment` — estágio DUAL-WRITE da decomposição da Fase 4 | Aceito | 2026-05-14 | — |
| [027](ADR-027-oidc-multi-issuer.md) | OIDC multi-issuer (migração Zitadel → Authentik) | Aceito | 2026-07-04 | — |
| [029](ADR-029-oidc-role-precedence.md) | Precedência de roles multi-claim + property mapping `acdg-roles` | Aceito | 2026-07-04 | — |
| [031](ADR-031-oidc-defense-in-depth-and-acdg-claims.md) | Defense-in-depth no `verify` OIDC + claims ACDG (org_id/person_id/legacy_sub) | Aceito | 2026-07-04 | — |
| [034](ADR-034-injectable-clock.md) | Clock injetável em toda leitura de tempo que decide | Aceito | 2026-09-01 | — |
| [039](ADR-039-erasure-policy-people-person-deleted.md) | Política de erasure ao consumir `people.person.deleted` (LGPD × No-Delete) | Aceito | 2026-06-09 | — |
| [040](ADR-040-jwks-runtime-refresh.md) | Refresh de JWKS em runtime (periódico + on-demand por `kid`) | Aceito | 2026-07-04 | — |
| [041](ADR-041-coverage-as-thermometer.md) | Cobertura de teste é termômetro, não gate | Aceito | 2026-09-01 | — |
| [042](ADR-042-verifiable-harness.md) | Harness verificável — o `.claude/` afirma só o que um comando comprova | Aceito | 2026-09-01 | — |
| [043](ADR-043-retire-handbook.md) | Aposentadoria do `handbook/` — ADR, rule e skill no lugar | Aceito | 2026-09-01 | Supersedes a regra "Handbook como Source of Truth" |
| [044](ADR-044-request-correlation-and-access-log.md) | Correlação de requisição e log de acesso sem PII | Aceito | 2026-09-01 | — |
| [045](ADR-045-cors-allowlist.md) | CORS opt-in, por allowlist explícita | Aceito | 2026-09-01 | — |
| [046](ADR-046-rate-limiting.md) | Rate limiting por token bucket em memória do processo | Aceito | 2026-09-01 | — |

> **Faixa 026-038 (reconciliada em 2026-07-04):** originalmente **reservada** aos
> tickets T-025..T-038 do `REMEDIATION_PIPELINE_2026_05_14.md`. Na prática, a
> migração OIDC (PR #18) **materializou 027, 029 e 031** para o tema *multi-issuer
> OIDC* — código, testes, a skill `swift-io-implementer` e o
> `SENIOR_CODE_REVIEW_2026_05_14.md` já os referenciavam com esse sentido. Esses
> três IDs ficam com o significado **OIDC** (ver tabela acima); a atribuição
> original do pipeline para eles (naming EN / JWKS-refresh / LookupBatchValidator)
> está **superada** — nenhum desses temas foi implementado, e se algum for
> promovido receberá **ID ≥040** (regra "tema novo fora do pipeline usa ≥039",
> como fez a ADR-039).
>
> **034 saiu da reserva em 2026-09-01**: o código citava `ADR-034` em três
> lugares e o arquivo não existia (dívida em `docs/GAPS.md`). O tema do ticket
> T-034 era exatamente o que as âncoras diziam — clock injetável, achado
> S-H-A2 —, então o ID foi usado para o seu tema original, e não reciclado.
>
> **030 continua reservado, e agora sem âncora órfã.** O único código que o
> citava era o `StubUnitOfWork` do `RegressionFixture`: placeholder de uma
> decisão que nunca foi tomada, cujos dois testes exercitavam o próprio stub.
> Foi removido em 2026-09-01 — a atomicidade que ele prometia já é atendida pelo
> repositório, que grava agregado e eventos na mesma transação (ADR-014). A
> proposta de Unit of Work cross-repository, se voltar, está em
> `docs/adr/BACKLOG.md` #14.
>
> Ainda **reservados** (planejados no pipeline, ADR criado conforme o ticket
> fecha): **026, 028, 030, 032, 033, 035-038**. Observação: **T-028** (cursor
> pagination) já foi implementado em v0.7.0 sem ADR formal — dívida de
> documentação a fechar.
> Próximo ID livre fora da reserva: **047** (044-046 usados em 2026-09-01).

## Skills citadas em ADRs antigos — tabela de equivalência

O harness foi reconstruído em 2026-08-31 (**ADR-042**) e as skills mudaram de
nome. A seção "Better Pattern para skills" dos ADRs anteriores continua citando
os nomes antigos: **isso é proposital**. ADR é registro datado; reescrever o
corpo de decisões passadas apagaria o contexto de quando foram tomadas. Ao ler
um ADR antigo, traduza:

| Citado no ADR (removido) | Onde a lição vive hoje |
|---|---|
| `.claude/skills/swift-domain-modeler/` | `.claude/skills/social-care-domain/` |
| `.claude/skills/swift-application-orchestrator/` | `.claude/skills/social-care-application/` |
| `.claude/skills/swift-io-implementer/` | `.claude/skills/social-care-io/` |
| `.claude/skills/swift-test-writer/` | `.claude/skills/social-care-tests/` |
| `.claude/skills/swift-expert/` | a skill da camada correspondente |
| `.claude/agents/swift-orchestrator.md` | `.claude/agents/social-care.md` |
| `swift-concurrency`, `swift-testing`, `swift-api-design-guidelines`, `swift-format-style` | sem equivalente — eram cópias de documentação de linguagem; consulte a fonte oficial |

## Regra de promoção `Proposto` → `Aceito` (ADR-003)

Um ADR só pode ficar `Aceito` quando o arquivo contém, **preenchidas**, as duas seções:

- `## Teste de regressão` — identificador do teste (ou lint/snapshot) que enforça a decisão
- `## Better Pattern para skills` — qual skill em `.claude/skills/` carrega a lição aprendida

ADR sem essas seções fica `Proposto` até completar. Em code review, ADR "Aceito" incompleto é rebaixado para `Proposto` mecanicamente — não é negociável. Justificativa em [ADR-003](ADR-003-adr-structure-enforces-test-and-pattern.md).

Quando o ADR é puramente documental/governança (raro), citar **por que** teste/skill não é aplicável é aceito como conformidade — desde que justificado na própria seção.

---

## Status possíveis

- **Proposto** — em discussão, sem decisão fechada. Vive aqui como ADR draft.
- **Aceito** — decisão tomada e aplicável.
- **Superseded by ADR-NNN** — substituído por outro ADR. Manter o arquivo
  por histórico (não deletar).
- **Deprecado** — não vale mais, e não foi explicitamente substituído.
  Documentar por que perdeu relevância.
- **Rejeitado** — proposta avaliada e descartada. Manter por histórico
  para evitar re-discussão.

## Numeração

- IDs sequenciais (`ADR-001`, `ADR-002`, ...), nunca renumerar.
- Slug em kebab-case curto: `swift-6-3-upgrade`, `outbox-retry-policy`.
- Se uma proposta é rejeitada, ainda consome um ID — a justificativa
  documentada é tão valiosa quanto a decisão aceita.

## Hierarquia (em conflito)

```
O código (toda contagem e todo nome são reconstituíveis por um comando)
  > ADRs (docs/adr/ADR-NNN-*.md)
    > Rules (.claude/rules/*) e Skills (.claude/skills/*)
      > CLAUDE.md (índice operacional)
```

O `handbook/` que aparecia aqui foi aposentado em 2026-09-01 (ADR-043).

Em conflito, **ADR prevalece sobre skill** porque ADR é decisão estrutural
versionada com contexto; skill é guia operacional.

## Histórico documental

Antes de 2026-05-14, decisões estruturais do social-care viviam diluídas em
`CLAUDE.md`, `handbook/architecture/README.md` e nos commits. A partir de
ADR-001, toda decisão futura ganha arquivo dedicado. Decisões antigas
**não serão retroativamente convertidas em ADRs** salvo quando alguém precise
revisitar — nesse caso, cria-se o ADR com seção "Histórico documental"
reconstituindo.
