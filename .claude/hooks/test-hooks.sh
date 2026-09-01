#!/usr/bin/env bash
# Bateria dos hooks. Roda no CI via check_harness.sh.
#
# Existe porque a primeira versão do `git-guard.sh` foi commitada como "guard
# real de force push, 12 casos testados" e tinha cinco escapes: os 12 casos
# eram variações de `--force`, e o `git` aceita muito mais que isso. Cada caso
# abaixo é um escape que já passou, ou um falso positivo que não pode voltar.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

# Dependências da BATERIA e dos hooks que ela exercita. Checadas aqui de
# propósito: sem `jq` os hooks saem com 2 (fail-closed — o comportamento certo
# de um guard que não consegue ler o comando), e a bateria reprovava todos os
# casos que esperam exit 0. Foram 13 falhas que pareciam bug dos hooks, num CI
# rodando `swift:6.3-jammy`, imagem que não traz `jq`. Uma linha de diagnóstico
# aqui vale mais que treze sintomas.
MISSING=""
for dep in jq python3; do
  command -v "$dep" >/dev/null 2>&1 || MISSING="$MISSING $dep"
done
if [[ -n "$MISSING" ]]; then
  echo "test-hooks: dependência ausente —$MISSING" >&2
  echo "Os hooks leem o JSON do stdin com jq e a bateria monta esse JSON com python3." >&2
  echo "No CI (container swift:*-jammy): apt-get install -y --no-install-recommends jq" >&2
  exit 1
fi

FAIL=0
run() { # hook, json, esperado, descrição
  local got
  printf '%s' "$2" | "./$1" >/dev/null 2>&1
  got=$?
  if [[ "$got" == "$3" ]]; then
    printf '  ✔ %s\n' "$4"
  else
    printf '  ✘ %s — esperava exit %s, veio %s\n' "$4" "$3" "$got"
    FAIL=$((FAIL + 1))
  fi
}

cmd() { python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"; }

echo "git-guard — deve BLOQUEAR (exit 2)"
run git-guard.sh "$(cmd 'git push --force')"                     2 'flag no início'
run git-guard.sh "$(cmd 'git push origin main --force')"         2 'flag no fim'
run git-guard.sh "$(cmd 'git push -f origin main')"              2 'forma curta'
run git-guard.sh "$(cmd 'git push -fu origin main')"             2 'curta agrupada (-fu)'
run git-guard.sh "$(cmd 'git push origin main -uf')"             2 'curta agrupada (-uf)'
run git-guard.sh "$(cmd 'git push "--force"')"                   2 'entre aspas'
run git-guard.sh "$(cmd 'git push --force=x origin')"            2 'com ='
run git-guard.sh "$(cmd 'git push origin +main')"                2 'refspec + (força implícita)'
run git-guard.sh "$(cmd 'git push origin +HEAD:refs/heads/main')" 2 'refspec + completo'
run git-guard.sh "$(cmd 'git status && git push origin main --force')" 2 'comando composto'
run git-guard.sh "$(cmd 'git push origin main \
  --force')"                                                      2 'continuação de linha'
run git-guard.sh "$(cmd 'git -C /tmp/x push --force')"           2 'com -C'
run git-guard.sh "$(cmd 'git push --force-with-lease origin main --force')" 2 'lease + force'

echo
echo "git-guard — deve PASSAR (exit 0)"
run git-guard.sh "$(cmd 'git push origin main')"                 0 'push normal'
run git-guard.sh "$(cmd 'git push --force-with-lease origin main')" 0 'force-with-lease'
run git-guard.sh "$(cmd 'git push origin main --force-if-includes')" 0 'force-if-includes'
run git-guard.sh "$(cmd 'git log --oneline -f')"                 0 '-f fora de push'
run git-guard.sh "$(cmd 'grep -rn force Sources/')"              0 'palavra force em outro comando'
run git-guard.sh "$(cmd 'make test')"                            0 'comando sem git'
run git-guard.sh "$(cmd 'git fetch origin +refs/heads/*:refs/remotes/origin/*')" 0 'refspec + em fetch (não é push)'

echo
echo "domain-imports — deve BLOQUEAR (exit 2)"
PROBE="../../Sources/social-care-s/Domain/__hook_probe.swift"
trap 'rm -f "$PROBE"' EXIT
probe() { printf '%s\n' "$1" > "$PROBE"; }
J='{"tool_input":{"file_path":"Sources/social-care-s/Domain/__hook_probe.swift"}}'

probe 'import Vapor';                    run domain-imports.sh "$J" 2 'import simples'
probe '@preconcurrency import Vapor';    run domain-imports.sh "$J" 2 '@preconcurrency'
probe 'public import SQLKit';            run domain-imports.sh "$J" 2 'public import'
probe 'internal import Vapor';           run domain-imports.sh "$J" 2 'internal import'
probe '@_exported import Vapor';         run domain-imports.sh "$J" 2 '@_exported'
probe '  import NIOCore';                run domain-imports.sh "$J" 2 'indentado'

echo
echo "domain-imports — deve PASSAR (exit 0)"
probe 'import Foundation';               run domain-imports.sh "$J" 0 'Foundation'
probe '// import Vapor faria o domínio depender de HTTP'
                                         run domain-imports.sh "$J" 0 'menção em comentário'
rm -f "$PROBE"
run domain-imports.sh '{"tool_input":{"file_path":"Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift"}}' 0 'arquivo fora de Domain/ e Application/'

# Application/ tem fronteira PRÓPRIA: denylist de framework de IO, não allowlist.
# `Logging` passa de propósito — já é importado em 2 arquivos reais, e barrá-lo
# quebraria o suite no primeiro commit.
echo
echo "domain-imports (Application/) — deve BLOQUEAR (exit 2)"
APROBE="../../Sources/social-care-s/Application/__hook_probe.swift"
trap 'rm -f "$PROBE" "$APROBE"' EXIT
aprobe() { printf '%s\n' "$1" > "$APROBE"; }
AJ='{"tool_input":{"file_path":"Sources/social-care-s/Application/__hook_probe.swift"}}'

aprobe 'import Vapor';                   run domain-imports.sh "$AJ" 2 'Vapor em Application'
aprobe 'import SQLKit';                  run domain-imports.sh "$AJ" 2 'SQLKit em Application'
aprobe 'import PostgresKit';             run domain-imports.sh "$AJ" 2 'PostgresKit'
aprobe '@preconcurrency import JWTKit';  run domain-imports.sh "$AJ" 2 'JWTKit com modificador'
aprobe 'import NIOCore';                 run domain-imports.sh "$AJ" 2 'NIOCore'
aprobe 'import AsyncHTTPClient';         run domain-imports.sh "$AJ" 2 'AsyncHTTPClient'

echo
echo "domain-imports (Application/) — deve PASSAR (exit 0)"
aprobe 'import Foundation';              run domain-imports.sh "$AJ" 0 'Foundation'
aprobe 'import Logging';                 run domain-imports.sh "$AJ" 0 'Logging (abstração, uso real no repo)'
aprobe '// import Vapor aqui invertaria a dependência'
                                         run domain-imports.sh "$AJ" 0 'menção em comentário'
rm -f "$APROBE"

echo
if [[ $FAIL -eq 0 ]]; then
  echo "Hooks: todos os casos passaram."
  exit 0
fi
echo "Hooks: $FAIL caso(s) falharam." >&2
exit 1
