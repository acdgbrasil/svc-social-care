# ADR-041: Cobertura de teste é termômetro, não gate

**Data:** 2026-09-01
**Status:** Proposto
**Supersedes:** —

> **Promoção → Aceito (ADR-003):** este ADR fica `Proposto` até o mecanismo de
> enforcement existir e rodar no CI — ver "Teste de regressão". A regra é do
> próprio projeto e vale para quem a escreveu.

## Contexto

Até 2026-08-31, seis documentos deste repositório afirmavam que a cobertura
mínima de 95% era "enforçada no CI" — `README.md`, `CLAUDE.md`,
`handbook/IMPLEMENTATION_PLAN.md` (que a dava como "gate verde"),
`docs/qa/00-plano-de-testes.md`, `handbook/Agents/implementor.md` e
`handbook/tooling/swift/testing/regression-pattern.md`.

Nada disso era verdade. O `ci.yml` executava `swift test` cru: sem
`--enable-code-coverage`, sem chamada ao `scripts/check_coverage.sh`. O gate
nunca rodou uma única vez.

A medição real, feita em 2026-08-31:

| Camada | Cobertas | Total | % |
|---|---:|---:|---:|
| `IO` | 652 | 7.132 | **9,14%** |
| `Application` | 1.943 | 4.086 | 47,55% |
| `Domain` | 1.625 | 2.775 | 58,56% |
| `shared` | 141 | 184 | 76,63% |
| **Global** | **4.361** | **14.196** | **30,72%** |

O dano da promessa falsa não foi a cobertura baixa em si — foi a **falsa
confiança** que ela sustentou. O `IMPLEMENTATION_PLAN.md` registrava "progresso
~99%" e classificava a ausência de testes de integração HTTP (G10) como "lacuna
arquitetural, não bloqueio de gate", justamente porque acreditava que 95%
estavam garantidos por outros caminhos. A camada com metade do código-fonte
estava a 9% e o documento dizia que estava tudo verde.

## Decisão

Abandonamos a meta numérica de cobertura no CI. Cobertura passa a ser
**termômetro**: o CI mede sempre e publica a leitura **por camada** no resumo do
job; quem reprova o CI é teste vermelho, nunca percentual.

O gate local de 30% (`make coverage`) permanece como piso anti-regressão, e o
número que importa passa a ser o da camada, não o global — um global de 30,72%
esconde `shared` a 76% e `IO` a 9%.

## Alternativas consideradas

- **Implementar o gate de 95% de verdade.** Descartada: exigiria ~10 mil linhas
  de teste antes de qualquer trabalho de produto, e um alvo tão alto convida ao
  teste de fachada — exercitar linha sem asserção real — que infla o número e
  não aumenta a confiança.
- **Gate no valor atual (30,72%), em modo catraca — nunca deixar cair.**
  Descartada **por ora**, não por princípio: é a alternativa mais defensável, e
  deve ser reavaliada quando `IO` tiver testes de integração (G10). Hoje ela
  reprovaria PRs legítimos que adicionam código na camada mais descoberta,
  criando incentivo a não mexer justamente onde mais falta teste. Além disso,
  uma catraca sobre o número global continua escondendo a distribuição.
- **Tirar cobertura do CI.** Descartada: perde o termômetro, que é o único dado
  que hoje aponta para onde o risco está concentrado.

## Consequências

**Positivas.** O CI passa a dizer a verdade. A leitura por camada é acionável —
foi ela que transformou "cobertura baixa" em "`IO` tem 9% de 7.132 linhas e
nenhum teste de integração HTTP", que é um plano de trabalho. Uma compilação
só: o passo de teste e o de cobertura viraram o mesmo.

**Negativas / custos.** Nada mecânico impede a cobertura de cair. A proteção
passa a ser social — revisão de PR olhando a tabela do resumo do job. Aceitamos
o custo por ora porque a alternativa mecânica (catraca) tem o efeito colateral
descrito acima.

**Ações requeridas.** Feitas em `2ce948d`: modo `report` no
`scripts/check_coverage.sh` com breakdown por camada, `ci.yml` chamando esse
modo, e correção dos seis documentos.

## Plano de adoção

1. ✅ `check_coverage.sh` ganha modo `report` (mede e publica, não reprova).
2. ✅ `ci.yml` roda `./scripts/check_coverage.sh report` no lugar de `swift test`.
3. ✅ Documentação corrigida onde afirmava 95%; `handbook/reports/` intocado por
   ser histórico.
4. ⏳ `scripts/check_harness.sh` barra o reaparecimento da promessa (ADR-042).
5. ⏳ Reavaliar a catraca quando G10 fechar.

## Como reverter

Trocar o argumento no `ci.yml` de `report` para um número
(`./scripts/check_coverage.sh 30`) restabelece o gate; o modo numérico nunca foi
removido do script.

## Teste de regressão

`scripts/check_harness.sh` — verificação estrutural que falha quando a
documentação viva volta a prometer gate de cobertura no CI (procura por
afirmações do tipo "95%" associadas a *enforçado/gate no CI* em `README.md`,
`CLAUDE.md`, `handbook/` fora de `reports/`, `docs/` e `.claude/`).

Complemento: o próprio `ci.yml` publica a medição a cada execução, então uma
regressão silenciosa da política — CI que para de medir — aparece pela ausência
da tabela no resumo do job.

Não há teste em Swift porque a decisão não muda comportamento de runtime: é
política de CI e de documentação, e o enforcement equivalente é o lint acima
(caso previsto no `ADR-TEMPLATE.md`).

## Better Pattern para skills

1. **Skill atualizada:** `.claude/skills/social-care-tests/SKILL.md` — seção
   "Cobertura" já carrega a regra e os números por camada.
2. **Handbook:** `handbook/IMPLEMENTATION_PLAN.md`, Fase 8, com a correção
   explícita da afirmação anterior.
3. **Regra resumida:** cobertura é termômetro, não gate — CI mede e publica por
   camada; reprova por teste vermelho, nunca por percentual. Persiga o caminho
   não exercitado, não o número.

## Referências

- Issue #35 — "[P3] CI: gate de cobertura documentado (95%) não existe no
  workflow; cobertura real é 30,72%".
- ADR-002 — política de testes de regressão (o suite que de fato protege).
- ADR-042 — harness verificável, que traz o mecanismo de enforcement citado acima.
- `handbook/IMPLEMENTATION_PLAN.md` — G10 (integração HTTP), a lacuna que a
  promessa de 95% mascarava.
