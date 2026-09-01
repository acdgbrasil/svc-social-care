---
name: release
description: Fecha uma release do social-care — calcula o bump SemVer a partir dos commits, atualiza o CHANGELOG e cria a tag anotada. Use ao publicar uma versão.
argument-hint: "[major|minor|patch — opcional, sobrescreve o cálculo]"
disable-model-invocation: true
---

# Release

A convenção deste projeto — tag SemVer obrigatória para todo `feat:`/`fix:` em
`main` — depende de alguém lembrar, e já falhou de forma documentada: o
`CHANGELOG` parou em **0.7.0** enquanto as tags seguiram até **v0.16.0**, e foi
reconstruído à mão em 2026-08-31, versão por versão, conferindo cada entrada
contra o código. Esta skill existe para que não haja segunda vez.

## 1. Onde estamos

```bash
git tag --sort=-v:refname | head -3            # última tag
git log $(git tag --sort=-v:refname | head -1)..HEAD --oneline --no-merges
git status --porcelain                          # precisa estar limpo
```

Se a árvore não estiver limpa, pare: release de working tree suja não é
reproduzível.

## 2. Calcular o bump

Classifique **cada** commit desde a última tag pelo prefixo:

| Prefixo | Efeito |
|---|---|
| `feat:` | **minor** (0.16.0 → 0.17.0) |
| `fix:` | **patch** (0.16.0 → 0.16.1) |
| `!` no tipo, ou `BREAKING CHANGE:` no corpo | **major** (0.16.0 → 1.0.0) |
| `chore:`, `docs:`, `refactor:`, `test:`, `ci:`, `style:` | nenhum |

O maior efeito presente vence. **Se só houver commits sem efeito, não há
release** — diga isso e pare; tag vazia polui o histórico e engana quem lê o
CHANGELOG depois. `$ARGUMENTS`, se vier, sobrescreve o cálculo, mas confira em
voz alta se o que ele pede bate com os commits.

## 3. Verificar antes de publicar

```bash
./scripts/check_harness.sh   # documentação bate com o código
make test                    # suite verde
make coverage                # piso local
```

Tag é imutável na prática — o `edge-cloud-infra` referencia `vX.Y.Z` nos
manifests, e `git tag -f` está no `deny` do `settings.json` justamente por isso.
Verifique antes, não depois.

## 4. CHANGELOG

Nova seção no topo, abaixo de `## [Unreleased]`, no formato do arquivo:

```markdown
## [X.Y.Z] - AAAA-MM-DD

### Adicionado
- **Título curto (ADR-NNN quando houver)** — o que mudou e, principalmente,
  **o que era antes**. Entrada que não diz o estado anterior não ajuda quem
  investiga um bug daqui a seis meses.

### Corrigido
### Alterado
### Complementar
```

Use só as seções que tiverem conteúdo. Escreva a partir do **diff**, não da
mensagem de commit: onde as duas divergirem, vale o código — foi a regra da
reconstrução histórica e continua valendo.

## 5. Tag e push

```bash
git add CHANGELOG.md && git commit -m "docs(changelog): vX.Y.Z"
git tag -a vX.Y.Z -m "<tipo>(<escopo>): <resumo da entrega>"
git push origin main --tags
```

A mensagem da tag segue Conventional Commits, como as existentes
(`git for-each-ref refs/tags/v0.16.0 --format='%(subject)'` mostra o padrão).
O push dispara `release-ghcr.yml`, que publica a imagem em
`ghcr.io/acdgbrasil/svc-social-care` com as tags `sha-<commit>`, `vX.Y.Z` e
`latest`. Em produção, consuma por digest imutável.

## 6. Fechar o ciclo

Se a release fecha um gap rastreado em `docs/GAPS.md`, atualize o arquivo. Se um
ADR saiu de `Proposto` com esta entrega, promova-o em `docs/adr/`.

## O que não fazer

- Não crie tag sem entrada correspondente no CHANGELOG — foi assim que 10
  versões ficaram sem registro.
- Não use `git tag -f` para "corrigir" uma tag publicada: outra versão
  referenciada por digest já pode estar em produção. Erro em tag publicada se
  conserta com a próxima versão.
- Não anuncie a release antes de o workflow terminar verde.
