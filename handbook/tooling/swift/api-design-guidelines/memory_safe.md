# Guia de Memory Safety em Swift para IA

> Baseado na documentação oficial do Swift Programming Language.  
> Este guia orienta uma IA a identificar, explicar e corrigir conflitos de acesso à memória em Swift.

---

## O que é Memory Safety?

Swift previne comportamentos inseguros por padrão, garantindo que:
- Variáveis sejam inicializadas antes de serem usadas
- Memória não seja acessada após ser desalocada
- Índices de arrays sejam verificados para erros de out-of-bounds
- Múltiplos acessos ao mesmo endereço de memória **não entrem em conflito**

Quando há conflito, Swift gera um **erro em tempo de compilação ou de execução**.

> **Nota:** Conflitos de memória podem acontecer em código **single-threaded**. Para código multithreaded, use o **Thread Sanitizer**. Esta documentação trata do caso single-thread.

---

## 1. Entendendo Conflitos de Acesso à Memória

### O que é um acesso à memória
Qualquer operação que leia ou escreva em memória — atribuir uma variável, passar argumento para função, etc.

```swift
var one = 1              // write access
print("número \(one)")   // read access
```

### Quando ocorre um conflito
Um conflito acontece quando **dois acessos satisfazem todas as três condições** abaixo simultaneamente:

| Condição | Detalhe |
|----------|---------|
| **Pelo menos um é escrita** | Dois reads nunca conflitam. Dois writes ou um read + um write conflitam. |
| **Mesma localização na memória** | Mesma variável, constante ou propriedade |
| **Durações sobrepostas** | Os acessos ocorrem ao mesmo tempo |

### Tipos de acesso por duração

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| **Instantâneo** | Nenhum outro código roda entre início e fim do acesso | Leitura/escrita simples de variável |
| **Long-term** | Outro código pode rodar enquanto o acesso está ativo | Parâmetros `inout`, métodos `mutating` |

> **Acesso atômico** (usando `Atomic`, `AtomicLazyReference` ou operações C atômicas) nunca conflita.

### Regra para IA
> Um conflito exige: (1) pelo menos uma escrita, (2) mesma memória, (3) durações sobrepostas. Se qualquer uma dessas condições não for atendida, não há conflito.

---

## 2. Conflitos em Parâmetros `inout`

### Por que `inout` cria long-term access
Uma função tem **write access de longa duração** a todos os seus parâmetros `inout`. Esse acesso começa após a avaliação dos parâmetros não-inout e **dura toda a chamada da função**.

### Conflito 1: Acessar a variável original dentro da função

```swift
var stepSize = 1

func increment(_ number: inout Int) {
    number += stepSize  // lê stepSize (read)
}

increment(&stepSize)
// ❌ Erro: Conflicting accesses to stepSize
// Write (via &stepSize) e Read (via stepSize) ocorrem ao mesmo tempo
```

**Por quê:** `number` e `stepSize` apontam para a mesma memória. A função tem write access a `number`, mas também lê `stepSize` — dois acessos sobrepostos ao mesmo endereço.

**Solução:** Fazer uma cópia explícita antes da chamada:

```swift
var copyOfStepSize = stepSize   // read termina aqui
increment(&copyOfStepSize)      // write em copyOfStepSize, não em stepSize
stepSize = copyOfStepSize       // atualiza o original depois
// ✅ stepSize agora é 2
```

### Conflito 2: Mesma variável em múltiplos parâmetros `inout`

```swift
func balance(_ x: inout Int, _ y: inout Int) {
    let sum = x + y
    x = sum / 2
    y = sum - x
}

var playerOneScore = 42
var playerTwoScore = 30

balance(&playerOneScore, &playerTwoScore) // ✅ OK — memórias diferentes
balance(&playerOneScore, &playerOneScore) // ❌ Erro — mesma memória, dois writes
```

> **Nota:** O mesmo vale para operadores que são funções. Se `balance` fosse um operador `<^>`, escrever `playerOneScore <^> playerOneScore` geraria o mesmo conflito.

### Regra para IA
> Nunca passe a mesma variável como dois parâmetros `inout` diferentes. Nunca acesse dentro de uma função `inout` a variável original passada como argumento. A solução é sempre **copiar antes de passar**.

---

## 3. Conflitos em Métodos `mutating` de Structs

### Por que `mutating` cria long-term access
Um método `mutating` tem **write access a `self`** durante toda a sua execução.

### Caso sem conflito: `self` e parâmetro são instâncias diferentes

```swift
struct Player {
    var name: String
    var health: Int
    var energy: Int
    static let maxHealth = 10

    mutating func restoreHealth() {
        health = Player.maxHealth  // write em self apenas
    }
}

extension Player {
    mutating func shareHealth(with teammate: inout Player) {
        balance(&teammate.health, &health)
    }
}

var oscar = Player(name: "Oscar", health: 10, energy: 10)
var maria = Player(name: "Maria", health: 5, energy: 10)

oscar.shareHealth(with: &maria) // ✅ OK — oscar e maria são memórias diferentes
```

### Caso com conflito: `self` e parâmetro são a mesma instância

```swift
oscar.shareHealth(with: &oscar)
// ❌ Erro: Conflicting accesses to oscar
// self (write) e &oscar (write) apontam para a mesma memória
```

**Por quê:** O método precisa de write access a `self` (oscar) e o parâmetro `inout` também precisa de write access ao mesmo endereço — dois writes sobrepostos na mesma memória.

### Regra para IA
> Em um método `mutating`, nunca passe `self` como argumento `inout` para si mesmo. Detecte esse padrão quando `self` e o parâmetro `inout` referenciam a mesma instância.

---

## 4. Conflitos em Propriedades

### Por que propriedades de value types conflitam
`struct`, `tuple` e `enum` são **value types**: acessar qualquer propriedade requer acesso ao **valor inteiro**. Por isso, dois acessos simultâneos a propriedades diferentes do mesmo valor ainda conflitam.

### Conflito em tuple

```swift
var playerInformation = (health: 10, energy: 20)
balance(&playerInformation.health, &playerInformation.energy)
// ❌ Erro: Conflicting access to properties of playerInformation
// Ambas as writes exigem write access ao tuple inteiro
```

### Conflito em struct global

```swift
var holly = Player(name: "Holly", health: 10, energy: 10)
balance(&holly.health, &holly.energy)
// ❌ Erro — holly é variável global
```

### Sem conflito: struct local

```swift
func someFunction() {
    var oscar = Player(name: "Oscar", health: 10, energy: 10)
    balance(&oscar.health, &oscar.energy) // ✅ OK — variável local
}
```

**Por quê:** O compilador consegue provar que o acesso é seguro quando a struct é local.

### As três condições para acesso sobreposto ser seguro

O compilador permite overlapping access a propriedades de struct **apenas quando todas as condições abaixo são verdadeiras**:

| Condição | Detalhe |
|----------|---------|
| **Stored properties apenas** | Não funciona com computed properties ou class properties |
| **Variável local** | Não funciona com variáveis globais |
| **Sem closures escapantes** | A struct não pode ser capturada por closures que escapam |

> Se o compilador **não conseguir provar** que o acesso é seguro, ele **bloqueia o acesso**.

### Regra para IA
> Ao ver um erro de conflito em propriedades, verifique se a struct está em variável global (mova para local) ou se há computed properties ou closures escapantes envolvidos. A solução mais comum é mover a variável para escopo local.

---

## Resumo: Causas e Soluções

| Causa do conflito | Solução |
|-------------------|---------|
| Variável passada como `inout` e acessada dentro da função | Fazer cópia explícita antes da chamada |
| Mesma variável em dois parâmetros `inout` | Usar variáveis distintas |
| `self` passado como `inout` em método `mutating` | Nunca passar `self` como argumento para si mesmo |
| Propriedades de tuple/struct global em múltiplos `inout` | Mover struct para variável local |
| Computed properties ou class properties sobrepostos | Reestruturar o código para evitar sobreposição |

---

## Checklist para a IA

Ao analisar ou escrever código Swift, verifique:

- [ ] Algum parâmetro `inout` é lido também dentro da função como variável global? → Copiar antes de passar
- [ ] A mesma variável aparece como dois argumentos `inout` na mesma chamada? → Separar em variáveis distintas
- [ ] Um método `mutating` recebe `self` como parâmetro `inout`? → Proibido — reestruturar
- [ ] Propriedades de struct/tuple global estão sendo passadas como `inout` simultaneamente? → Mover para variável local
- [ ] A struct é capturada por closure escapante? → O compilador não consegue provar segurança; reestruturar o acesso
- [ ] O acesso envolve computed properties? → Não há garantia de segurança pelo compilador

---

*Fonte: The Swift Programming Language — Memory Safety. © 2014–2025 Apple Inc. Licenciado sob CC BY 4.0.*