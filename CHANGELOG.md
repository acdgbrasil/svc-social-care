# Changelog

Todas as mudancas relevantes deste servico serao registradas aqui.

## [Unreleased]

### Adicionado
- Implementação da Fase 0.3: Remoção do caractere `+` de todos os nomes de arquivos, adotando o padrão CamelCase (ex: `PatientFamily.swift`).
- Refatoração do Read Model: Queries de leitura (`GetPatientById`, `GetPatientByPersonId`) convertidas para o protocolo `QueryHandling`.
- Conclusão da Fase 0.2: Todos os serviços de comando de `Application` migrados para `actor CommandHandler`, garantindo isolamento de estado e conformidade com CQRS.
- Protocolos de Use Case padronizados para herdar de `CommandHandling` ou `ResultCommandHandling` com `associatedtype`.
- Renomeação sistemática de `execute(command:)` para `handle(_:)` em toda a camada de aplicação para melhor fluência Swift.
- Infraestrutura CQRS estabelecida com novos protocolos base (`Command`, `Query`, `CommandHandling`) em `shared`.
- Implementação da Fase 0.1: Refatoração completa dos Value Objects do Kernel (`CPF`, `NIS`, `CEP`, `RGDocument`) para padrões de acrônimos uppercase e Inglês.
- Atualização de referências cruzadas em `Address`, `CivilDocuments`, `SocialIdentity`, `Patient` e todos os serviços de `Application`.
- Correção de tipagem em `PatientRepository` e `SQLKitPatientRepository` para usar `PatientId` em vez de `UUID`.
- Suítes de Teste (TDD) para refatoração do Kernel: `CPFTests`, `NISTests`, `CEPTests` e `RGDocumentTests`.
- Auditoria de Refinamento de Domínio e Application em `handbook/reports/DOMAIN_APPLICATION_REFINEMENT_AUDIT.md`.
- Extensão `SQLDatabase+Transaction` para suporte a transações atômicas nativas e via SQL bruto.
- Use Case `GetPatientByIdService` para leitura do prontuário completo.
- Use Case `GetPatientByPersonIdService` para integração via PersonId público.
- Use Case `RemoveFamilyMemberService` para remoção de membros da família.
- Rota `DELETE /patients/{id}/family-members/{memberId}` implementada (G3).
- Migration `2026_03_06_AddV2AssessmentFields` para suporte a campos v2.0 (Trabalho, Saúde, Educação).
- `GlobalErrorMiddleware` para padronização de respostas de erro em toda a API.
- Endpoints de Health Check (`/health` e `/ready`) para orquestração em Kubernetes.
- `StandardResponse<T>` wrapper para padronização de todas as respostas de sucesso (G8).

### Alterado
- Rotas HTTP migradas para o padrão Flat (`/patients/{id}/...`) em conformidade com as necessidades do front-end.
- DTOs e caminhos de API agora utilizam Inglês como idioma padrão.
- `SQLKitPatientRepository` agora utiliza transações SQL no método `save()` garantindo consistência Agregado-Outbox.
- `SQLKitMigrationRunner` agora é resiliente e utiliza transações por unidade de migração.
- `PatientDatabaseMapper` e `PatientModel` atualizados para persistência total do domínio v2.0.
- `PatientQueryDTO` e testes unitários corrigidos para refletir nomes de propriedades do domínio.
- `SQLKitOutboxRelay` otimizado com processamento em lote e marcação de processamento (G16).

## [0.4.0] - 2026-02-24
- Implementacao da camada de **Infrastructure** com **SQLKit** e **PostgresKit**.
- Implementacao do **Pattern Transactional Outbox** para garantia de entrega de eventos.
- Criacao do **SQLKitOutboxRelay** (Actor) para polling assíncrono e distribuicao via **AsyncStream**.
- Implementacao de **DomainEventRegistry** para decodificacao segura de eventos heterogêneos.
- Sistema de **Migrations** programático e idempotente para PostgreSQL.
- Refatoracao de eventos de domínio para suporte a `Codable`.

## [0.3.0] - 2026-02-24
- Migracao completa da camada de **Application** de TypeScript para Swift 6.
- Implementacao de 8 Casos de Uso com *Structured Concurrency* e *Typed Throws*.
- Refatoracao de Mappers de erro para um padrao centralizado (`mapError`).
- Suite de testes de aplicacao concluida com 100% de cobertura lógica nos serviços.
- Alcance do nível **Platinum (95.95%)** de confiabilidade global do projeto.
- Testes de cobertura adicionados para todos os Enums de erro e Value Objects (PatientId).

## [0.2.0] - 2026-02-24
- Migracao de CI de Bun para Swift/Linux com SwiftPM.
- Remocao de setup/login/sync de contracts no pipeline de CI.
- Atualizacao do workflow de release GHCR para imagem do servico Swift.
- Migracao do Dockerfile para build e runtime baseados em Swift.
- Atualizacao de `.dockerignore` e `.gitignore` para artefatos Swift.
- Dominio da aplicacao concluido (Aggregates, Entities, Value Objects e testes).
- Proximos passos: camada de Application e integracoes com database/servidores.

## [0.1.0] - 2026-02-22
- Baseline inicial de repositorio ACDG.
