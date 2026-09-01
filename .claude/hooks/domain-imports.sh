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

# Duas camadas, duas regras — porque as fronteiras são diferentes.
#
# `Domain/` é allowlist fechada (só Foundation): qualquer dependência nova ali
# é decisão estrutural, então o default certo é recusar.
#
# `Application/` é denylist dos frameworks de IO. Orquestrar caso de uso às
# vezes pede utilitário — `Logging` já é importado em 2 arquivos, legitimamente
# (é abstração, não infraestrutura). O que Application NUNCA pode enxergar é o
# framework HTTP ou o driver de banco: é isso que a invariante 2 protege, e até
# hoje ela só existia como texto no revisor.
case "$REL" in
  Sources/social-care-s/Domain/*.swift)      LAYER="Domain" ;;
  Sources/social-care-s/Application/*.swift) LAYER="Application" ;;
  *) exit 0 ;;
esac

[[ -f "$REL" ]] || exit 0

# Swift 6 aceita modificador antes do import: `public import`, `internal import`,
# `@preconcurrency import`, `@_exported import`. Todos contam.
IMPORT_RE='^[[:space:]]*(@[A-Za-z_]+[[:space:]]+|public[[:space:]]+|internal[[:space:]]+|package[[:space:]]+|private[[:space:]]+|fileprivate[[:space:]]+)*import[[:space:]]'

if [[ "$LAYER" == "Domain" ]]; then
  OFFENDERS="$(grep -nE "$IMPORT_RE" "$REL" | grep -vE '^[0-9]+:[[:space:]]*import Foundation[[:space:]]*$' || true)"
  RULE="Domain/ importa apenas Foundation — sem Vapor, SQLKit, JWT, NIO ou tipos de
Application/ e IO/."
else
  # Casa o nome do módulo no fim da linha de import. `NIO` pega NIOCore,
  # NIOHTTP1 etc. porque o prefixo é o mesmo.
  FORBIDDEN='Vapor|SQLKit|PostgresKit|PostgresNIO|JWT|JWTKit|NIO[A-Za-z]*|AsyncHTTPClient'
  OFFENDERS="$(grep -nE "$IMPORT_RE($FORBIDDEN)[[:space:]]*$" "$REL" || true)"
  RULE="Application/ orquestra o domínio e não conhece infraestrutura — sem Vapor,
SQLKit, PostgresKit, JWT, NIO ou AsyncHTTPClient. O adapter é papel de IO/;
o que Application precisa da infra entra por uma porta (protocolo) em shared/Ports/."
fi

[[ -z "$OFFENDERS" ]] && exit 0

{
  echo "Fronteira de $LAYER violada em $REL:"
  printf '%s\n' "$OFFENDERS"
  echo
  printf '%s\n' "$RULE"
  echo "Se a regra precisa mesmo cair, isso é um ADR, não um import."
} >&2

exit 2
