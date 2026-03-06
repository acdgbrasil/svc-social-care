# Migracoes SQL: Tabelas de Dominio (Lookup)

**Data de Inicio:** 05 de Marco de 2026
**Status:** Etapas 1-2 concluidas

---

## Objetivo

Criar todas as tabelas `dominio_*` referenciadas pelos Value Objects do Domain,
popular com seed data do SUAS brasileiro e implementar o adapter real de `LookupValidating`.

---

## Mapa de Tabelas Criadas (8 tabelas, 77 registros)

| Tabela | Referenciada por | Campo no VO | Registros |
| :--- | :--- | :--- | :--- |
| `dominio_parentesco` | `FamilyMember` | `relationshipId` | 12 |
| `dominio_tipo_identidade` | `SocialIdentity` | `tipoId` | 11 |
| `dominio_condicao_ocupacao` | `WorkIncomeVO` | `occupationId` | 12 |
| `dominio_escolaridade` | `MemberEducationalProfile` | `educationLevelId` | 13 |
| `dominio_efeito_condicionalidade` | `ProgramOccurrence` | `effectId` | 5 |
| `dominio_tipo_deficiencia` | `MemberDeficiency` | `deficiencyTypeId` | 11 |
| `dominio_tipo_ingresso` | `IngressInfo` | `ingressTypeId` | 9 |
| `dominio_programa_social` | `ProgramLink` | `programId` | 14 |

---

## Tabelas Adicionais Identificadas (front_end_forms — ainda nao criadas)

| Tabela | Referenciada por (formulario) | Prioridade |
| :--- | :--- | :--- |
| `dominio_tipo_violacao` | Violencia e Violacao de Direitos | Alta |
| `dominio_tipo_medida` | Medidas Socioeducativas | Alta |
| `dominio_tipo_beneficio` | Beneficios Eventuais (metadata-driven: `exige_certidao`, `exige_cpf_falecido`) | Alta |
| `dominio_servico_vinculo` | Fortalecimento de Vinculos | Media |
| `dominio_unidade_realizacao` | Fortalecimento de Vinculos | Media |
| `dominio_especificidade_familiar` | Cadastro Pessoa Referencia (Parte 3) | Media |

---

## Checklist de Execucao

### Etapa 1: Migracao SQL (Schema + Seed Data) — CONCLUIDA
- [x] Criar arquivo `2026_03_05_CreateLookupTables.swift`
- [x] Definir schema generico: `id UUID PK`, `codigo TEXT UNIQUE NOT NULL`, `descricao TEXT NOT NULL`, `ativo BOOLEAN DEFAULT true`
- [x] Inserir seed data para todas as 8 tabelas
- [x] Registrar migracao no `ApplicationContext.swift`

### Etapa 2: Adapter + Injecao nos Use Cases — CONCLUIDA
- [x] Criar `SQLKitLookupRepository.swift` implementando `LookupValidating`
- [x] Injetar no `ApplicationContext.swift`
- [x] Injetar `LookupValidating` nos 3 Use Cases de Registry:
  - [x] `RegisterPatientService` (valida `prRelationshipId` + `socialIdentity.tipoId`)
  - [x] `AddFamilyMemberService` (valida `relationshipId`)
  - [x] `UpdateSocialIdentityService` (valida `tipoId`)
- [x] Adicionar `invalidLookupId(table:id:)` nos 3 error enums
- [x] Atualizar testes com mock de `LookupValidating`

### Etapa 3: Testes de Integracao
- [ ] Criar testes para `SQLKitLookupRepository`
- [ ] Validar exists() retorna true para IDs validos
- [ ] Validar exists() retorna false para IDs inexistentes

### Etapa 4: Endpoint GET /dominios
- [ ] Criar controller para expor dados de lookup ao frontend

---

## Mapa de Use Cases: Existentes vs Necessarios

### JA IMPLEMENTADOS (9 Use Cases + 1 Query Orchestrator)
| Use Case | Modulo | Lookup Validado? |
| :--- | :--- | :--- |
| `RegisterPatientService` | Registry | SIM (parentesco + identidade) |
| `AddFamilyMemberService` | Registry | SIM (parentesco) |
| `RemoveFamilyMemberService` | Registry | N/A |
| `UpdateSocialIdentityService` | Registry | SIM (identidade) |
| `AssignPrimaryCaregiverService` | Registry | N/A |
| `UpdateHousingConditionService` | Assessment | N/A (enums fixos) |
| `UpdateSocioEconomicSituationService` | Assessment | N/A |
| `CreateReferralService` | Protection | N/A |
| `ReportRightsViolationService` | Protection | N/A |
| `RegisterAppointmentService` | Care | N/A |
| `PatientRegistrationService` | Query | N/A (orquestra os acima) |

### FALTAM IMPLEMENTAR (extraidos dos 12 formularios)
| Use Case Necessario | Formulario | Tabelas de Lookup | Complexidade |
| :--- | :--- | :--- | :--- |
| UpdateWorkAndIncome | Rendimento | `dominio_condicao_ocupacao` | Media (calculos RTF/RPC) |
| UpdateEducationalStatus | Educacao Familiar | `dominio_escolaridade`, `dominio_efeito_condicionalidade` | Media (vuln. educacionais) |
| UpdateHealthStatus | Saude | `dominio_tipo_deficiencia` | Media (validacao gestantes por sexo) |
| RegisterIngressInfo | Ingresso Inicial | `dominio_tipo_ingresso`, `dominio_programa_social` | Baixa |
| RegisterBenefitGrant | Beneficios Eventuais | `dominio_tipo_beneficio` (metadata-driven) | Alta (validacao dinamica) |
| RegisterServiceParticipation | Fortalecimento Vinculos | `dominio_servico_vinculo`, `dominio_unidade_realizacao` | Media |
| RegisterViolationSituation | Violencia | `dominio_tipo_violacao` (metadata-driven) | Media |
| RegisterSocioeducativeMeasure | Medidas Socioeducativas | `dominio_tipo_medida` | Media (validacao cronologica) |
| RegisterAcolhimento | Acolhimento | Nenhuma (validacao cruzada ciclo de vida) | Alta |
| GetUnifiedProfile (Query) | Prontuario Unificado | Todas | Alta (agrega tudo) |

---

## Log de Progresso

### [2026-03-05] Sessao 1
- Explorado todo o codebase: identificadas 8 tabelas de lookup necessarias
- Criado este arquivo de tracking
- Criado `2026_03_05_CreateLookupTables.swift` com schema + seed data para 8 tabelas (77 registros)
- Criado `SQLKitLookupRepository.swift` (adapter real de `LookupValidating`)
- Registrado migracao e lookup validator no `ApplicationContext.swift`
- Renomeado BFF -> Query Orchestrator (pasta, variaveis, docs, testes)
- Injetado `LookupValidating` em RegisterPatient, AddFamilyMember e UpdateSocialIdentity
- Adicionado `invalidLookupId(table:id:)` nos 3 error enums com AppError mapeado (HTTP 422)
- Mapeados todos os 12 formularios: identificados 10 Use Cases faltantes + 6 tabelas de lookup adicionais
- Build: OK | Testes: 45/45 passaram (22 suites)
