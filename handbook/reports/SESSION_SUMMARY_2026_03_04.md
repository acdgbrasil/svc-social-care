# Relatório de Sessão: Evolução para social-care v2.0
**Data:** 04 de Março de 2026
**Status:** Compilando e Validado (TDD)

## 🎯 Objetivo da Sessão
Migrar o microserviço de um cadastro estático para um núcleo de inteligência social **Metadata-Driven**, centralizando todos os cálculos analíticos e regras de negócio no **Domínio**, conforme os novos requisitos dos formulários de triagem.

---

## 🏗️ 1. Arquitetura e Infraestrutura
- **Nova Versão Arquitetural:** Atualização do `architecture/README.md` estabelecendo a soberania do Domínio sobre cálculos (Densidade, Renda, Vulnerabilidades).
- **Composition Root:** Criação do `ApplicationContext.swift` (análogo ao AppDelegate) para gerenciar o ciclo de vida de dependências (EventLoop, Postgres Pool, Repositories e Services).
- **Web Framework:** Integração completa com **Hummingbird 2.0**.
- **Concorrência:** Refatoração do `DomainEventRegistry` para `actor`, garantindo thread-safety idiomático no hardware dedicado.

## 🧠 2. Inteligência de Domínio (Core)
- **Infraestrutura de Lookup:** Implementação de `LookupId` e `LookupValidating` para suportar tabelas de domínio dinâmicas (`dominio_*`), desacoplando o código de mudanças na legislação/regras.
- **Analytics Services (Domain):**
    - `FinancialAnalyticsService`: Cálculos de RTF_S, RPC_S, RTG e RPC_G.
    - `HousingAnalyticsService`: Cálculo de densidade (membros/dormitório) e superlotação.
    - `EducationAnalyticsService`: Identificação de evasão e analfabetismo por faixa etária.
    - `FamilyAnalytics`: Projeção de perfil etário completo da família.
- **Novos Módulos Implementados:**
    - `WorkAndIncome`: Gestão detalhada de rendas individuais e benefícios.
    - `EducationalStatus`: Escolaridade e condicionalidades.
    - `HealthStatus`: Deficiências (Lookup), gestação e segurança alimentar.
    - `AcolhimentoHistory`: Histórico de afastamento familiar com validação de datas.
    - `IngressInfo`: Fluxo de entrada inicial e motivos de atendimento.

## 🛡️ 3. Qualidade e TDD
- **Bateria de Testes v2.0:** Criação de testes de especificação em `Tests/Domain/v2/`.
- **Regras de Ouro Validadas:**
    - **PR Única:** Garantia de exatamente uma Pessoa de Referência por família.
    - **Ciclo de Vida:** Impedimento de registro de internação/guarda se a idade dos membros for incompatível.
- **Refinamento Swift:** Aplicação das diretrizes do `reviewr.md` (Naming, Fluência, Static Dispatch e Documentação Markdown).

## 🌐 4. Camada de API (I/O)
- **Controllers Consolidados:** `PatientIntake`, `Registry`, `Assessment`, `Protection` e `Care`.
- **DTOs & Mappers:** Contratos JSON alinhados com o payload unificado exigido pelo frontend.
- **Persistência:** Atualização do `PatientDatabaseMapper` e migrações SQLKit para suportar as novas colunas (`birth_date`, `social_identity`, etc).

---

## 📈 Status do Plano de Evolução
| Fase | Descrição | Progresso |
| :--- | :--- | :--- |
| **Fase 1** | Kernel & Infra de Lookup | 100% ✅ |
| **Fase 2** | Registry & Identidade | 100% ✅ |
| **Fase 3** | Assessment (Analytics) | 100% ✅ |
| **Fase 4** | Protection & Ingress | 100% ✅ |
| **Fase 5** | Refinamento & Qualidade | 95% 🟡 |

## 🚀 Próximos Passos Sugeridos
1. **Migrações de Dados:** Criar as migrações SQL para popular as tabelas `dominio_*` (Parentesco, Tipos de Deficiência, etc).
2. **Integração de DB:** Implementar os testes de integração reais para validar o `save/find` com as novas tabelas de Lookup.
3. **Frontend Sync:** Validar os novos DTOs com a equipe de frontend.

---
**Nota:** O projeto está em estado estável ("Green") e com todas as novas funcionalidades de domínio cobertas por testes.
