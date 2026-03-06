# Guia de Concurrency em Swift para IA

> Baseado na documentação oficial do Swift Programming Language.  
> Este guia orienta uma IA a identificar, aplicar e explicar corretamente os conceitos de concorrência em Swift.

---

## O que é Concurrency?

**Concurrency** é a combinação de código **assíncrono** e **paralelo**:

| Conceito | Descrição |
|----------|-----------|
| **Código assíncrono** | Pode ser suspenso e retomado depois. Apenas uma parte executa por vez. |
| **Código paralelo** | Múltiplas partes executam simultaneamente (ex: 4 cores = 4 tarefas ao mesmo tempo). |

O maior risco da concorrência é o **data race**: múltiplas partes do código tentando acessar o mesmo estado mutável ao mesmo tempo. Swift detecta e previne a maioria dos data races em tempo de compilação.

> **Nota:** O modelo de concorrência do Swift é construído sobre threads, mas você **não interage com elas diretamente**. Funções assíncronas podem ceder a thread que estão usando para outra função assíncrona rodar nela.

---

## 1. Funções Assíncronas (`async` / `await`)

### O que é
Uma função assíncrona pode ser **suspensa no meio da execução** enquanto espera por algo (ex: rede, disco). Diferente de funções síncronas, que rodam até o fim, lançam erro, ou nunca retornam.

### Como declarar
```swift
func listPhotos(inGallery name: String) async -> [String] {
    let result = // ... código de rede assíncrono ...
    return result
}
```

- Adicione `async` **após os parâmetros**, antes da seta `->`.
- Para função que também lança erros: `async throws` (nessa ordem).

### Como chamar
```swift
let photoNames = await listPhotos(inGallery: "Summer Vacation")
let sortedNames = photoNames.sorted()
let name = sortedNames[0]
let photo = await downloadPhoto(named: name)
show(photo)
```

- Use `await` antes de cada chamada assíncrona.
- `await` marca um **ponto de suspensão possível** — onde a execução pode pausar.
- Linhas sem `await` (como `.sorted()`) são síncronas e nunca suspendem.

### Onde `await` pode ser usado
- Dentro do corpo de outra função/método/propriedade `async`
- No método `static main()` de uma struct, class ou enum marcada com `@main`
- Em uma task filho não-estruturada (Unstructured Concurrency)

### Regra para IA
> Sempre que uma função puder demorar (rede, I/O), marque-a com `async`. Marque cada chamada a ela com `await`. **Código síncrono não pode chamar código assíncrono diretamente** — a adoção deve ser feita de cima para baixo na arquitetura.

---

## 2. Sequências Assíncronas (`for await in`)

### O que é
Permite iterar sobre elementos de uma coleção **um de cada vez**, esperando o próximo elemento ficar disponível, em vez de esperar a coleção inteira.

### Exemplo
```swift
import Foundation
let handle = FileHandle.standardInput
for try await line in handle.bytes.lines {
    print(line)
}
```

- Funciona como `for-in`, mas com `await` após o `for`.
- Suspende a execução no início de cada iteração enquanto espera o próximo elemento.
- Para usar seus próprios tipos, adicione conformidade ao protocolo `AsyncSequence`.

### Regra para IA
> Use `for await in` quando os dados chegam progressivamente (streams, arquivos grandes, eventos). Prefira isso a esperar toda a coleção de uma vez com `await`.

---

## 3. Chamadas Paralelas com `async let`

### O problema
Usar `await` sequencialmente faz as operações rodarem **uma de cada vez**, mesmo quando são independentes:

```swift
// ❌ Sequencial — cada download espera o anterior terminar
let firstPhoto = await downloadPhoto(named: photoNames[0])
let secondPhoto = await downloadPhoto(named: photoNames[1])
let thirdPhoto = await downloadPhoto(named: photoNames[2])
```

### A solução: `async let`
```swift
// ✅ Paralelo — os três downloads iniciam ao mesmo tempo
async let firstPhoto = downloadPhoto(named: photoNames[0])
async let secondPhoto = downloadPhoto(named: photoNames[1])
async let thirdPhoto = downloadPhoto(named: photoNames[2])

let photos = await [firstPhoto, secondPhoto, thirdPhoto]
show(photos)
```

- `async let` inicia a operação imediatamente, sem esperar.
- O `await` só aparece quando o **resultado é necessário**.

### Quando usar cada abordagem

| Abordagem | Quando usar |
|-----------|-------------|
| `await` direto | A próxima linha **depende** do resultado |
| `async let` | O resultado só será necessário **mais tarde** |

### Regra para IA
> Use `async let` para paralelizar operações independentes. Use `await` direto quando há dependência entre os resultados. Ambos marcam pontos de suspensão com `await`.

---

## 4. Tasks e Task Groups

### O que é uma Task
Uma **Task** é uma unidade de trabalho que pode rodar de forma assíncrona. Todo código assíncrono roda dentro de alguma Task.

### Task Groups — para trabalho dinâmico
Use quando o número de tarefas não é conhecido em tempo de compilação:

```swift
// Sem retorno — exibe cada foto ao terminar
await withTaskGroup(of: Data.self) { group in
    let photoNames = await listPhotos(inGallery: "Summer Vacation")
    for name in photoNames {
        group.addTask {
            return await downloadPhoto(named: name)
        }
    }
    for await photo in group {
        show(photo)
    }
}

// Com retorno — coleta todos os resultados
let photos = await withTaskGroup(of: Data.self) { group in
    let photoNames = await listPhotos(inGallery: "Summer Vacation")
    for name in photoNames {
        group.addTask {
            return await downloadPhoto(named: name)
        }
    }
    var results: [Data] = []
    for await photo in group {
        results.append(photo)
    }
    return results
}
```

> Para funções que podem lançar erros, use `withThrowingTaskGroup(of:returning:body:)`.

### Vantagens da hierarquia de Tasks (Structured Concurrency)

| Vantagem | Descrição |
|----------|-----------|
| Completude garantida | A task pai não pode esquecer de esperar as filhas |
| Prioridade escalada | Aumentar prioridade de uma filha escalona a pai automaticamente |
| Cancelamento em cascata | Cancelar a pai cancela todas as filhas automaticamente |
| Task-local values | Propagam para filhas automaticamente |

### Regra para IA
> Use `withTaskGroup` quando o número de operações paralelas é dinâmico (ex: iterar sobre uma lista). Use `async let` quando o número é fixo e conhecido.

---

## 5. Cancelamento de Tasks

### Modelo cooperativo
O Swift usa cancelamento **cooperativo**: a task precisa verificar e responder ao cancelamento por conta própria.

### Formas de responder ao cancelamento

| Resposta | Quando usar |
|----------|-------------|
| Lançar `CancellationError` | Quando quer parar imediatamente |
| Retornar `nil` ou coleção vazia | Quando prefere resultado parcial |
| Retornar trabalho parcialmente completo | Para não perder o progresso já feito |

### Como verificar cancelamento

```swift
// Lança erro automaticamente se cancelada
Task.checkCancellation()

// Permite lógica customizada de limpeza
if Task.isCancelled {
    // fechar conexões, deletar arquivos temporários, etc.
    return nil
}
```

### Evitar adicionar novas tasks após cancelamento
```swift
let added = group.addTaskUnlessCancelled {
    Task.isCancelled ? nil : await downloadPhoto(named: name)
}
guard added else { break }
```

### Cancelamento com handler imediato
```swift
let task = await Task.withTaskCancellationHandler {
    // ... trabalho principal ...
} onCancel: {
    print("Cancelado!")
}
task.cancel() // Dispara o handler imediatamente
```

> **Atenção:** Evite compartilhar estado entre a task e o handler de cancelamento — isso pode criar race conditions.

### Regra para IA
> Sempre implemente verificação de cancelamento em tarefas longas. Prefira `addTaskUnlessCancelled` em loops que adicionam tasks. Use `checkCancellation()` para simplicidade, `isCancelled` para limpeza customizada.

---

## 6. Concorrência Não-Estruturada (Unstructured Concurrency)

### Quando usar
Quando você precisa de flexibilidade total e a task **não tem um pai natural**.

### Dois tipos

| Tipo | Método | Herda contexto? |
|------|--------|----------------|
| Task comum | `Task { }` | Sim — herda isolamento de ator, prioridade e task-locals |
| Detached task | `Task.detached { }` | Não — começa completamente independente |

```swift
// Task comum — herda o contexto atual
let handle = Task {
    return await add(newPhoto, toGalleryNamed: "Spring Adventures")
}
let result = await handle.value

// Detached task — sem herança de contexto
Task.detached(priority: .background) {
    await processInBackground()
}
```

### Regra para IA
> Prefira sempre **structured concurrency** (`async let`, `TaskGroup`). Use `Task { }` apenas quando precisar de flexibilidade. Use `Task.detached` com cautela — você perde cancelamento automático e propagação de prioridade.

---

## 7. Isolamento e Atores

### O problema: Data Races
Quando múltiplas tasks modificam o mesmo dado simultaneamente, o resultado é imprevisível.

### Três formas de isolar dados

| Forma | Descrição |
|-------|-----------|
| **Dados imutáveis** (`let`) | Constantes nunca têm race conditions |
| **Dados locais da task** | Variáveis locais não são acessíveis de fora |
| **Dados protegidos por ator** | Apenas código do mesmo ator acessa simultaneamente |

### Actors

```swift
actor TemperatureLogger {
    let label: String
    var measurements: [Int]
    private(set) var max: Int

    init(label: String, measurement: Int) {
        self.label = label
        self.measurements = [measurement]
        self.max = measurement
    }
}
```

- Declare com a keyword `actor`.
- São **reference types** (como classes), mas permitem apenas **uma task por vez** acessar o estado mutável.
- Acesso externo requer `await`:

```swift
let logger = TemperatureLogger(label: "Outdoors", measurement: 25)
print(await logger.max) // await obrigatório de fora do ator
```

- Acesso interno **não requer** `await`:

```swift
extension TemperatureLogger {
    func update(with measurement: Int) {
        measurements.append(measurement)  // sem await — já está no ator
        if measurement > max {
            max = measurement
        }
    }
}
```

- Tentar acessar sem `await` de fora gera **erro de compilação**:

```swift
print(logger.max) // ❌ Erro de compilação
```

### Regra para IA
> Use `actor` para proteger qualquer estado mutável compartilhado. Lembre que dentro do ator não é necessário `await`. Fora do ator, todo acesso a propriedades/métodos exige `await`.

---

## 8. O Main Actor (`@MainActor`)

### O que é
O **main actor** é um singleton global que serializa acesso ao estado da UI. Todo código que toca a interface deve rodar nele.

### Como marcar

```swift
// Função sempre roda no main actor
@MainActor
func show(_ photo: Data) {
    // código de UI
}

// Closure no main actor
Task { @MainActor in
    show(photo)
}

// Tipo inteiro no main actor
@MainActor
struct PhotoGallery {
    var photoNames: [String]
    func drawUI() { /* ... */ }
}

// Apenas membros específicos
struct PhotoGallery {
    @MainActor var photoNames: [String]       // afeta UI
    var hasCachedPhotos = false               // não afeta UI
    @MainActor func drawUI() { /* ... */ }    // afeta UI
    func cachePhotos() { /* ... */ }          // não afeta UI
}
```

- Chamar uma função `@MainActor` de fora do main actor requer `await`.
- Frameworks como SwiftUI já marcam seus protocolos/base classes com `@MainActor` — tipos que conformam herdam isso implicitamente.

### Padrão comum
```swift
func downloadAndShowPhoto(named name: String) async {
    let photo = await downloadPhoto(named: name)  // roda fora do main actor
    await show(photo)                              // chama @MainActor, suspende
}
```

### Regra para IA
> Marque com `@MainActor` qualquer código que lê ou escreve estado da UI. Faça o trabalho pesado (rede, CPU) fora do main actor e só chame `@MainActor` para atualizar a interface.

---

## 9. Tipos Sendable

### O que é
Um tipo **Sendable** pode ser passado com segurança entre domínios de concorrência (entre tasks e atores).

### Três formas de ser Sendable

| Forma | Exemplo |
|-------|---------|
| Value type com propriedades sendable | `struct` com `Int`, `String`, etc. |
| Tipo sem estado mutável | struct/class só com `let` |
| Tipo que serializa acesso | classe marcada `@MainActor` ou que usa filas |

```swift
// Conformidade explícita
struct TemperatureReading: Sendable {
    var measurement: Int
}

// Conformidade implícita (struct com props sendable, não public)
struct TemperatureReading {
    var measurement: Int
    // implicitamente Sendable
}

// Marcando explicitamente como NÃO sendable
@available(*, unavailable)
extension FileDescriptor: Sendable {}
```

### Regra para IA
> Prefira `struct` e `enum` com valores sendable para dados trocados entre tasks. Evite passar classes com estado mutável sem proteção entre domínios de concorrência.

---

## Resumo: Quando usar cada recurso

| Situação | Recurso |
|----------|---------|
| Função que pode demorar | `async` + `await` |
| Dados chegam progressivamente | `for await in` + `AsyncSequence` |
| Operações independentes em paralelo (número fixo) | `async let` |
| Operações paralelas em quantidade dinâmica | `TaskGroup` |
| Task sem pai natural | `Task { }` ou `Task.detached { }` |
| Proteger estado mutável compartilhado | `actor` |
| Código que toca a UI | `@MainActor` |
| Dados trocados entre tasks/atores | `Sendable` |
| Parar trabalho em andamento | `Task.checkCancellation()` / `isCancelled` |

---

## Checklist para a IA

Antes de escrever ou revisar código concorrente em Swift:

- [ ] A função pode demorar (rede, I/O)? → Marque com `async`, chame com `await`
- [ ] As operações são independentes entre si? → Use `async let` ou `TaskGroup`
- [ ] O número de tasks é dinâmico? → Use `TaskGroup`
- [ ] A task pode ser cancelada? → Implemente `checkCancellation()` ou verifique `isCancelled`
- [ ] Há estado mutável compartilhado? → Proteja com `actor`
- [ ] O código toca a UI? → Marque com `@MainActor`
- [ ] O tipo é passado entre tasks/atores? → Confirme conformidade com `Sendable`
- [ ] Você está chamando `async` de código síncrono? → Não é possível diretamente; converta de cima para baixo

---

*Fonte: The Swift Programming Language — Concurrency. © 2014–2025 Apple Inc. Licenciado sob CC BY 4.0.*