#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${CONTRACTS_OUT_DIR:-$ROOT_DIR/.contracts}"
TMP_DIR="${CONTRACTS_TMP_DIR:-$ROOT_DIR/.contracts-tmp}"
CONTRACTS_REF="${CONTRACTS_REF:-ghcr.io/acdgbrasil/contracts:v1.0.0}"

rm -rf "$OUT_DIR" "$TMP_DIR"
mkdir -p "$OUT_DIR" "$TMP_DIR"

if [[ -n "${CONTRACTS_LOCAL_DIR:-}" ]]; then
  echo "Using local contracts from: $CONTRACTS_LOCAL_DIR"
  cp "$CONTRACTS_LOCAL_DIR/README.md" "$OUT_DIR/README.md"
  cp -R "$CONTRACTS_LOCAL_DIR/services" "$OUT_DIR/services"
  cp -R "$CONTRACTS_LOCAL_DIR/shared" "$OUT_DIR/shared"
else
  if ! command -v oras >/dev/null 2>&1; then
    echo "oras CLI not found. Install ORAS or set CONTRACTS_LOCAL_DIR."
    exit 1
  fi

  echo "Pulling contracts artifact: $CONTRACTS_REF"
  oras pull "$CONTRACTS_REF" --output "$TMP_DIR"

  BUNDLE="$(find "$TMP_DIR" -maxdepth 1 -type f -name 'contracts-*.tgz' | head -n 1)"
  if [[ -z "$BUNDLE" ]]; then
    echo "No contracts bundle (*.tgz) found in pulled artifact."
    exit 1
  fi

  tar -xzf "$BUNDLE" -C "$OUT_DIR"
fi

SPEC_PATH="$OUT_DIR/services/social-care/openapi/openapi.yaml"
if [[ ! -f "$SPEC_PATH" ]]; then
  echo "Expected spec not found: $SPEC_PATH"
  exit 1
fi

echo "Contracts ready at: $OUT_DIR"
