---
name: revisar
description: Revisa o diff atual contra as invariantes do social-care, em subagente isolado, e devolve só os achados.
argument-hint: "[branch, PR ou caminho — opcional]"
disable-model-invocation: true
context: fork
agent: social-care-reviewer
background: false
---

Revise as mudanças do repositório contra as invariantes do `social-care`.

Alvo: `$ARGUMENTS` — se veio vazio, revise o diff de trabalho (`git diff` mais
`git status --porcelain`); se veio um branch, compare com `main`
(`git diff main...<branch>`); se veio um número de PR, use `gh pr diff`.

Siga o checklist das 12 invariantes do seu prompt de agente, nessa ordem. Para
cada achado, dê `arquivo:linha`, a invariante violada e o cenário concreto em
que quebra — sem cenário não é achado. Ao final, diga o que você verificou e
estava correto, para o leitor saber o alcance da revisão.

Nada a reportar é resposta legítima.
