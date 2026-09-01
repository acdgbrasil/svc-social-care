# svc-social-care

Microservico de cuidado social da **ACDG Brasil** (Associacao Brasileira de Profissionais Atuantes em Doencas Geneticas). Gerencia prontuarios sociais de pacientes com doencas geneticas raras.

## Stack

- **Linguagem:** Swift 6.3 (Strict Concurrency)
- **Framework HTTP:** Vapor 4
- **Database:** PostgreSQL 15 (via SQLKit + PostgresKit)
- **Build:** Swift Package Manager (SwiftPM)
- **Container:** Docker (Linux amd64)
- **Registry:** `ghcr.io/acdgbrasil/svc-social-care`

## Arquitetura

Clean Architecture + DDD com CQRS e Transactional Outbox.

```
Sources/social-care-s/
  Domain/         Agregados, entidades, value objects (11 so no Kernel)
  Application/    25 command handlers + read-side em Query/
  IO/
    HTTP/         6 controllers, 35 rotas (Vapor)
    Persistence/  SQLKit repository, migrations, mapper
  shared/         AppError, DomainEventRegistry, protocolos
```

### Camada HTTP

| Controller | Rotas |
|---|---|
| **HealthController** | `GET /health`, `GET /ready` |
| **PatientController** | `GET /patients` (listagem paginada), `POST /patients`, `GET /patients/:id`, `GET /patients/by-person/:personId`, `POST /:id/family-members`, `DELETE /:id/family-members/:memberId`, `PUT /:id/primary-caregiver`, `PUT /:id/social-identity`, `GET /:id/audit-trail` |
| **AssessmentController** | `PUT` housing-condition, socioeconomic-situation, work-and-income, educational-status, health-status, community-support-network, social-health-summary |
| **ProtectionController** | `PUT` placement-history, `POST` violation-reports, `POST` referrals |
| **CareController** | `POST` appointments, `PUT` intake-info |
| **LookupController** | `GET /dominios/:tableName`, lookup-requests (create/list/approve/reject), admin (create/update item) |

### Funcionalidades transversais

- **StandardResponse\<T\>** com `meta.timestamp` em todos os endpoints
- **actorId** derivado do `sub` do JWT em toda mutation (ADR-023) — nao existe header de identidade
- **Audit trail** com before/after diff e filtro por eventType
- **Validacao metadata-driven** (flags em lookup tables)
- **Validacoes cruzadas** (sexo/gestante, idade/acolhimento)
- **Calculos automaticos no GET** (densidade habitacional, indicadores financeiros, perfil etario, vulnerabilidades educacionais)

## Desenvolvimento local

### Requisitos

- Swift 6.3+ (via Swiftly — le o `.swift-version`)
- PostgreSQL 15+ (ou Docker)
- jq (para coverage report)

### Opcao 1: PostgreSQL via Docker Compose

```bash
# Subir apenas o banco
docker compose up postgres -d

# Rodar o app nativamente
make run dev
```

### Opcao 2: Stack completa via Docker Compose

```bash
docker compose up --build
```

### Opcao 3: Tudo nativo

```bash
cp .env.example .env    # ajustar se necessario
make deps
make run dev
```

## Make (atalhos)

```bash
make help             # Lista comandos
make run dev          # Rodar servico localmente
make run test         # Executar testes
make run coverage     # Testes + piso local de 25%
make ci               # Pipeline local (deps + build-release + coverage)
make clean            # Limpar artefatos
```

## Docker

```bash
# Build local
docker build -t svc-social-care:local .

# Execucao
docker run --rm -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PASSWORD=postgres \
  svc-social-care:local
```

## CI/CD

### CI (Pull Requests + Push to main)

Workflow: `.github/workflows/ci.yml`

1. `swift package resolve`
2. `swift build -c release`
3. `./scripts/check_coverage.sh report` — roda a suite com instrumentacao de
   cobertura e publica a leitura por camada no resumo do job. Reprova por teste
   vermelho; o percentual e termometro, nao gate.

### Release (Push to main + Tags)

Workflow: `.github/workflows/release-ghcr.yml`

1. Build da imagem Docker
2. Push para `ghcr.io/acdgbrasil/svc-social-care`
3. Tags: `sha-<commit>`, `vX.Y.Z`, `latest` (apenas main)

Em producao, consumir por digest imutavel: `@sha256:...`

## Deploy (Edge Cloud)

O servico roda na **ACDG Edge Cloud** (K3s + FluxCD + Tailscale):

```
Usuario -> Caddy (VPS/SSL) -> Tailnet -> K3s (Xeon) -> Pod social-care
```

- **Orquestrador:** K3s com FluxCD (GitOps pull-based)
- **Banco:** PostgreSQL StatefulSet no Xeon (SSD 1TB)
- **Segredos:** Bitwarden Secrets Manager (operador K8s)
- **Health probes:** `/health` (liveness) e `/ready` (readiness com check de DB)
- **SSL:** Caddy na VPS gateway
- **CORS:** primeira camada no Caddy; o servico tem politica propria, desligada
  por default (ADR-045). Ligar so quando um front-end web chamar direto.
- **Rate limit:** ligado por default no servico (ADR-046). Atras do Caddy sem
  `TRUST_PROXY`, o IP visto e o do proxy e o balde e compartilhado — o boot
  avisa no log.

## Variaveis de ambiente

| Variavel | Default | Descricao |
|---|---|---|
| `PORT` | `3000` | Porta do servidor HTTP |
| `DB_HOST` | `localhost` | Host do PostgreSQL |
| `DB_PORT` | `5432` | Porta do PostgreSQL |
| `DB_USER` | `postgres` | Usuario do banco |
| `DB_PASSWORD` | `postgres` | Senha do banco |
| `DB_NAME` | `social_care` | Nome do banco |
| `CORS_ALLOWED_ORIGINS` | — (desligado) | CSV de origens permitidas. Sem ela, o servico nao emite header de CORS. `*` e recusado em producao (ADR-045) |
| `RATE_LIMIT_ENABLED` | `true` | `false`/`0`/`no`/`off` desliga o teto de requisicoes (ADR-046) |
| `RATE_LIMIT_REQUESTS` | `300` | Creditos por janela, por cliente |
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | Tamanho da janela |
| `TRUST_PROXY` | `false` | Deriva o IP do cliente de `X-Forwarded-For`/`X-Real-IP`. **So ligue com um proxy que reescreve esses headers** — senao o limite vira opcional para quem ataca |

Secrets aceitam o sufixo `_FILE` (`DB_PASSWORD_FILE`), que tem precedencia sobre
a variavel. As de OIDC (`OIDC_JWKS_URLS`, `OIDC_ISSUERS`, `OIDC_AUDIENCES`)
estao documentadas no `.env.example` e nos ADR-027/029/031.

## Qualidade

- **550 testes** em **94 suites**, verdes.
- Cobertura e **termometro, nao gate** — leitura de 2026-09-01: **34,97% global**.
  Por camada: `shared` 76,6%, `Domain` 58,6%, `Application` 47,6%, **`IO` 18,4%**.
  A camada IO tem 7.510 linhas (metade do codigo-fonte) e segue sendo a menor
  cobertura, mas o pipeline HTTP passou a ser exercitado ponta a ponta: 31 testes
  em `Tests/social-care-sTests/IO/HTTP/`.
- Piso local de 25% como anti-regressao: `./scripts/check_coverage.sh 25`.
- Leitura por camada, sem gate: `./scripts/check_coverage.sh report`.

## Seguranca

- Segredos via Bitwarden Secrets Manager (nunca hardcoded)
- Vulnerabilidades: reportar via `SECURITY.md` da organizacao
