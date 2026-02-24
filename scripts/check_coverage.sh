#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-95}"
TARGET_REGEX="/Sources/social-care-s/"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required to compute code coverage" >&2
  exit 1
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

printf 'Coverage (Sources/social-care-s): %.2f%% (%s/%s)\n' "$PERCENT" "$COVERED" "$TOTAL"
printf 'Threshold: %.2f%%\n' "$THRESHOLD"

if jq -e --arg target "$TARGET_REGEX" --argjson threshold "$THRESHOLD" '
  [.data[0].files[] | select(.filename | test($target)) | .summary.lines]
  | ((map(.covered) | add) * 100 / (map(.count) | add)) >= $threshold
' "$COVERAGE_JSON_PATH" >/dev/null; then
  echo "Coverage gate passed."
else
  echo "Coverage gate failed." >&2
  exit 1
fi
