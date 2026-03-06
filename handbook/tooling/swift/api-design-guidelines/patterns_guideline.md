# Guia de Patterns em Swift para IA

> Baseado na documentação oficial do Swift Programming Language.  
> Este guia orienta uma IA a identificar, aplicar e explicar corretamente os padrões de correspondência (patterns) em Swift.

---

## O que é um Pattern?

Um **pattern** representa a **estrutura** de um valor — simples ou composto — e não um valor específico. Por isso, um único pattern pode corresponder a vários valores diferentes.

- O pattern `(x, y)` corresponde a `(1, 2)`, `(5, 10)`, ou qualquer tupla de dois elementos.
- Além de corresponder, patterns permitem **extrair e vincular** partes de um valor composto a constantes ou variáveis.

### Dois tipos fundamentais

| Tipo | Descrição | Onde usar |
|------|-----------|-----------|
| **Sempre corresponde** | Wildcard, Identifier, Value-Binding, Tuple | `let`, `var`, bindings opcionais |
| **Pode falhar** | Enum Case, Optional, Expression, Type-Casting | `switch/case`, `catch`, `if/while/guard/for-in` |

---

## Gramática Geral

```
pattern → wildcard-pattern type-annotation?
pattern → identifier-pattern type-annotation?
pattern → value-binding-pattern
pattern → tuple-pattern type-annotation?
pattern → enum-case-pattern
pattern → optional-pattern
pattern → type-casting-pattern
pattern → expression-pattern
```

---

## 1. Wildcard Pattern (`_`)

### O que é
Corresponde a **qualquer valor** e o ignora completamente. É representado por um underscore `_`.

### Quando usar
Quando o valor da posição não é relevante para a lógica.

### Exemplo
```swift
for _ in 1...3 {
    // Executa 3 vezes, sem usar o valor do intervalo
}
```

### Regra para IA
> Use `_` sempre que um valor precisa existir sintaticamente, mas não será utilizado.

---

## 2. Identifier Pattern

### O que é
Corresponde a qualquer valor e **vincula esse valor a um nome** (constante ou variável).

### Quando usar
Ao declarar variáveis/constantes normais. Quando usado no lado esquerdo de `let`/`var`, é implicitamente tratado como value-binding pattern.

### Exemplo
```swift
let someValue = 42
// "someValue" é um identifier pattern que captura o valor 42
```

### Regra para IA
> Identifier patterns são o caso mais comum — toda declaração `let x = ...` usa um.

---

## 3. Value-Binding Pattern

### O que é
Vincula valores correspondidos a **novos nomes** usando `let` ou `var`. O `let`/`var` se distribui para todos os identificadores dentro de um tuple pattern.

### Quando usar
Ao fazer destructuring em `switch` ou em declarações com múltiplos valores.

### Exemplo
```swift
let point = (3, 2)
switch point {
case let (x, y):
    print("O ponto é (\(x), \(y)).")
}
// Prints "O ponto é (3, 2)."
```

> `case let (x, y):` é equivalente a `case (let x, let y):`

### Regra para IA
> Use value-binding quando precisar nomear partes de um valor composto dentro de um `switch`.

---

## 4. Tuple Pattern

### O que é
Uma lista de patterns separada por vírgulas, entre parênteses. Corresponde a **tuplas do mesmo tipo e estrutura**.

### Quando usar
Para decompor e trabalhar com tuplas, especialmente em `for-in` e declarações de variáveis.

### Restrições importantes
- Em `for-in` e declarações, só pode conter: wildcards, identifiers, optional patterns ou outros tuple patterns.
- **Não é válido** usar expression patterns dentro de tuple patterns nesse contexto:

```swift
let points = [(0, 0), (1, 0), (1, 1)]

// ❌ INVÁLIDO — "0" é um expression pattern
for (x, 0) in points { }

// ✅ VÁLIDO
for (x, y) in points { }
```

- Parênteses em torno de um único elemento **não têm efeito**:

```swift
let a = 2         // a: Int
let (a) = 2       // a: Int — idêntico
let (a): Int = 2  // a: Int — idêntico
```

### Regra para IA
> Use tuple patterns para desestruturar tuplas. Lembre-se: expression patterns não são permitidos dentro deles em `for-in`.

---

## 5. Enumeration Case Pattern

### O que é
Corresponde a um **case específico de um enum**. Se o case tiver valores associados, o pattern deve incluir um tuple pattern com um elemento por valor.

### Quando usar
Em `switch`, `if case`, `while case`, `guard case`, `for case`.

### Exemplo simples
```swift
enum SomeEnum { case left, right }
let x: SomeEnum? = .left

switch x {
case .left:
    print("Vire à esquerda")
case .right:
    print("Vire à direita")
case nil:
    print("Siga em frente")
}
// Prints "Vire à esquerda"
```

> Um enum case pattern também corresponde a valores **wrapped em optional**. `.none` e `.some` podem aparecer no mesmo `switch` que os cases do enum.

### Regra para IA
> Para enums com valores associados, sempre inclua um tuple pattern correspondente. Para opcionais, `.none` e `.some` são válidos junto com os demais cases.

---

## 6. Optional Pattern

### O que é
Corresponde a valores **não-nulos** wrapped em `Optional`. É um identifier pattern seguido de `?`.

### Quando usar
Para desempacotar opcionais de forma concisa, especialmente em `for-in` sobre arrays de opcionais.

### Exemplo
```swift
let someOptional: Int? = 42

// Usando enum case pattern
if case .some(let x) = someOptional {
    print(x)
}

// Usando optional pattern (equivalente e mais conciso)
if case let x? = someOptional {
    print(x)
}

// Iterando apenas sobre valores não-nulos
let arrayOfOptionalInts: [Int?] = [nil, 2, 3, nil, 5]
for case let number? in arrayOfOptionalInts {
    print("Encontrado: \(number)")
}
// Encontrado: 2
// Encontrado: 3
// Encontrado: 5
```

### Regra para IA
> Prefira `let x?` a `case .some(let x)` — é mais legível e idiomático. Use em `for-in` para filtrar `nil` automaticamente.

---

## 7. Type-Casting Patterns (`is` / `as`)

### O que é
Dois patterns para correspondência baseada em **tipo em tempo de execução**:

| Pattern | Comportamento |
|---------|--------------|
| `is <Tipo>` | Verifica se o tipo corresponde, descarta o resultado |
| `<pattern> as <Tipo>` | Verifica e **converte** o valor para o tipo especificado |

### Forma geral
```swift
is <#type#>
<#pattern#> as <#type#>
```

### Quando usar
Em `switch` sobre valores de tipo `Any` ou `AnyObject`, ou em hierarquias de classe.

### Regra para IA
> Use `is` quando só precisa verificar o tipo. Use `as` quando precisa usar o valor convertido. Ambos correspondem ao tipo exato **ou subclasses** dele.

---

## 8. Expression Pattern

### O que é
Representa o **valor de uma expressão**. A correspondência usa o operador `~=` da standard library. Por padrão, `~=` compara com `==`, mas também suporta **ranges**.

### Quando usar
Apenas em `case` labels de `switch`. Ideal para comparar com ranges ou com lógica customizada.

### Exemplo com range
```swift
let point = (1, 2)
switch point {
case (0, 0):
    print("Na origem.")
case (-2...2, -2...2):
    print("Perto da origem.")
default:
    print("Longe da origem.")
}
// Prints "Perto da origem."
```

### Customizando com `~=`
```swift
// Permite comparar um Int com uma String
func ~= (pattern: String, value: Int) -> Bool {
    return pattern == "\(value)"
}

switch point {
case ("0", "0"):
    print("Na origem.")
default:
    print("O ponto é (\(point.0), \(point.1)).")
}
// Prints "O ponto é (1, 2)."
```

### Regra para IA
> Expression patterns são poderosos para ranges em `switch`. Para lógica personalizada, sobrecarregue o operador `~=`.

---

## Resumo: Quando usar cada Pattern

| Situação | Pattern recomendado |
|----------|-------------------|
| Ignorar um valor | `_` (Wildcard) |
| Nomear um valor | Identifier |
| Destructuring em `switch` | Value-Binding (`let`/`var`) |
| Trabalhar com tuplas | Tuple |
| Verificar cases de enum | Enumeration Case |
| Desempacotar optional com elegância | Optional (`?`) |
| Verificar tipo em runtime | `is` / `as` (Type-Casting) |
| Comparar com range ou expressão custom | Expression (`~=`) |

---

## Checklist para a IA

Antes de aplicar ou sugerir um pattern, verifique:

- [ ] O valor precisa ser usado ou pode ser ignorado? → Wildcard vs. Identifier
- [ ] Estou em um contexto de `switch`, `if case`, `guard case` ou `for case`? → Patterns que podem falhar são válidos aqui
- [ ] O valor é opcional? → Considere Optional Pattern (`?`) ou Enum Case `.some`/`.none`
- [ ] Preciso verificar ou converter o tipo? → `is` ou `as`
- [ ] Estou comparando contra um range? → Expression Pattern com `~=`
- [ ] Estou usando tuple pattern em `for-in`? → Não inclua expression patterns dentro dele

---

*Fonte: The Swift Programming Language — Patterns. © 2014–2025 Apple Inc. Licenciado sob CC BY 4.0.*