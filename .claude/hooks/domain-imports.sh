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

# Ancorado no proprio script: o hook nao pode depender do cwd de quem o chama.
cd "${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}" || exit 0

if ! command -v jq >/dev/null 2>&1; then
  echo "domain-imports: jq ausente — não dá para inspecionar a edição." >&2
  exit 2
fi

FILE="$(jq -r '.tool_input.file_path // empty')"
[[ -z "$FILE" ]] && exit 0

# Normaliza para caminho relativo ao projeto.
REL="${FILE#"$PWD/"}"

case "$REL" in
  Sources/social-care-s/Domain/*.swift) ;;
  *) exit 0 ;;
esac

[[ -f "$REL" ]] || exit 0

# Swift 6 aceita modificador antes do import: `public import`, `internal import`,
# `@preconcurrency import`, `@_exported import`. Todos contam.
IMPORT_RE='^[[:space:]]*(@[A-Za-z_]+[[:space:]]+|public[[:space:]]+|internal[[:space:]]+|package[[:space:]]+|private[[:space:]]+|fileprivate[[:space:]]+)*import[[:space:]]'
OFFENDERS="$(grep -nE "$IMPORT_RE" "$REL" | grep -vE '^[0-9]+:[[:space:]]*import Foundation[[:space:]]*$' || true)"

[[ -z "$OFFENDERS" ]] && exit 0

{
  echo "Fronteira do domínio violada em $REL:"
  printf '%s\n' "$OFFENDERS"
  echo
  echo "Domain/ importa apenas Foundation — sem Vapor, SQLKit, JWT, NIO ou tipos de"
  echo "Application/ e IO/. Se a regra precisa mesmo cair, isso é um ADR, não um import."
} >&2

exit 2
