#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACTS_DIR="${CONTRACTS_OUT_DIR:-$ROOT_DIR/.contracts}"
SPEC_PATH="${CONTRACTS_SPEC_PATH:-$CONTRACTS_DIR/services/social-care/openapi/openapi.yaml}"
OUT_PATH="${CONTRACTS_TYPES_OUT:-$ROOT_DIR/src/contracts/openapi.types.ts}"

if [[ ! -f "$SPEC_PATH" ]]; then
  echo "OpenAPI spec not found: $SPEC_PATH"
  echo "Run: bun run contracts:pull"
  exit 1
fi

mkdir -p "$(dirname "$OUT_PATH")"

GENERATOR="$ROOT_DIR/node_modules/.bin/openapi-typescript"
if [[ ! -x "$GENERATOR" ]]; then
  echo "openapi-typescript is not installed. Run: bun install"
  exit 1
fi

"$GENERATOR" "$SPEC_PATH" -o "$OUT_PATH"

echo "Generated types at: $OUT_PATH"
