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

**Estado em 2026-09-01:** `details` resolve o plugin corretamente, mas uma
sessão `-p` recém-criada ainda respondeu `No LSP server available for
file type: .swift`. A ativação depende de confiar no workspace na primeira
sessão interativa — abra o `/plugin`, confirme que `acdg` aparece ativo e sem
entrada na aba **Errors**, e rode `/reload-plugins` se ele pedir. Enquanto isso
não for confirmado, o caminho garantido é carregar direto:

```bash
claude --plugin-dir ./tooling/acdg-plugin
```

Foi assim que o LSP foi validado ponta a ponta (`documentSymbol` em
`DomainProtocols.swift` → `OK Core Domain Events`).

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
