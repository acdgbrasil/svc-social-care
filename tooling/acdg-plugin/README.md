# Plugin `acdg`

Ferramental compartilhado dos serviços da ACDG. Nasceu de duas coisas que
**não** dão para fazer só com `.claude/` de projeto:

1. **Registrar um servidor LSP.** Apenas plugins leem `.lsp.json`. Sem isso não
   há navegação semântica em Swift (`goToDefinition`, `findReferences`,
   `goToImplementation`) — e ler Clean Architecture no `grep`, com protocolo
   aqui e implementação três pastas adiante, é caro e impreciso.
2. **Compartilhar entre repositórios.** O harness do `social-care` já foi
   copiado à mão para outro serviço uma vez. Cópia diverge; plugin versiona.

## O que traz

| Componente | O quê |
|---|---|
| `.lsp.json` + `bin/acdg-sourcekit-lsp` | SourceKit-LSP para `.swift`, resolvido na ordem Swiftly → PATH → Xcode. Swiftly vem primeiro porque é a toolchain que respeita o `.swift-version` do projeto. |
| `hooks/git-guard.sh` | `PreToolUse` (Bash): bloqueia force push em qualquer posição da linha; `--force-with-lease` passa. Genérico — vale para qualquer repo. |

O que é específico de um serviço (skills de camada, gate de regressão, fronteira
do domínio) continua no `.claude/` do próprio repositório. A regra de corte é:
**entrou no plugin o que serve a qualquer serviço da ACDG.**

## Usar

O `.claude/settings.json` do serviço registra o marketplace (`./tooling`) e
habilita `acdg@acdg`, então o plugin deve carregar sozinho. Confirme com:

```bash
claude plugin details acdg@acdg   # deve listar 1 hook e 1 LSP server (swift)
claude plugin validate ./tooling  # marketplace
```

**Confirmado em 2026-09-01:** carrega sozinho, sem `--plugin-dir`. Numa sessão
interativa `claude plugin details acdg@acdg` lista `Hooks (1)` e
`LSP servers (1) swift`, e o wrapper resolve pela Swiftly — dois processos
vivos, `~/.swiftly/bin/sourcekit-lsp` exec'ando o binário da toolchain
`swift-6.3.3-RELEASE`, com `cwd` no repo. As seis operações foram exercitadas
em código real:

| Operação | Verificado com |
|---|---|
| `documentSymbol` | `CPF.swift` → 25 símbolos, com `FiscalRegion` aninhado |
| `hover` | `CPF.init` → `public init(_ rawValue: String) throws` |
| `goToDefinition` (módulo externo) | `String` → `Swift.String.swiftinterface` |
| `goToDefinition` (cross-file) | `AppErrorConvertible` → `shared/Error/AppError.swift:250` |
| `findReferences` | `CPF` → 17 refs em 8 arquivos, Domain → Application → IO |
| `workspaceSymbol` | `RegisterPatientCommandHandler` → achou a classe |

Se a sessão *ainda* responder `No LSP server available for file type: .swift`,
aí sim a ativação travou na confiança do workspace: abra o `/plugin`, confirme
que `acdg` aparece ativo e sem entrada na aba **Errors**, rode
`/reload-plugins`, e use `claude --plugin-dir ./tooling/acdg-plugin` como
contorno.

### Warm-up: vazio nos primeiros minutos não é defeito

O servidor sobe junto com a primeira chamada. Enquanto carrega o `IndexStoreDB`
(RSS 43 MB → 264 MB, ~3–4 min), `hover`, `documentSymbol` e `goToDefinition`
para módulo externo já respondem, mas **`findReferences`, `workspaceSymbol` e
`goToDefinition` cross-file devolvem vazio** com "has not fully indexed the
workspace". É o mesmo sintoma de um LSP mal configurado, e a causa é outra —
**repita a chamada em vez de mexer na config.** Nas mesmas posições, passados os
minutos, tudo respondeu.

### O índice vem do build, não do editor

O store lido é `.build/debug/index/store`, escrito pelo `swift build` /
`swift test`. **Não há indexação contínua:** durante toda a validação nenhum
arquivo foi tocado em `.build/index-build`, que segue parado desde 2026-07-06 —
o servidor só carrega o que o build deixou pronto.

Portanto o resultado de `findReferences` reflete o último build, não o working
tree. Depois de editar `.swift`, rode `make build` antes de confiar na
navegação — senão a resposta descreve o código de antes da sua mudança.

Verificar o que ele carrega e quanto custa de contexto:

```bash
claude plugin validate ./tooling/acdg-plugin
claude plugin details acdg
```

Se um servidor LSP não subir, ele aparece em `/plugin` → aba **Errors**
(`Executable not found in $PATH` é o caso típico). Para ver o motivo:
`claude --debug`.

## Conflito com o `swift-lsp` oficial

O plugin `swift-lsp@claude-plugins-official` também declara um servidor para
`.swift`. Se os dois estiverem ativos, desative o oficial
(`claude plugin disable swift-lsp@claude-plugins-official`) para não disputar o
mesmo tipo de arquivo.

## Duplicação temporária do `git-guard`

O mesmo hook está registrado hoje em dois lugares: aqui e no
`.claude/settings.json` do `social-care`. É deliberado e provisório — enquanto o
plugin não estiver ativo por padrão, remover o local abriria uma janela sem
proteção contra force push. Quando o plugin estiver instalado e verificado, o
registro local sai e este vira a única fonte.

## Crescer daqui

Um plugin também aceita `agents/`, `skills/`, `commands/`, `.mcp.json`,
`monitors/` e um `settings.json` de defaults. Antes de mover qualquer coisa para
cá, aplique a regra de corte: material que fala de `Patient`, de `Domain/` ou de
`make regression` é do serviço, não da organização.
