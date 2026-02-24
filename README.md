# svc-social-care

Servico base da organizacao ACDG para dominio de social care.

## Stack
- Linguagem: Swift 6.2
- Build/Test: Swift Package Manager (SwiftPM)
- Plataforma alvo: Linux (containers Docker)
- Container registry: GHCR

## Repositorio
- GitHub: `https://github.com/acdgbrasil/svc-social-care`

## Status atual
- Dominio concluido (Aggregates, Entities, Value Objects e testes).
- Proximas etapas:
  - Camada de `Application`
  - Integracoes com database e servidores

## Estrutura
- `Sources/social-care-s/`: codigo fonte em Swift
- `Tests/social-care-sTests/`: testes automatizados
- `handbook/`: documentacao operacional
- `.github/workflows/`: CI e release/publish de imagem

## Desenvolvimento local
```bash
swift --version
swift package resolve
swift build
swift run social-care-s
```

## Qualidade
```bash
swift build -c release --product social-care-s
swift test
```

## Docker
Build da imagem local:

```bash
docker build -t svc-social-care:local .
```

Execucao local:

```bash
docker run --rm -p 3000:3000 svc-social-care:local
```

## Release
- Workflow: `.github/workflows/release-ghcr.yml`
- Imagem: `ghcr.io/acdgbrasil/svc-social-care`
- Tags: `sha-<commit>`, `vX.Y.Z`, `latest` (somente `main`)
- Producao deve consumir por digest: `@sha256:...`

## CI
- Workflow: `.github/workflows/ci.yml`
- Executa:
  - `swift package resolve`
  - `swift build -c release`
  - `swift test`
- Nao faz sync/pull de contracts neste momento.

## Versoes suportadas
- `main`: suporte ativo

## Seguranca
- Vulnerabilidades devem ser reportadas pelo canal definido em `SECURITY.md` da organizacao.
