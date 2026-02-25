# Changelog

Todas as mudancas relevantes deste servico serao registradas aqui.

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
