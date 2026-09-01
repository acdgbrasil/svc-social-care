#!/usr/bin/env bash
# Hook PreToolUse (Bash) — bloqueia force push de verdade.
#
# A regra `deny: Bash(git push --force:*)` do settings.json so casa quando a
# flag vem logo depois do subcomando: `git push origin main --force` escapa,
# porque regra de permissao casa texto, nao semantica de shell. Hook que sai
# com 2 e avaliado antes das regras e nao tem esse buraco.
#
# `--force-with-lease` passa: e a forma segura, que recusa sobrescrever
# trabalho que voce ainda nao viu.
set -uo pipefail

CMD="$(cat | jq -r '.tool_input.command // empty')"
[[ -z "$CMD" ]] && exit 0

# Percorre cada subcomando (a permissao do Claude Code separa por &&, ||, ;, |).
while IFS= read -r part; do
  [[ "$part" =~ (^|[[:space:]])git([[:space:]]|$) ]] || continue
  [[ "$part" =~ (^|[[:space:]])push([[:space:]]|$) ]] || continue

  # --force-with-lease / --force-if-includes sao aceitos.
  SAFE="$(printf '%s' "$part" | sed -E 's/--force-with-lease(=[^ ]*)?//g; s/--force-if-includes//g')"

  if [[ "$SAFE" =~ (^|[[:space:]])(--force|-f)([[:space:]]|=|$) ]]; then
    {
      echo "Force push bloqueado: $part"
      echo
      echo "Reescrever historico publicado apaga trabalho de quem ja puxou o branch."
      echo "Se a intencao e mesmo sobrescrever, use --force-with-lease (recusa quando"
      echo "ha commit remoto que voce nao viu) e confirme com o Gabriel antes."
    } >&2
    exit 2
  fi
done < <(printf '%s\n' "$CMD" | tr ';|&' '\n')

exit 0
