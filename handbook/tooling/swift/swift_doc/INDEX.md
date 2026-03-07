# Swift Documentation Index

Este arquivo serve como mapa para uma IA CLI encontrar a referência certa sobre qualquer tema Swift.
Todos os arquivos `.md` neste diretório contêm documentação oficial da linguagem Swift extraída e formatada para consumo por LLMs.

## Como usar

1. Leia este INDEX.md primeiro para identificar qual arquivo consultar
2. Abra o arquivo relevante ao tema da pergunta
3. Para temas que cruzam múltiplas áreas, consulte múltiplos arquivos

## Referências por Tema

### Fundamentos
| Arquivo | Conteúdo |
|---------|----------|
| `basic-operators.md` | Operadores aritméticos, comparação, range (`a..<b`, `a...b`), ternário, nil-coalescing (`??`) |
| `strings-and-characters.md` | Manipulação de strings, Unicode, interpolação (`\()`), substrings, multiline strings |
| `collection-types.md` | Array, Set, Dictionary — criação, iteração, map/filter/reduce, transformações |
| `control-flow.md` | if/else, switch (pattern matching), for-in, while, guard, repeat-while, #available |
| `functions.md` | Declaração com `func`, parâmetros nomeados, valores default, retorno múltiplo, `inout`, funções como tipo |
| `closures.md` | Sintaxe de closure, trailing closures, capturing values, `@escaping`, shorthand `$0/$1` |
| `enumerations.md` | Enum com associated values, raw values, CaseIterable, enums recursivos com `indirect` |
| `structures-and-classes.md` | Diferenças struct vs class, value types vs reference types, memberwise initializer |

### Orientação a Objetos e Protocolos
| Arquivo | Conteúdo |
|---------|----------|
| `properties.md` | Stored properties, computed properties, property observers (`willSet`/`didSet`), property wrappers, `static`/`class` |
| `methods.md` | Instance methods, type methods, `mutating` em structs/enums, `self` |
| `subscripts.md` | Subscripts customizados, overloading de subscripts, subscripts estáticos |
| `inheritance.md` | Herança de classes, `override`, `final`, polimorfismo, casting entre classes |
| `initialization.md` | `init`, `convenience init`, failable init (`init?`), `required init`, two-phase initialization, delegação |
| `deinitialization.md` | `deinit`, cleanup de recursos, ordem de deinicialização |
| `protocols.md` | Conformance, protocol extensions, default implementations, delegation pattern, associated types, `Self` |
| `extensions.md` | Adicionar métodos, computed properties, initializers e conformances a tipos existentes |
| `nested-types.md` | Tipos definidos dentro de outros tipos |

### Tipos Avançados e Generics
| Arquivo | Conteúdo |
|---------|----------|
| `generics.md` | Funções e tipos genéricos, type constraints, `where` clauses, associated types em protocols |
| `generic-parameters-and-arguments.md` | Sintaxe formal de parâmetros genéricos, constraints avançados |
| `opaque-and-boxed-protocol-types.md` | `some` (opaque types), `any` (boxed protocol types), diferenças e quando usar cada um |
| `optional-chaining.md` | Encadear chamadas em optionals (`?.`), fallback com `??`, optional binding |
| `type-casting.md` | `is`, `as`, `as?`, `as!`, `Any`, `AnyObject`, type checking |
| `types.md` | Sistema de tipos do Swift, metatypes (`.Type`, `.self`), tuplas, function types, `Self` |

### Concorrência e Memória
| Arquivo | Conteúdo |
|---------|----------|
| `concurrency.md` | `async`/`await`, `Task`, `TaskGroup`, `actor`, `Sendable`, isolation, structured concurrency |
| `memory-safety.md` | Acesso exclusivo a memória, conflitos de acesso em `inout`, regras de exclusividade |
| `automatic-reference-counting.md` | ARC, `strong`/`weak`/`unowned`, retain cycles, capture lists em closures (`[weak self]`) |

### Tratamento de Erros e Patterns
| Arquivo | Conteúdo |
|---------|----------|
| `error-handling.md` | `throw`, `try`, `try?`, `try!`, `catch`, `do-catch`, `Result`, `rethrows` |
| `patterns.md` | Pattern matching em switch/if/guard, wildcard `_`, value-binding, tuple/enum/optional/expression patterns |

### Recursos Avançados
| Arquivo | Conteúdo |
|---------|----------|
| `advanced-operators.md` | Operadores customizados (`prefix`/`infix`/`postfix`), bitwise, overflow operators (`&+`), precedence groups |
| `attributes.md` | `@available`, `@discardableResult`, `@MainActor`, `@Sendable`, `@propertyWrapper`, `@resultBuilder` |
| `macros.md` | Macros freestanding (`#stringify`) e attached (`@Observable`), como criar macros |
| `access-control.md` | `open`, `public`, `internal`, `fileprivate`, `private` — regras e quando usar cada nível |

### Referência Formal da Linguagem
| Arquivo | Conteúdo |
|---------|----------|
| `declarations.md` | Sintaxe formal de todas as declarações (let, var, func, class, struct, enum, protocol, etc.) |
| `expressions.md` | Sintaxe formal de expressões (literais, closures, key-path, selector, etc.) |
| `statements.md` | Sintaxe formal de statements (loops, branches, labeled statements, compiler control) |
| `lexical-structure.md` | Tokens, literais, identificadores, palavras reservadas, operadores, whitespace |
| `summary-of-the-grammar.md` | Gramática formal completa do Swift em BNF |
