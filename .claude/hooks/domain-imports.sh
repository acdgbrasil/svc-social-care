#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write) — a fronteira do domínio, verificada de verdade.
#
# `Domain/` só pode importar Foundation. Era a melhor das regras do Kodus, que
# só rodava no PR e dependia de um serviço externo; aqui roda no ato da edição,
# local e de graça.
#
#   exit 0 → nada a dizer
#   exit 2 → erro devolvido ao Claude para corrigir antes de seguir
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

FILE="$(cat | jq -r '.tool_input.file_path // empty')"
[[ -z "$FILE" ]] && exit 0

# Normaliza para caminho relativo ao projeto.
REL="${FILE#"$PWD/"}"

case "$REL" in
  Sources/social-care-s/Domain/*.swift) ;;
  *) exit 0 ;;
esac

[[ -f "$REL" ]] || exit 0

OFFENDERS="$(grep -nE '^\s*import ' "$REL" | grep -vE '^\s*[0-9]+:\s*import Foundation\s*$' || true)"

[[ -z "$OFFENDERS" ]] && exit 0

{
  echo "Fronteira do domínio violada em $REL:"
  printf '%s\n' "$OFFENDERS"
  echo
  echo "Domain/ importa apenas Foundation — sem Vapor, SQLKit, JWT, NIO ou tipos de"
  echo "Application/ e IO/. Se a regra precisa mesmo cair, isso é um ADR, não um import."
} >&2

exit 2
