# ADR-042: Harness verificável — o `.claude/` afirma só o que um comando comprova

**Data:** 2026-09-01
**Status:** Proposto
**Supersedes:** —

> **Promoção → Aceito (ADR-003):** fica `Proposto` até `scripts/check_harness.sh`
> existir e rodar no CI — ver "Teste de regressão".

## Contexto

O harness anterior (`.claude/`) tinha **19.104 linhas em 80 arquivos**: 9 skills
e 1 agent, para um serviço de ~14 mil linhas de código-fonte. Auditado em
2026-08-31, ensinava padrões que o código havia abandonado:

- injetar `eventBus: any EventBus` no construtor do handler — porta removida
  pelo **ADR-014**, e já coberta pelo teste de regressão S-C4;
- a role `social_worker`, que nunca existiu no código (`RoleGuardMiddleware`
  sempre usou `worker`, `owner`, `admin`, `superadmin`);
- gate de cobertura de 95% que o CI nunca rodou (ADR-041);
- Swift 6.2, quando `.swift-version` fixa 6.3.3.

O `settings.json` registrava um marketplace em `../infra/reference-network` —
diretório inexistente — e o `CLAUDE.md` dedicava uma seção a mandar delegar
para agentes `acdg-ref:*` indisponíveis neste repositório. Cerca de 15 mil das
19 mil linhas eram cópias de documentação de linguagem, com triplicatas (três
arquivos sobre migrar de XCTest) e conteúdo alheio a um backend Vapor headless
(Core Data, ARC, workflows do Xcode).

A causa não foi desleixo pontual: **nada verificava as afirmações do harness**.
Documentação que ninguém mede envelhece em silêncio, e um guia que ensina o
padrão errado é pior que a ausência de guia — o leitor não sabe que precisa
desconfiar.

## Decisão

Reconstruímos o harness do zero sob duas regras, e criamos o mecanismo que as
faz valer:

1. **Skill não repete o handbook.** Aponta para o ADR ou para o arquivo-âncora.
   Conteúdo duplicado é conteúdo que vai divergir.
2. **Toda contagem vem acompanhada do comando que a remede.** Número sem comando
   envelhece calado.

`scripts/check_harness.sh` verifica, a cada CI, o que é verificável: caminhos
citados existem, termos proibidos não voltaram, contagens batem com o código.

## Alternativas consideradas

- **Podar e deduplicar o harness existente.** Descartada: preservaria a
  superfície de drift, e boa parte do material era documentação de linguagem que
  o modelo já conhece — o que ele não conhece são as convenções deste projeto.
- **Reconstruir a "reference network"** (`infra/reference-network` com doc
  oficial offline e agentes `ref-*`). Descartada por ora: é infraestrutura
  própria, fora do escopo deste serviço, para resolver um problema que não
  temos evidência de ter.
- **Confiar apenas na convenção** ("mantenha atualizado"). Descartada: é
  exatamente o que já falhou. Convenção sem mecanismo é a hipótese que este ADR
  refuta.
- **Reescrever as referências órfãs nos ADRs históricos.** Descartada: ADR é
  registro datado; reescrever histórico apaga o contexto de quando a decisão foi
  tomada. Resolvido com tabela de equivalência em `DECISIONS.md`.

## Consequências

**Positivas.** 19.104 → ~950 linhas, sem perder nada que era específico do
projeto. Cada skill carrega uma seção do que a documentação antiga afirmava e é
falso, o que protege quem leu a versão velha. As invariantes que só existiam
como texto viraram hooks: suite de regressão no `Stop`, fronteira do domínio no
`PostToolUse`, force push no `PreToolUse`.

**Negativas / custos.** As referências de linguagem (concurrency, swift-testing,
API design) deixaram de existir localmente; para fato de biblioteca a fonte
passa a ser `Package.resolved`, o header do módulo ou a doc oficial. A
reconstrução também **órfãou 70 referências** em 32 arquivos do handbook — quase
todo ADR aponta, na seção "Better Pattern", para uma skill que não existe mais.

**Ações requeridas.** Feitas em `d9c617e`, `86ae9eb`, `603d0fe`, `ba23d42`. Falta
o `check_harness.sh` (este ADR) e a tabela de equivalência no `DECISIONS.md`.

## Plano de adoção

1. ✅ Remoção do harness antigo e das regras `.kody/` órfãs.
2. ✅ 1 agent de roteamento + 4 skills de camada + 2 skills de workflow
   (`/novo-usecase`, `/revisar`) + agent revisor read-only.
3. ✅ Hooks de enforcement e `permissions` com `deny`/`ask`.
4. ✅ Plugin `acdg` (`tooling/acdg-plugin/`) para o que serve a qualquer serviço
   da organização — hoje o LSP de Swift e o guard de git.
5. ⏳ `scripts/check_harness.sh` no CI.
6. ⏳ Tabela de equivalência skill antiga → nova em `DECISIONS.md`.

## Como reverter

`git revert` dos quatro commits citados restaura o harness anterior — que está
íntegro no histórico, e é o argumento para não tê-lo arquivado em pasta morta.

## Teste de regressão

`scripts/check_harness.sh`, executado no CI junto dos testes. Verifica:

1. **Caminhos citados existem** — todo caminho de arquivo/diretório entre crases
   nos arquivos de `.claude/` aponta para algo real no repositório.
2. **Termos proibidos não voltaram** — `social_worker` (role inexistente),
   `X-Actor-Id` (contrato removido pelo ADR-023), `infra/reference-network` e
   `acdg-ref` (caminho morto), promessa de gate de 95% no CI (ADR-041).
3. **Contagens batem** — os números afirmados no harness (use cases, controllers,
   migrations, testes) conferem com o que o código responde; divergência falha
   com a contagem correta na mensagem, para que corrigir seja trivial.

O item 2 complementa, no nível de documentação, o que o teste S-C4
(`Regression/EventPublication/`) já garante no nível de código.

## Better Pattern para skills

1. **Skill atualizada:** todas as quatro de camada
   (`.claude/skills/social-care-{domain,application,io,tests}/SKILL.md`) já
   trazem a seção "Armadilhas / o que a documentação antiga afirmava e é falso",
   e o agent `.claude/agents/social-care.md` abre com a tabela de fatos medidos e
   seus comandos.
2. **Handbook:** `CLAUDE.md`, seção "Harness (`.claude/`)".
3. **Regra resumida:** skill não repete o handbook — aponta para o ADR ou o
   arquivo-âncora; e toda contagem vem com o comando que a remede. Afirmação que
   nenhum comando comprova não entra no harness.

## Referências

- ADR-014 — remoção do `EventBus` (padrão que o harness antigo ainda ensinava).
- ADR-023 — `actorId` via `JWT.sub`, que aposentou o `X-Actor-Id`.
- ADR-041 — cobertura como termômetro, cuja promessa falsa o harness repetia.
- `tooling/acdg-plugin/README.md` — regra de corte entre plugin e projeto.
