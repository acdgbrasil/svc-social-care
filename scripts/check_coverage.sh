#!/usr/bin/env bash
set -euo pipefail

# Mede a cobertura de linhas de `Sources/social-care-s/`.
#
#   ./scripts/check_coverage.sh          # gate no default local (30%)
#   ./scripts/check_coverage.sh 45       # gate em 45%
#   ./scripts/check_coverage.sh report   # só mede; nunca reprova
#
# O modo `report` existe porque neste projeto a cobertura é TERMOMETRO, nao
# contrato: serve para enxergar onde estamos e qual camada esta descoberta.
# Quem reprova o CI e o resultado dos testes, nao o percentual — ver ci.yml.
# O breakdown por camada e o dado que importa: um numero global esconde que
# Domain esta coberto e IO nao.
#
# Locale-safe: jq emite numeros com ponto decimal; sob LC_NUMERIC com virgula
# (ex.: pt_BR) o `printf '%.2f'` aborta com "numero invalido" e, com `set -e`,
# derruba o script antes do gate. Forcar ponto decimal em todo o script.
export LC_ALL=C

MODE="${1:-30}"
TARGET_REGEX="/Sources/social-care-s/"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required to compute code coverage" >&2
  exit 1
fi

if [[ "$MODE" != "report" ]] && ! [[ "$MODE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "error: argumento deve ser um numero (threshold) ou 'report'; recebido: $MODE" >&2
  exit 2
fi

swift test --enable-code-coverage
COVERAGE_JSON_PATH="$(swift test --show-codecov-path)"

STATS="$(jq -r --arg target "$TARGET_REGEX" '
  [.data[0].files[] | select(.filename | test($target)) | .summary.lines]
  | {
      covered: (map(.covered) | add),
      count: (map(.count) | add),
      percent: ((map(.covered) | add) * 100 / (map(.count) | add))
    }
  | "\(.covered) \(.count) \(.percent)"
' "$COVERAGE_JSON_PATH")"

read -r COVERED TOTAL PERCENT <<<"$STATS"

# Breakdown por camada (primeiro diretorio sob Sources/social-care-s/).
LAYERS="$(jq -r --arg target "$TARGET_REGEX" '
  [ .data[0].files[]
    | select(.filename | test($target))
    | (.filename | split("/Sources/social-care-s/")[1] | split("/")) as $p
    | { layer: (if ($p | length) > 1 then $p[0] else "(root)" end), lines: .summary.lines }
  ]
  | group_by(.layer)
  | map({
      layer: .[0].layer,
      covered: (map(.lines.covered) | add),
      count: (map(.lines.count) | add)
    })
  | sort_by(.covered * 100 / .count)
  | .[]
  | "\(.layer) \(.covered) \(.count) \(.covered * 100 / .count)"
' "$COVERAGE_JSON_PATH")"

printf 'Coverage (Sources/social-care-s): %.2f%% (%s/%s linhas)\n\n' "$PERCENT" "$COVERED" "$TOTAL"
printf '%-14s %10s %10s %8s\n' "CAMADA" "COBERTAS" "TOTAL" "%"
while read -r layer covered count percent; do
  printf '%-14s %10s %10s %7.2f%%\n' "$layer" "$covered" "$count" "$percent"
done <<<"$LAYERS"

# No CI, publica a mesma leitura no resumo do job (visivel sem abrir o log).
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    printf '## Cobertura de testes\n\n'
    printf '**%.2f%%** — %s de %s linhas em `Sources/social-care-s/`.\n\n' "$PERCENT" "$COVERED" "$TOTAL"
    printf 'Termometro, nao gate: o CI reprova por teste vermelho, nunca por percentual.\n\n'
    printf '| Camada | Cobertas | Total | %% |\n|---|---:|---:|---:|\n'
    while read -r layer covered count percent; do
      printf '| `%s` | %s | %s | %.2f%% |\n' "$layer" "$covered" "$count" "$percent"
    done <<<"$LAYERS"
  } >>"$GITHUB_STEP_SUMMARY"
fi

if [[ "$MODE" == "report" ]]; then
  echo
  echo "Modo report: sem gate."
  exit 0
fi

printf '\nThreshold: %.2f%%\n' "$MODE"

if jq -e --arg target "$TARGET_REGEX" --argjson threshold "$MODE" '
  [.data[0].files[] | select(.filename | test($target)) | .summary.lines]
  | ((map(.covered) | add) * 100 / (map(.count) | add)) >= $threshold
' "$COVERAGE_JSON_PATH" >/dev/null; then
  echo "Coverage gate passed."
else
  echo "Coverage gate failed." >&2
  exit 1
fi
