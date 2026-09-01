---
paths:
  - "Sources/social-care-s/Domain/**"
  - "Tests/social-care-sTests/Domain/**"
---

# Domínio — onde o cálculo mora

Destilado do antigo `handbook/architecture/README.md` (v2.0), mantendo só o que
o código confirma. O que foi descartado está no fim, para não voltar por engano.

## Inteligência no domínio

**Se envolve fórmula, contagem ou classificação, o código vai em `Domain/`.**
Query handler não calcula — ele pede ao serviço de domínio e monta a resposta.
É o que mantém o cálculo testável sem banco e sem HTTP, e o que impede a mesma
regra de existir em duas versões divergentes (uma no handler, outra na tela).

Os quatro serviços que existem hoje:

| Cálculo | Serviço |
|---|---|
| Densidade habitacional (membros/dormitórios) | `Domain/Assessment/Analytics/Services/HousingAnalyticsService.swift` |
| Renda total e per capita | `Domain/Assessment/Analytics/Services/FinancialAnalyticsService.swift` |
| Vulnerabilidade educacional (evasão, analfabetismo por idade) | `Domain/Assessment/Analytics/Services/EducationAnalyticsService.swift` |
| Perfil etário da família | `Domain/Registry/Analytics/FamilyAnalytics.swift` |

Cálculo novo entra num destes ou num serviço novo ao lado — nunca dentro do
command handler.

## Lookup primeiro (metadata-driven)

**Nunca use `String` solta onde cabe um id de tabela de domínio.** As regras de
preenchimento mudam por norma (o SUAS revisa formulário), e a tabela permite
mudar sem recompilar. A validação vem de `LookupValidating`
(`Domain/Kernel/LookupValidating.swift`), não de `enum` estático.

Há **14** tabelas `dominio_*` no código — confira antes de criar mais uma:

```bash
grep -rho 'dominio_[a-z_]*' Sources/ | sort -u
```

Algumas carregam metadado que muda validação (ex: benefício que exige CPF ou
certidão). Quem valida isso é `MetadataValidator`, em `IO/HTTP/Validation/`.

## CRU, sem delete

Histórico social não se apaga: inativa-se por flag. A exceção única é a
anonimização de PII por LGPD (ADR-039). Isso vale para o modelo de domínio e
para a migration — `DELETE` de dado de prontuário é achado de revisão.

## O significado dos campos não se inventa

Campo de avaliação existe porque o **Prontuário SUAS** o define. Antes de criar,
renomear ou tornar obrigatório um campo, veja o bloco correspondente na skill
`social-care-suas`. O código deriva da norma, não o contrário.

## Descartado do documento antigo (não repor)

- **`GET /patients/unified-profile/{id}` e o "Prontuário Unificado"**: promessa
  de 2026-03 que nunca foi implementada — zero ocorrências em `Sources/`. Se um
  dia virar requisito, entra por ADR.
- **`AcolhimentoHistory`**: o tipo se chama `PlacementHistory`
  (`Domain/Protection/Entities/`).
- **Plano de fases 5–8**: as fases fecharam; o que resta aberto são os gaps em
  `docs/GAPS.md`.
