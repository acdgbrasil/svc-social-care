#!/usr/bin/env bash
# Hook Stop — enforcement da REGRA INVIOLÁVEL do CLAUDE.md:
# "teste falhando é responsabilidade de quem está no comando".
#
# Roda o suite de regressão (alvo < 5s; medido em 1,13s com build quente) e
# bloqueia o fim do turno se estiver vermelho. Sai barato porque só roda quando
# o turno mexeu em Swift — turno de documentação não paga nada.
#
# Contrato do hook (stdin JSON, exit code):
#   exit 0 → deixa o turno terminar
#   exit 2 → bloqueia; stderr vira a instrução para o Claude
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

INPUT="$(cat)"

# Anti-loop: se este hook já bloqueou uma vez neste turno, não bloqueia de novo.
# Sem isso, um teste que o Claude não consegue consertar prende a sessão.
if [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" == "true" ]]; then
  exit 0
fi

# Só vale a pena com código Swift tocado (working tree ou index).
if ! git status --porcelain -- '*.swift' 2>/dev/null | grep -q .; then
  exit 0
fi

OUTPUT="$(make regression 2>&1)"
STATUS=$?

if [[ $STATUS -eq 0 ]]; then
  exit 0
fi

{
  echo "Suite de regressão VERMELHO — o turno não termina assim (CLAUDE.md, regra inviolável)."
  echo "Conserte antes de encerrar, mesmo que a falha seja colateral ao que você mexeu."
  echo
  printf '%s\n' "$OUTPUT" | grep -E "✘|error:|failed|Test .* recorded an issue" | head -20
} >&2

exit 2
