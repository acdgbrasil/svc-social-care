# svc-social-care

Servico base da organizacao ACDG para dominio de social care.

## Stack
- Runtime: Bun
- Linguagem: TypeScript
- Container: Docker + GHCR

## Repositorio
- GitHub: `https://github.com/acdgbrasil/svc-social-care`

## Estrutura minima
- `src/`: codigo fonte
- `tests/`: testes automatizados
- `handbook/`: documentacao operacional
- `.github/workflows/`: CI e release de imagem

## Desenvolvimento local
```bash
bun install
bun run dev
```

## Qualidade
```bash
bun run typecheck
bun test
```

## Release
- Imagem: `ghcr.io/acdg/svc-social-care`
- Tags: `sha-<commit>`, `vX.Y.Z`, `latest` (somente `main`)
- Producao deve consumir por digest: `@sha256:...`

## Versoes suportadas
- `main`: suporte ativo

## Seguranca
- Vulnerabilidades devem ser reportadas pelo canal definido em `SECURITY.md` da organizacao.
