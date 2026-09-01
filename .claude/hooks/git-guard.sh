#!/usr/bin/env bash
# Hook PreToolUse (Bash) — bloqueia force push.
#
# Regra de permissão casa texto, não semântica de shell: `deny` com prefixo
# deixa passar `git push origin main --force`. Hook que sai com 2 é avaliado
# antes das regras e não tem esse buraco.
#
# A primeira versão deste arquivo prometia "force push em qualquer posição" e
# tinha cinco escapes — refspec `+`, aspas, flags curtas agrupadas, continuação
# de linha e `jq` ausente. Daí a normalização abaixo, e a bateria em
# `test-hooks.sh`: um guard que falha aberto é pior que nenhum, porque quem
# confia nele para de conferir.
#
# `--force-with-lease` e `--force-if-includes` passam: recusam sobrescrever
# commit que você ainda não viu.
set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "git-guard: jq ausente — não dá para inspecionar o comando, então nada passa." >&2
  exit 2
fi

CMD="$(jq -r '.tool_input.command // empty')"
[[ -z "$CMD" ]] && exit 0

# Normaliza antes de decidir:
#   1. continuação de linha (`\` + newline) vira espaço — senão o `--force` da
#      linha seguinte fica num "part" sem o `git push`;
#   2. aspas somem — `git push "--force"` não pode escapar do casamento;
#   3. `=` vira espaço para separar `--force=x` em token próprio.
# awk, não sed: o BSD sed do macOS descarta o pattern space no `N` quando não
# há próxima linha, e o CI roda Linux — a diferença zerava a normalização.
NORM="$(printf '%s\n' "$CMD" \
  | awk '{ if (sub(/\\[[:space:]]*$/, "")) printf "%s ", $0; else print }' \
  | tr -d "\"'" \
  | tr '=' ' ')"

is_force_push() { # recebe um subcomando; 0 = é force push
  local part="$1" tok
  # precisa ser um `git ... push`
  [[ " $part " == *" git "* ]] || return 1
  [[ " $part " == *" push "* ]] || return 1

  # as formas seguras saem da análise antes de qualquer teste
  part="$(printf '%s' "$part" \
    | sed -E 's/--force-with-lease[^ ]*//g; s/--force-if-includes//g')"

  for tok in $part; do
    case "$tok" in
      --force) return 0 ;;                    # --force, --force=x (o `=` virou espaço)
      -*f*)                                   # -f, e agrupadas como -fu, -uf
        [[ "$tok" =~ ^-[a-zA-Z]+$ ]] && return 0 ;;
      +*) return 0 ;;                         # refspec `+main`, `+HEAD:refs/heads/main`
    esac
  done
  return 1
}

while IFS= read -r part; do
  is_force_push " $part " || continue
  {
    echo "Force push bloqueado: $part"
    echo
    echo "Reescrever histórico publicado apaga trabalho de quem já puxou o branch."
    echo "Se a intenção é mesmo sobrescrever, use --force-with-lease (recusa quando"
    echo "há commit remoto que você não viu) e confirme com o Gabriel antes."
  } >&2
  exit 2
done < <(printf '%s\n' "$NORM" | tr ';|&' '\n')

exit 0
