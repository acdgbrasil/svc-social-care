# ADR-043: Aposentadoria do `handbook/` — ADR, rule e skill no lugar

**Data:** 2026-09-01
**Status:** Aceito
**Supersedes:** a regra "Handbook como Source of Truth" do `CLAUDE.md` (2026-05-14)

## Contexto

O `CLAUDE.md` declarava, desde 2026-05-14, que o `handbook/` era a **fonte
canônica** de arquitetura e decisões, acima do próprio `CLAUDE.md`. Medido em
2026-09-01, o diretório tinha **75.304 linhas em 266 arquivos (11 MB)**. A
distribuição mostra o problema:

| Bloco | Linhas | O que era |
|---|---:|---|
| `tooling/swift/` | 55.296 | Espelho de doc externa: referência da linguagem Swift, API Design Guidelines da Apple e doc do Vapor. `VAPOR/` tinha **143 arquivos para 25 páginas** — a mesma página em ~6 idiomas (`.zh`, `.it`, `.es`, `.nl`…) |
| `reports/` | 5.648 | `SESSION_*.md` e reviews datados |
| `architecture/DECISIONS/` | 6.944 | 32 ADRs + template |
| `tooling/suas/` | 4.557 | Manual do Prontuário SUAS (MDS) e do fluxo socioeducativo |
| `front_end_forms/` | 861 | Forma dos payloads de formulário |
| `IMPLEMENTATION_PLAN.md` | 657 | Fases fechadas + gaps G1–G17 |
| `architecture/*.md` | 821 | README v2.0, índice de ADRs, backlog |
| `Agents/`, `features/` | 520 | Prompts do harness antigo; uma spec de feature |

Três defeitos concretos, todos verificados contra o código:

1. **73% do volume era documentação de terceiros**, que nem responde pelas
   convenções deste projeto e envelhece sem aviso. Ela contradizia uma regra que
   o próprio `CLAUDE.md` já escrevia: *"para fato de biblioteca, leia a fonte;
   não há atalho interno"*.
2. **O conteúdo com valor real ficava invisível por associação.** Os manuais do
   SUAS — a norma que este serviço implementa — estavam em
   `handbook/tooling/suas/`, ao lado do espelho do Vapor. Ninguém abria.
3. **O documento canônico mentia.** `architecture/README.md` (v2.0) descrevia a
   rota `GET /patients/unified-profile/{id}` e um "Prontuário Unificado":
   **zero ocorrências em `Sources/`**. `DOMAIN_EVOLUTION_PLAN.md` citava
   `AcolhimentoHistory`, tipo que se chama `PlacementHistory`. Um documento
   declarado acima do `CLAUDE.md` na hierarquia de conflito descrevia rota
   inexistente.

O mecanismo do harness também mudou desde então: `.claude/rules/` com `paths:`
carrega instrução **só** quando se toca o código correspondente, e uma skill
carrega sob demanda. Em 2026-05-14 a única forma de dar contexto era um
diretório que alguém precisava lembrar de abrir.

## Decisão

Removemos o `handbook/`. Cada conteúdo com valor foi para o mecanismo que
corresponde à sua natureza:

| Origem | Destino | Por quê |
|---|---|---|
| `architecture/DECISIONS/` (32 ADRs + template) | `docs/adr/` | Decisão versionada é registro de primeira classe, não anexo de handbook |
| `architecture/DECISIONS.md` | `docs/adr/README.md` | Índice, junto do que indexa |
| `architecture/IMPROVEMENT_BACKLOG.md` | `docs/adr/BACKLOG.md` | É o funil de ADR; fica ao lado deles |
| `tooling/suas/` (2 manuais) | skill `social-care-suas` + `references/` | Norma do domínio: carrega quando a conversa é de domínio, custa zero quando não é |
| `front_end_forms/` (12) | `references/` da skill `social-care-io` | Consulta de quem mexe em DTO |
| `features/PATIENT_LIFECYCLE.md` | `references/` da skill `social-care-application` | Consulta de quem mexe no ciclo de vida |
| Parte viva de `architecture/README.md` | `.claude/rules/domain-analytics.md` (`paths: Domain/**`) | Regra que vale sempre naquele path |
| Gaps abertos do `IMPLEMENTATION_PLAN.md` | `docs/GAPS.md` | 657 linhas viraram o que ainda está aberto |
| `tooling/swift/`, `reports/`, `Agents/`, `DOMAIN_EVOLUTION_PLAN.md` | removidos | Doc externa, histórico que o git guarda, e planos 100% concluídos |

Saldo: **63.422 linhas deletadas**, 50 arquivos movidos com `git mv` (histórico
preservado).

Os **ADRs não foram deletados** e essa foi a única parte do pedido original que
recebeu contestação. Medição que sustentou a decisão: existem **353 referências
a `ADR-NNN` fora do handbook** — 202 em `Sources/`, 95 em `Tests/`, 41 no
harness, 11 no `CLAUDE.md`, 4 em `scripts/`. O `CLAUDE.md` manda procurar
âncoras como `// ADR-023:` no código. Deletar converteria 353 ponteiros em
referências órfãs. O que estava inchado era a estrutura, não as decisões.

A hierarquia de conflito passa a ser:

```
o código  >  docs/adr/  >  .claude/rules/ e skills  >  CLAUDE.md
```

O código no topo é a mudança de fundo: nenhum documento volta a ser declarado
acima dele.

## Alternativas consideradas

**Podar o handbook no lugar de removê-lo.** Rejeitada. A estrutura era o
problema: o `tooling/` misturava norma do SUAS com espelho do Vapor, e o
`README.md` v2.0 acumulava princípio válido, plano de fases concluído e rota
inexistente no mesmo arquivo. Podar preservaria a mistura que produziu a
invisibilidade.

**Manter o handbook e adicionar rules.** Rejeitada: duas fontes para a mesma
regra divergem, e a hierarquia teria que arbitrar entre elas a cada conflito.

**Deletar também os ADRs, limpando as âncoras do código.** Rejeitada: 202
comentários de `Sources/` perderiam o referente, e o motivo de cada decisão
sobreviveria só no histórico do git — exatamente o que um ADR existe para
evitar.

## Consequências

**Ganhos.** O contexto que chega ao modelo passou a ser proporcional à tarefa:
`.claude/rules/domain-analytics.md` só carrega ao tocar `Domain/`,
`testing.md` só ao tocar `Tests/`, e a skill do SUAS só quando a conversa é de
domínio. O `CLAUDE.md` caiu de **260 para 156 linhas** (a doc oficial recomenda
menos de 200; acima disso a adesão cai). E a norma do SUAS ficou alcançável pela
primeira vez, com o mapeamento dos 16 blocos para os tipos do código.

**Perdas aceitas.** Quem procurar a doc do Vapor offline não a encontra mais no
repo — deve ler a fonte oficial, que é a regra do projeto desde antes. O
histórico de sessões saiu do working tree e vive no git.

**Dívida exposta pela migração**, registrada em `docs/GAPS.md`: `ADR-030` e
`ADR-034` são citados pelo código e **não existem** como arquivo; `ADR-001` e
`ADR-003` não são citados por ninguém fora do registro.

## Plano de adoção

Concluído em 2026-09-01, no mesmo commit: mover, destilar, deletar, corrigir
todas as referências (`CLAUDE.md`, agentes, skills, `scripts/check_harness.sh`,
`Tests/`) e validar com `./scripts/check_harness.sh` e `swift test`.

## Como reverter

`git revert` do commit restaura os 266 arquivos: nada foi deletado fora do
controle de versão, e os 50 movimentos foram `git mv`. Reverter significa
retomar as 63 mil linhas e a hierarquia que colocava um documento acima do
código — só faz sentido se a premissa de que doc externa espelhada envelhece
calada for refutada.

## Teste de regressão

Mecanismo em `scripts/check_harness.sh`, que já roda no CI (ADR-042) e agora
cobre o novo layout:

- **Checagem 1** reprova qualquer caminho citado no harness que não exista — é
  o que pega uma referência a `handbook/` deixada para trás.
- **Checagem 4** varre a documentação viva atrás de padrão abandonado; a lista
  de exclusão passou a ser `docs/adr/ADR-*`, `docs/adr/BACKLOG.md` e os
  `references/` das skills (norma de terceiro não responde pelas convenções
  daqui).

Verificado após a migração: 14 checagens sem divergência, suite em 504 testes
verdes.

## Better Pattern para skills

A regra que este ADR entrega para o harness, e que vale para o próximo
documento que alguém pensar em criar:

> **Documento não é lugar de conhecimento — mecanismo é.** Antes de escrever
> um `.md` novo, pergunte o que ele é:
>
> - Decisão com trade-off → **ADR** em `docs/adr/`.
> - Regra que vale sempre num path → **rule** em `.claude/rules/` com `paths:`.
> - Procedimento ou domínio consultado às vezes → **skill**.
> - Norma ou doc de terceiro → **`references/` de uma skill**, nunca copiada
>   para dentro de outro texto.
> - Invariante que precisa valer mesmo se ninguém ler → **hook**.
>
> Se não é nenhum desses, provavelmente é histórico — e o git já guarda.

E o critério que decidiu o que sobreviveu: **guarda-se o que não é
reconstituível pelo código**. Contagem, nome de tipo, estrutura de pasta e fato
de biblioteca vêm do `grep` ou da fonte oficial; norma, decisão e armadilha que
custou descoberta são o que merece um arquivo.
