#!/usr/bin/env bash
# Verifica que o harness (`.claude/`) afirma só o que o código comprova — ADR-042.
#
# O harness anterior tinha 19 mil linhas e ensinava padrões que o código havia
# abandonado: um `EventBus` removido por ADR, uma role que nunca existiu, um gate
# de cobertura que o CI nunca rodou. Nada disso era desleixo pontual — nada
# verificava as afirmações. Este script é esse "nada".
#
# Falha (exit 1) quando o harness cita caminho inexistente, quando um número que
# ele afirma diverge do que o código responde, quando uma role usada no código
# não está documentada, ou quando a promessa de gate de cobertura ressuscita.
#
#   ./scripts/check_harness.sh
set -uo pipefail
export LC_ALL=C

cd "$(dirname "$0")/.." || exit 1

FAILURES=0
CHECKS=0

fail() { printf '  ✘ %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
pass() { printf '  ✔ %s\n' "$1"; }
check() { CHECKS=$((CHECKS + 1)); }

AGENT=".claude/agents/social-care.md"
HARNESS_FILES=$(find .claude -name '*.md' 2>/dev/null)

# ---------------------------------------------------------------------------
# 1. Todo caminho citado no harness existe
# ---------------------------------------------------------------------------
echo "1. Caminhos citados no harness"
check
MISSING=0
while IFS=: read -r file path; do
  [[ -e "$path" ]] && continue
  fail "$file cita \`$path\`, que não existe"
  MISSING=$((MISSING + 1))
done < <(
  for f in $HARNESS_FILES; do
    grep -oE '`[^`]+`' "$f" \
      | tr -d '`' \
      | grep -E '^(Sources|Tests|handbook|scripts|docs|tooling|\.github|\.claude)/' \
      | grep -vE '[<>*$|]' \
      | sed "s|^|$f:|"
  done | sort -u
)
[[ $MISSING -eq 0 ]] && pass "todos os caminhos citados existem"

# ---------------------------------------------------------------------------
# 2. Números afirmados batem com o código
#
# O agente mantém uma tabela `| <rótulo> | <valor> | <comando> |`. Os rótulos
# abaixo são contrato: renomeá-los cega esta verificação.
# ---------------------------------------------------------------------------
echo
echo "2. Contagens afirmadas no agente"

claimed() { grep -E "^\| $1 \|" "$AGENT" | head -1 | awk -F'|' '{print $3}' | grep -oE '[0-9]+' | head -1; }

compare() { # rótulo, valor real, como recalcular
  check
  local label="$1" real="$2" how="$3" said
  said="$(claimed "$label")"
  if [[ -z "$said" ]]; then
    fail "rótulo '$label' sumiu da tabela de $AGENT (renomeado?) — a verificação depende dele"
  elif [[ "$said" != "$real" ]]; then
    fail "$label: agente diz $said, código responde $real  →  corrija a tabela ($how)"
  else
    pass "$label: $real"
  fi
}

compare "Use cases de escrita" \
  "$(find Sources/social-care-s/Application -type d -name Command | wc -l | tr -d ' ')" \
  'find Sources/social-care-s/Application -type d -name Command | wc -l'

compare "Controllers" \
  "$(ls Sources/social-care-s/IO/HTTP/Controllers/*.swift 2>/dev/null | wc -l | tr -d ' ')" \
  'ls Sources/social-care-s/IO/HTTP/Controllers/*.swift | wc -l'

compare "Rotas" \
  "$(grep -rhoE '\.(get|post|put|patch|delete)\(' Sources/social-care-s/IO/HTTP/Controllers/ | wc -l | tr -d ' ')" \
  'grep -rhoE "\.(get|post|put|patch|delete)\(" Sources/social-care-s/IO/HTTP/Controllers/ | wc -l'

compare "Migrations" \
  "$(( $(ls Sources/social-care-s/IO/Persistence/SQLKit/Migrations/*.swift 2>/dev/null | wc -l) - 2 ))" \
  'arquivos em Migrations/ menos Migration.swift e SQLKitMigrationRunner.swift'

# ---------------------------------------------------------------------------
# 3. Toda role usada no código está documentada no harness
# ---------------------------------------------------------------------------
echo
echo "3. Roles do RBAC"
check
# `tr -d '\n'` antes do grep: chamada quebrada em varias linhas nao casava, e a
# role indocumentada ficava invisivel — o laco nao iterava e o check passava.
ROLES=$(find Sources -name '*.swift' -exec cat {} + | tr -d '\n' \
  | grep -oE 'RoleGuardMiddleware\([^)]*\)' | grep -oE '"[a-z_]+"' | tr -d '"' | sort -u)
UNDOCUMENTED=0
if [[ -z "$ROLES" ]]; then
  # Nenhuma role encontrada e defeito do verificador, nao ausencia de RBAC.
  fail "nenhuma role extraida de RoleGuardMiddleware — o RBAC mudou de forma e este check ficou cego"
  UNDOCUMENTED=1
fi
for role in $ROLES; do
  if ! grep -qE "\`$role\`|\"$role\"" $HARNESS_FILES 2>/dev/null; then
    fail "role '$role' é usada em RoleGuardMiddleware e não aparece no harness"
    UNDOCUMENTED=$((UNDOCUMENTED + 1))
  fi
done
[[ $UNDOCUMENTED -eq 0 ]] && pass "roles documentadas: $(echo $ROLES | tr '\n' ' ')"

# ---------------------------------------------------------------------------
# 4. Padrões abandonados não ressuscitaram na documentação viva
#
# Cada termo abaixo já foi verdade e deixou de ser. Mencioná-los é legítimo
# quando o texto os marca como armadilha — daí a exceção por negação.
# `handbook/reports/` e os ADRs ficam de fora: são registro histórico.
# ---------------------------------------------------------------------------
echo
echo "4. Padrões abandonados"

# `IMPROVEMENT_BACKLOG.md` fica de fora porque discutir alternativa nao adotada
# e a funcao dele — proposta nao e afirmacao.
# `handbook/tooling/` guarda copias de documentacao oficial (Vapor, Swift book):
# o texto de terceiros nao responde pelas convencoes deste projeto. `reports/` e
# os ADRs sao registro historico. Nenhum dos tres entra na verificacao.
LIVE_DOCS=$(find .claude docs handbook -name '*.md' 2>/dev/null \
  | grep -v '^handbook/reports/' \
  | grep -v '^handbook/tooling/' \
  | grep -v '^handbook/architecture/DECISIONS/' \
  | grep -v '^handbook/architecture/IMPROVEMENT_BACKLOG.md$')
LIVE_DOCS="$LIVE_DOCS CLAUDE.md README.md"

# Uma menção é legítima quando o texto a marca como superada. Olhamos a linha
# e suas vizinhas: em Markdown a negação costuma abrir o parágrafo ou o cenário,
# e o termo cai na linha seguinte.
# Marcadores inequivocos, so. A lista anterior tinha `não`, `foi `, `era ` e
# `anterior`: 348 das ~4.900 linhas dos LIVE_DOCS casavam por acidente, e o
# check virava probabilistico. Estes exigem que o texto trate o termo como
# superado, nao apenas que contenha uma negacao qualquer.
NEGATION='~~|RESOLVIDO|nunca existiu|não existe|nao existe|aposentad|removid|abandonad|superad|deprecad|ignorando|forjáv|forjav|era falsa|é falsa|e falsa|deixou de|caminho morto|inexistente'

banned() { # termo, por quê
  check
  local term="$1" why="$2" hits=0
  while IFS=: read -r file line text; do
    # contexto de uma linha para cada lado
    local ctx
    ctx="$(sed -n "$(( line > 1 ? line - 1 : 1 )),$(( line + 1 ))p" "$file" 2>/dev/null)"
    printf '%s' "$ctx" | grep -qiE "$NEGATION" && continue
    fail "$file:$line ressuscita '$term' ($why)"
    hits=$((hits + 1))
  done < <(grep -nHiE "$term" $LIVE_DOCS 2>/dev/null)
  [[ $hits -eq 0 ]] && pass "'$term' não aparece afirmativamente"
}

banned 'social_worker'          'role que nunca existiu; as reais são worker/owner/admin/superadmin'
banned 'X-Actor-Id'             'header aposentado pelo ADR-023 — actorId vem do JWT.sub'
banned 'infra/reference-network' 'caminho morto herdado de outro repositório'
banned '95%'                     'gate de cobertura abandonado pelo ADR-041'
banned 'Hummingbird'             'o framework HTTP e Vapor 4 — ver Package.swift'

# ---------------------------------------------------------------------------
# 5. Versão do Swift citada bate com .swift-version
# ---------------------------------------------------------------------------
echo
echo "5. Versão do Swift"
check
SWIFT_VERSION="$(tr -d ' \n' < .swift-version)"
SWIFT_MINOR="${SWIFT_VERSION%.*}"
WRONG=0
# Valida a SERIE (6.3.x), nao o patch: citar `Swift 6.3.1` numa nota historica
# sobre qual patch corrigiu um bug e legitimo. O alvo aqui e a serie errada —
# era `Swift 6.2` espalhado pelo README e pelo harness antigo.
while IFS=: read -r file line text; do
  cited="$(printf '%s' "$text" | grep -oE 'Swift [0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
  fail "$file:$line cita $cited — .swift-version fixa $SWIFT_VERSION"
  WRONG=$((WRONG + 1))
done < <(grep -nHoE 'Swift [0-9]+\.[0-9]+(\.[0-9]+)?' $LIVE_DOCS 2>/dev/null \
  | grep -vE "Swift ${SWIFT_MINOR}")
[[ $WRONG -eq 0 ]] && pass "toda menção pertence à série ${SWIFT_MINOR} (.swift-version: $SWIFT_VERSION)"

# ---------------------------------------------------------------------------
# 6. Hooks passam na propria bateria
# ---------------------------------------------------------------------------
echo
echo "6. Bateria dos hooks"
check
if HOOK_OUT="$(.claude/hooks/test-hooks.sh 2>&1)"; then
  pass "$(printf '%s' "$HOOK_OUT" | tail -1)"
else
  fail "bateria dos hooks falhou:"
  printf '%s\n' "$HOOK_OUT" | grep '✘' | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
# 7. A copia do git-guard no plugin nao divergiu
#
# Sao dois registros do mesmo hook (projeto e plugin) enquanto o plugin nao
# carrega por padrao. Corrigir um furo so num deles deixa o outro aberto.
# ---------------------------------------------------------------------------
echo
echo "7. Cópia do git-guard no plugin"
check
if cmp -s .claude/hooks/git-guard.sh tooling/acdg-plugin/hooks/git-guard.sh; then
  pass "idêntica à do projeto"
else
  fail "tooling/acdg-plugin/hooks/git-guard.sh divergiu de .claude/hooks/git-guard.sh — sincronize (cp) ou remova uma das cópias"
fi

# ---------------------------------------------------------------------------
echo
if [[ $FAILURES -eq 0 ]]; then
  echo "Harness verificado: $CHECKS checagens, nenhuma divergência."
  exit 0
fi
echo "Harness divergente: $FAILURES problema(s) em $CHECKS checagens." >&2
echo "Documentação que mente é pior que documentação ausente — corrija antes de seguir (ADR-042)." >&2
exit 1
