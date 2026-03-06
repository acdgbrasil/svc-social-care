# Plano de Evolução do Domínio — social-care (v2.0)

> Este arquivo serve para rastrear o progresso da refatoração do Domínio seguindo os novos requisitos de Inteligência Centralizada e Metadata-Driven.

## 🟢 Fase 1: Kernel & Infraestrutura de Lookup
- [x] Criar testes de especificação (TDD)
- [x] Criar `LookupId` em `Domain/Kernel/`
- [x] Criar protocolo `LookupValidating` em `Domain/Kernel/`
- [x] Atualizar `TimeStamp` para fornecer utilitários de cálculo de idade

## 🔵 Fase 2: Registry & Identidade (Refatoração)
- [x] Criar testes de especificação (TDD)
- [x] Refatorar `SocialIdentity` para modelo de ID Único + Descrição
- [x] Refatorar `FamilyMember` para usar `relationshipId`
- [x] Implementar regra de "Pessoa de Referência Única" no `Patient`
- [x] Implementar `FamilyAggregate.calculateAgeProfile()` (Projeção de Domínio)

## 🟡 Fase 3: Assessment Context (Novos Módulos)
- [x] Criar testes de especificação (TDD)
- [x] Criar `WorkAndIncome` (Trabalho e Rendimento)
- [x] Criar `EducationalStatus` (Condições Educacionais)
- [x] Criar `HealthStatus` (Saúde e Deficiências)
- [x] Implementar `FinancialAnalyticsService` (Cálculos de Renda)
- [x] Implementar `HousingAnalyticsService` (Cálculos de Densidade)
- [x] Implementar `EducationAnalyticsService` (Cálculos de Vulnerabilidade)

## 🔴 Fase 4: Protection & Ingress
- [x] Criar testes de especificação (TDD)
- [x] Criar `AcolhimentoHistory` (Acolhimento e Afastamento)
- [x] Criar `IngressInfo` (Forma de Ingresso e Atendimento Inicial)
- [x] Implementar validações cruzadas de ciclo de vida (ex: menores de idade para internação)

---

## 📈 Progresso Geral
- **Registry:** 100%
- **Assessment:** 100%
- **Protection:** 100%
- **Analytics:** 100%

## 🧹 Refinamento & Qualidade (Pós-Review)
- [x] Corrigir typos em `EducationalStatus` e `WorkAndIncome`
- [x] Normalizar nomenclatura de Analytics Services (Fluência Swift)
- [x] Auditoria Global: Aplicar API Design Guidelines em TODO o Domain/
- [x] Auditoria Global: Garantir documentação Markdown em TODAS as APIs públicas
- [x] Auditoria Global: Otimizar performance (Static Dispatch & Access Control)
