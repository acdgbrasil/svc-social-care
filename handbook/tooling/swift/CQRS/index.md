# 🧠 Guia CQRS para Swift — Como Aplicar, O Que Fazer e O Que Evitar

> **Público-alvo:** Desenvolvedores e IAs que precisam entender, sugerir ou implementar CQRS em projetos Swift — iOS, macOS, Vapor/backend, etc.

---

## 📖 O Que é CQRS?

**CQRS** (Command Query Responsibility Segregation) é um padrão arquitetural que **separa as responsabilidades de escrita e leitura** em dois modelos distintos.

- **Command (Comando):** Muda o estado do sistema. Não retorna dados de negócio.
- **Query (Consulta):** Lê o estado do sistema. Não muda nada.

> 💡 Em Swift, a separação é reforçada pelos próprios mecanismos da linguagem: protocolos com `associatedtype`, `some`/`any` para ocultar ou flexibilizar tipos, `actor` para isolamento de estado, e `async/await` para operações assíncronas.

### Diagrama Mental

```
CQS (princípio geral — método não faz as duas coisas ao mesmo tempo)
         ↓
CQRS (padrão de design — pipelines separadas)
    ↙                           ↘
Commands                      Queries
(Write Model)                 (Read Model)
protocol Command: Sendable    protocol Query: Sendable
actor CommandHandler          struct QueryHandler
mutating / throws             async / pure / some Result
```

---

## ⚙️ Componentes Principais — Versão Swift

| Componente | Papel | Idioma Swift |
|---|---|---|
| **Command** | Intenção de mudança. Imperativo: `RegisterUser`, `PlaceOrder`. | `struct` imutável conformando `Command` |
| **CommandHandler** | Valida e executa. Contém lógica de escrita. | `actor` com `func handle(_:) async throws` |
| **Query** | Pedido de informação. Não muda estado. | `struct` imutável conformando `Query` |
| **QueryHandler** | Busca e retorna dados otimizados. | `struct` com `func handle(_:) async throws -> Q.Result` |
| **Event** | Fato imutável ocorrido no domínio. Passado: `UserRegistered`. | `struct` conformando `DomainEvent & Sendable` |
| **CommandBus** | Roteia commands para seus handlers. | `actor` com dispatch via `switch`/pattern matching |
| **Write Store** | Banco otimizado para escrita. | `actor` isolado |
| **Read Store** | Banco otimizado para leitura. | `protocol` — pode ser cache, DB ou replica |

---

## ✅ O QUE FAZER

### 1. Definir os protocolos base com `associatedtype` e herança correta

Protocolos que descrevem *o que algo é* usam substantivos (`Command`, `Query`). Protocolos com capacidade usam sufixos `-able`/`-ing` (`Cancellable`, `Dispatchable`). Toda propriedade em protocol usa `var`, nunca `let`:

```swift
// Marca operações de escrita — nomeado como substantivo
protocol Command: Sendable {}

// Command que produz um valor (ex: retorna o ID criado)
// associatedtype com : Sendable garante segurança de concorrência
protocol ResultCommand: Sendable {
    associatedtype Result: Sendable
}

// Marca operações de leitura — associatedtype define o tipo de retorno
protocol Query: Sendable {
    associatedtype Result: Sendable
}

// Handler de escrita: sempre actor, async throws, nunca retorna dados de domínio
protocol CommandHandling<C>: Actor {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

// Handler de leitura: struct pura, sempre async, nunca muta estado
protocol QueryHandling<Q> {
    associatedtype Q: Query
    func handle(_ query: Q) async throws -> Q.Result
}

// Evento de domínio — fato imutável, nomeado no passado
protocol DomainEvent: Sendable {
    var occurredAt: Date { get }  // var (não let) — requisito de protocol
}
```

> **Por quê `Actor` como herança de `CommandHandling`?** O protocol herdar de `Actor` garante que qualquer conformante será um `actor`, obtendo isolamento automático. Essa é a forma idiomática de expressar "este protocolo exige reference semantics com exclusão mútua".

> **Por quê `Sendable` em `Command` e `Query`?** Commands e Queries trafegam entre domínios de concorrência — do `@MainActor` para o `actor` de domínio. Marcar como `Sendable` é detectado pelo compilador em tempo de build, não em runtime.

---

### 2. Commands como `struct` — Swift sintetiza `Sendable` e `Equatable` gratuitamente

Quando todas as propriedades são `Sendable` e `Equatable`, Swift gera as conformidades automaticamente. Nunca implemente manualmente o que o compilador já sintetiza:

```swift
// ✅ Swift sintetiza Sendable automaticamente (UUID, String são Sendable)
struct PlaceOrderCommand: Command {
    let customerId: UUID
    let items: [OrderItem]  // OrderItem também deve ser Sendable
}

// ✅ Equatable sintetizado — útil para testes e deduplicação
struct CompleteTodoCommand: Command, Equatable {
    let todoItemId: UUID
    // NÃO escreva == manualmente — Swift gera comparação campo a campo
}

struct RegisterUserCommand: Command {
    let email: String
    let name: String
}
```

```swift
// ❌ Errado — CRUD genérico não expressa intenção de negócio
struct UpdateUserCommand: Command {
    let id: UUID
    var email: String?   // var em command é sinal de CRUD disfarçado
    var name: String?
    var isActive: Bool?
}

// ❌ Errado — implementar Equatable manualmente quando Swift pode sintetizar
struct BadCommand: Command, Equatable {
    let id: UUID
    static func == (lhs: BadCommand, rhs: BadCommand) -> Bool {
        lhs.id == rhs.id  // desnecessário — Swift já faria isso
    }
}
```

---

### 3. Proteger o write store com `actor` e expor interface via `some`

`actor` garante exclusão mútua. Use `some` no retorno de factory methods para ocultar o tipo concreto do store sem custo de boxing:

```swift
actor OrderStore {
    private var orders: [UUID: Order] = [:]

    func add(_ order: Order) {
        orders[order.id] = order
    }

    func find(by id: UUID) -> Order? {
        orders[id]
    }

    func all() -> [Order] {
        Array(orders.values)
    }
}

// Factory function — `some` oculta o tipo concreto (OrderStore)
// Se o store mudar de implementação, a assinatura pública não quebra
func makeOrderStore() -> some Actor {
    OrderStore()
}
```

```swift
// ❌ Errado — classe sem proteção → data race potencial
class UnsafeOrderStore {
    var orders: [UUID: Order] = [:]  // mutable, sem exclusão mútua
}
```

---

### 4. CommandHandler como `actor` — `mutating` não existe em classes/actors

Em Swift, `mutating` é exclusivo de `struct` e `enum`. Actors modificam estado interno diretamente. O protocol `CommandHandling` herdar de `Actor` torna isso explícito e verificado pelo compilador:

```swift
actor PlaceOrderCommandHandler: CommandHandling {
    typealias C = PlaceOrderCommand

    private let orderStore: OrderStore
    private let inventoryService: InventoryService
    private let eventBus: EventBus

    init(orderStore: OrderStore, inventoryService: InventoryService, eventBus: EventBus) {
        self.orderStore = orderStore
        self.inventoryService = inventoryService
        self.eventBus = eventBus
    }

    // ✅ async throws — idiomático Swift para falha comunicada via throw
    func handle(_ command: PlaceOrderCommand) async throws {
        guard !command.items.isEmpty else {
            throw OrderError.invalidItemQuantity
        }

        // Verificação paralela de estoque — TaskGroup para quantidade dinâmica
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in command.items {
                group.addTaskUnlessCancelled {  // respeita cancelamento
                    guard await self.inventoryService.hasStock(
                        for: item.productId,
                        quantity: item.quantity
                    ) else {
                        throw OrderError.insufficientStock(item.productId)
                    }
                }
            }
        }

        let order = Order.create(customerId: command.customerId, items: command.items)
        await orderStore.add(order)
        await eventBus.publish(OrderPlacedEvent(orderId: order.id, customerId: order.customerId))
    }
}
```

---

### 5. QueryHandler como `struct` puro — default implementation via protocol extension

Queries sem estado não precisam de `actor`. Use **protocol extensions** para fornecer comportamento padrão (ex: logging, validação) sem tocar nos handlers concretos:

```swift
struct GetUserOrdersQuery: Query {
    typealias Result = [OrderSummary]
    let userId: UUID
}

struct GetUserOrdersQueryHandler: QueryHandling {
    typealias Q = GetUserOrdersQuery

    private let readStore: OrderReadStore

    // ✅ Retorna [OrderSummary] — tipo concreto, Q.Result já define isso
    func handle(_ query: GetUserOrdersQuery) async throws -> [OrderSummary] {
        try await readStore.fetchOrders(for: query.userId)
            .sorted { $0.placedAt > $1.placedAt }
    }
}

// ✅ Protocol extension adiciona comportamento a TODOS os QueryHandlers
// sem modificar nenhum handler concreto (open/closed principle)
extension QueryHandling {
    func handleWithLogging(_ query: Q) async throws -> Q.Result {
        print("▶ Query: \(type(of: query))")
        let result = try await handle(query)
        print("✓ Query \(type(of: query)) concluída")
        return result
    }
}
```

---

### 6. Usar `some` no retorno de factories de handlers para ocultar implementação

`some` é zero-cost (sem boxing) e preserva a identidade de tipo para o compilador. Use quando o handler sempre retorna o mesmo tipo concreto mas você quer liberdade para mudar internamente:

```swift
// ✅ some oculta que é GetUserOrdersQueryHandler — pode trocar a implementação
// sem quebrar os chamadores
func makeOrdersHandler(readStore: OrderReadStore) -> some QueryHandling<GetUserOrdersQuery> {
    GetUserOrdersQueryHandler(readStore: readStore)
}

// Chamador não sabe o tipo concreto — só sabe que é QueryHandling<GetUserOrdersQuery>
let handler = makeOrdersHandler(readStore: .shared)
let orders = try await handler.handle(GetUserOrdersQuery(userId: userId))
```

```swift
// ❌ Errado — tipo concreto exposto, qualquer mudança interna quebra chamadores
func makeOrdersHandler(readStore: OrderReadStore) -> GetUserOrdersQueryHandler {
    GetUserOrdersQueryHandler(readStore: readStore)
}
```

---

### 7. Usar `any` para coleções heterogêneas de eventos no EventBus

Quando o EventBus precisa propagar eventos de tipos diferentes, `any` é a escolha correta. Ao receber, faça downcast seguro com `as?`:

```swift
// ✅ EventBus armazena closures para qualquer DomainEvent — coleção heterogênea
actor EventBus {
    // [any DomainEvent] pode conter OrderPlacedEvent, UserRegisteredEvent, etc.
    private var handlers: [String: [(any DomainEvent) async -> Void]] = [:]

    func subscribe<E: DomainEvent>(
        to eventType: E.Type,
        handler: @escaping (E) async -> Void
    ) {
        let key = String(describing: eventType)
        handlers[key, default: []].append { event in
            if let typedEvent = event as? E {  // ✅ downcast seguro com as?
                await handler(typedEvent)
            }
        }
    }

    func publish<E: DomainEvent>(_ event: E) async {
        let key = String(describing: E.self)
        for handler in handlers[key] ?? [] {
            await handler(event)
        }
    }
}
```

```swift
// ❌ Errado — any não preserva identidade, == falha em compile time
let a: any DomainEvent = OrderPlacedEvent(...)
let b: any DomainEvent = OrderPlacedEvent(...)
a == b  // ❌ Erro de compilação — any DomainEvent não tem ==

// ❌ Errado — any não pode ser passado como argumento genérico
func process<E: DomainEvent>(_ event: E) { }
let event: any DomainEvent = OrderPlacedEvent(...)
process(event)  // ❌ "Type 'any DomainEvent' cannot conform to 'DomainEvent'"
```

---

### 8. Despachar Commands com pattern matching — exhaustiveness garantida pelo compilador

Enum com associated values + `switch` é o roteamento mais seguro e idiomático do Swift. Esquecer um case vira erro de compilação, não bug em runtime:

```swift
// ✅ Enum representa todos os commands — exhaustiveness verificada em compile time
enum AppCommand: Sendable {
    case placeOrder(PlaceOrderCommand)
    case completeTodo(CompleteTodoCommand)
    case registerUser(RegisterUserCommand)
}

actor CommandBus {
    private let placeOrderHandler: PlaceOrderCommandHandler
    private let completeTodoHandler: CompleteTodoCommandHandler
    private let registerUserHandler: RegisterUserCommandHandler

    func dispatch(_ command: AppCommand) async throws {
        switch command {
        case .placeOrder(let cmd):    try await placeOrderHandler.handle(cmd)
        case .completeTodo(let cmd):  try await completeTodoHandler.handle(cmd)
        case .registerUser(let cmd):  try await registerUserHandler.handle(cmd)
        // ✅ Esquecer um case → erro de compilação, não bug silencioso em runtime
        }
    }
}
```

---

### 9. Delegation para notificar a UI após Commands — `AnyObject` + `weak`

O padrão Delegation em Swift exige que delegates sejam `AnyObject` (class-only) para permitir `weak`. Isso evita retain cycles entre ViewModel e CommandBus:

```swift
// ✅ Protocol de delegate: AnyObject = class-only = permite weak
protocol OrdersDelegate: AnyObject {
    func ordersDidChange()
    func commandDidFail(with error: Error)
}

actor CommandBus {
    weak var delegate: OrdersDelegate?  // ✅ weak — evita retain cycle

    func dispatch(_ command: AppCommand) async throws {
        do {
            // ... executa o handler ...
            await delegate?.ordersDidChange()        // ✅ optional chaining — delegate pode ser nil
        } catch {
            await delegate?.commandDidFail(with: error)
            throw error
        }
    }
}

// ✅ ViewModel adota o delegate — referência fraca no CommandBus
@MainActor
@Observable
final class OrdersViewModel: OrdersDelegate {
    nonisolated func ordersDidChange() {
        Task { @MainActor in await self.loadOrders() }
    }
    nonisolated func commandDidFail(with error: Error) {
        Task { @MainActor in self.errorMessage = error.localizedDescription }
    }
}
```

```swift
// ❌ Errado — delegate sem AnyObject → não pode ser weak → retain cycle
protocol BadDelegate {
    func ordersDidChange()
}
actor CommandBus {
    var delegate: BadDelegate?  // ❌ sem weak — retain cycle com o ViewModel!
}
```

---

### 10. Protocol composition para handlers com múltiplas capacidades

Use `&` para combinar protocols sem criar protocol intermediário desnecessário:

```swift
protocol Loggable {
    var logIdentifier: String { get }
}

// ✅ Composição direta com & — sem criar LoggableCommandHandling intermediário
func monitor(_ handler: some CommandHandling<PlaceOrderCommand> & Loggable) {
    print("Monitorando: \(handler.logIdentifier)")
}

// ✅ Actor que satisfaz a composição
actor PlaceOrderCommandHandler: CommandHandling, Loggable {
    typealias C = PlaceOrderCommand
    let logIdentifier = "PlaceOrderHandler"

    func handle(_ command: PlaceOrderCommand) async throws { /* ... */ }
}

monitor(PlaceOrderCommandHandler(...))  // ✅ satisfaz CommandHandling<PlaceOrderCommand> & Loggable
```

```swift
// ❌ Protocol intermediário desnecessário — apenas combina dois sem adicionar nada
protocol LoggableCommandHandling: CommandHandling, Loggable { }  // ❌ sem valor
// ✅ Use diretamente: some CommandHandling<C> & Loggable
```

---

### 11. Usar `async let` para paralelizar buscas independentes em Queries

```swift
struct GetProductDetailQuery: Query {
    typealias Result = ProductDetail
    let productId: UUID
}

struct GetProductDetailQueryHandler: QueryHandling {
    typealias Q = GetProductDetailQuery

    func handle(_ query: GetProductDetailQuery) async throws -> ProductDetail {
        // ✅ async let — três buscas independentes rodam em paralelo
        async let product    = readStore.fetchProduct(id: query.productId)
        async let stockLevel = inventoryStore.fetchStock(for: query.productId)
        async let reviews    = reviewStore.fetchTopReviews(for: query.productId)

        return try await ProductDetail(product: product, stockLevel: stockLevel, reviews: reviews)
    }
}
```

```swift
// ❌ Sequencial desnecessário — três round-trips onde um round seria suficiente
let product    = try await readStore.fetchProduct(id: query.productId)
let stockLevel = try await inventoryStore.fetchStock(for: query.productId)
let reviews    = try await reviewStore.fetchTopReviews(for: query.productId)
```

---

### 12. Injetar handlers com `some` no `init`, armazenar como `any` na propriedade

`some` no parâmetro do `init` é syntax sugar para genérico — garante type safety no call site. `any` na propriedade permite armazenar tipos diferentes (útil para mocks em testes):

```swift
@MainActor
@Observable
final class OrdersViewModel {
    var orders: [OrderSummary] = []
    var isLoading = false
    var errorMessage: String?

    // any na propriedade — permite mock em testes sem genérico no ViewModel
    private let queryHandler: any QueryHandling<GetUserOrdersQuery>
    private let commandBus: CommandBus

    // some no init — type-safe na injeção, sem expor genérico na classe
    init(
        queryHandler: some QueryHandling<GetUserOrdersQuery>,
        commandBus: CommandBus
    ) {
        self.queryHandler = queryHandler  // armazenado como any
        self.commandBus = commandBus
    }

    func loadOrders(for customerId: UUID) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                orders = try await queryHandler.handle(GetUserOrdersQuery(userId: customerId))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func placeOrder(customerId: UUID, items: [OrderItem]) {
        Task {
            do {
                try await commandBus.dispatch(.placeOrder(
                    PlaceOrderCommand(customerId: customerId, items: items)
                ))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

---

## ❌ O QUE NÃO FAZER

### ❌ 1. Query que muda estado do sistema

```swift
// ❌ Errado — Query com efeito colateral viola CQRS
struct GetProductQueryHandler: QueryHandling {
    typealias Q = GetProductQuery

    func handle(_ query: GetProductQuery) async throws -> ProductDto {
        var product = try await readStore.fetch(id: query.productId)
        product.viewCount += 1               // ← escrita dentro de leitura!
        try await writeStore.save(product)   // ← efeito colateral em query!
        return ProductDto(from: product)
    }
}

// ✅ Correto — Query pura + Command separado e assíncrono
struct GetProductQueryHandler: QueryHandling {
    typealias Q = GetProductQuery

    func handle(_ query: GetProductQuery) async throws -> ProductDto {
        let product = try await readStore.fetch(id: query.productId)
        return ProductDto(from: product)
    }
}

struct TrackProductViewCommand: Command {
    let productId: UUID
}
// Dispare TrackProductViewCommand fire-and-forget após a query
```

---

### ❌ 2. CommandHandler retornando o objeto completo (query embutida no command)

```swift
// ❌ Errado — mistura responsabilidades
actor CreateUserCommandHandler {
    func handle(_ command: RegisterUserCommand) async throws -> UserDto {
        let user = User(name: command.name, email: command.email)
        try await repository.save(user)
        return UserDto(id: user.id, name: user.name, email: user.email)  // ← Query embutida!
    }
}

// ✅ Correto — command retorna apenas o identificador
actor CreateUserCommandHandler: CommandHandling {
    typealias C = RegisterUserCommand

    func handle(_ command: RegisterUserCommand) async throws -> UUID {
        let user = User(name: command.name, email: command.email)
        try await repository.save(user)
        return user.id  // ✅ apenas o ID
    }
}
// Se precisar dos dados completos: chame GetUserQuery(userId: id) depois
```

---

### ❌ 3. Usar `any` onde `some` seria correto — boxing desnecessário

```swift
// ❌ Errado — any cria boxing (indireção em runtime) desnecessário
func makeQueryHandler() -> any QueryHandling<GetUserOrdersQuery> {
    GetUserOrdersQueryHandler(readStore: .shared)
    // Sempre retorna o mesmo tipo — some seria mais eficiente
}

// ✅ Correto — some é zero-cost e preserva type identity
func makeQueryHandler() -> some QueryHandling<GetUserOrdersQuery> {
    GetUserOrdersQueryHandler(readStore: .shared)
}

// ✅ any é correto quando há heterogeneidade real em runtime
var handlers: [any QueryHandling<GetUserOrdersQuery>] = [cachedHandler, fallbackHandler]
```

---

### ❌ 4. Tentar usar `any Protocol` com `associatedtype` como return type direto

```swift
// ❌ Erro de compilação — protocols com associatedtype não podem ser return type como any
func makeHandler() -> any Query { }  // ❌ "Type 'any Query' cannot conform to 'Query'"

// ✅ Correto — some funciona com associatedtype (compiler conhece o tipo concreto)
func makeHandler() -> some QueryHandling<GetUserOrdersQuery> {
    GetUserOrdersQueryHandler(readStore: .shared)
}

// ✅ Ou use genérico nomeado para constraints complexas com where
func execute<H: QueryHandling>(_ handler: H, query: H.Q) async throws -> H.Q.Result {
    try await handler.handle(query)
}
```

---

### ❌ 5. Tentar encadear `any Protocol` como argumento genérico

```swift
// ❌ any não pode ser passado como argumento onde T: Protocol é esperado
func process<C: Command>(_ command: C) { }
let cmd: any Command = PlaceOrderCommand(...)
process(cmd)  // ❌ "Type 'any Command' cannot conform to 'Command'"

// ✅ Use some em parâmetros para encadear transformações
func process(_ command: some Command) { }  // some = syntax sugar para genérico
process(PlaceOrderCommand(...))  // ✅ funciona
```

---

### ❌ 6. Delegate sem `AnyObject` — retain cycle silencioso

```swift
// ❌ Protocol sem AnyObject — não pode ser weak → retain cycle
protocol BadOrdersDelegate {
    func ordersDidChange()
}

actor CommandBus {
    var delegate: BadOrdersDelegate?  // ❌ não pode ser weak → memória vazada
}

// ✅ Correto
protocol OrdersDelegate: AnyObject {  // ✅ AnyObject = permite weak
    func ordersDidChange()
    func commandDidFail(with error: Error)
}

actor CommandBus {
    weak var delegate: OrdersDelegate?  // ✅ weak — sem retain cycle
}
```

---

### ❌ 7. Protocol intermediário que apenas combina dois (use `&`)

```swift
// ❌ Desnecessário — apenas combina, não adiciona comportamento
protocol LoggableCommandHandling: CommandHandling, Loggable { }

// ✅ Composição direta é mais idiomática e não polui o namespace de tipos
func monitor(_ handler: some CommandHandling<PlaceOrderCommand> & Loggable) { }
```

---

### ❌ 8. Implementar manualmente `Equatable`/`Sendable` que Swift sintetizaria

```swift
// ❌ Desnecessário — Swift sintetiza == campo a campo para structs com props Equatable
struct PlaceOrderCommand: Command, Equatable {
    let customerId: UUID
    let items: [OrderItem]

    static func == (lhs: PlaceOrderCommand, rhs: PlaceOrderCommand) -> Bool {
        lhs.customerId == rhs.customerId && lhs.items == rhs.items  // ❌ Swift já faria isso
    }
}

// ✅ Correto — declare a conformidade e deixe Swift gerar
struct PlaceOrderCommand: Command, Equatable {
    let customerId: UUID
    let items: [OrderItem]
    // Swift gera == automaticamente ✅
}
```

---

### ❌ 9. Ignorar cancelamento em Commands/Queries de longa duração

```swift
// ❌ Errado — ignora sinal de cancelamento
actor ProcessBulkOrdersHandler: CommandHandling {
    typealias C = ProcessBulkOrdersCommand

    func handle(_ command: ProcessBulkOrdersCommand) async throws {
        for order in command.orders {
            try await processOrder(order)  // sem verificar cancelamento
        }
    }
}

// ✅ Correto — verifica cancelamento a cada iteração
actor ProcessBulkOrdersHandler: CommandHandling {
    typealias C = ProcessBulkOrdersCommand

    func handle(_ command: ProcessBulkOrdersCommand) async throws {
        for order in command.orders {
            try Task.checkCancellation()   // lança CancellationError se necessário
            try await processOrder(order)
        }
    }
}
```

---

## 🏗️ Exemplo Prático Completo: Livraria Online em Swift

### Protocolos Base com Protocol Extension

```swift
protocol Command: Sendable {}
protocol Query: Sendable { associatedtype Result: Sendable }
protocol DomainEvent: Sendable { var occurredAt: Date { get } }

protocol CommandHandling<C>: Actor {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

protocol QueryHandling<Q> {
    associatedtype Q: Query
    func handle(_ query: Q) async throws -> Q.Result
}

// ✅ Protocol extension — logging grátis para TODOS os QueryHandlers
// sem modificar nenhum handler concreto
extension QueryHandling {
    func handleWithLogging(_ query: Q) async throws -> Q.Result {
        print("▶ \(type(of: query))")
        defer { print("✓ \(type(of: query)) concluída") }
        return try await handle(query)
    }
}
```

### Erros de Domínio

```swift
enum OrderError: Error {
    case invalidItemQuantity
    case insufficientStock(UUID)
    case customerNotFound(UUID)
}
```

### Command Side (Escrita)

```swift
// 1. Command — struct imutável, Sendable sintetizado
struct PlaceOrderCommand: Command {
    let customerId: UUID
    let items: [OrderItem]
}

// 2. Aggregate — value type com factory method
struct Order {
    let id: UUID
    let customerId: UUID
    let items: [OrderItem]
    let placedAt: Date

    static func create(customerId: UUID, items: [OrderItem]) -> Order {
        Order(id: UUID(), customerId: customerId, items: items, placedAt: Date())
    }
}

// 3. Evento — struct Sendable nomeada no passado
struct OrderPlacedEvent: DomainEvent {
    let orderId: UUID
    let customerId: UUID
    let occurredAt: Date
}

// 4. Command Handler — actor com verificação paralela de estoque
actor PlaceOrderCommandHandler: CommandHandling {
    typealias C = PlaceOrderCommand

    private let orderStore: OrderStore
    private let inventoryService: InventoryService
    private let eventBus: EventBus

    func handle(_ command: PlaceOrderCommand) async throws {
        guard !command.items.isEmpty else { throw OrderError.invalidItemQuantity }

        // TaskGroup — quantidade de items dinâmica, verificação paralela
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in command.items {
                group.addTaskUnlessCancelled {
                    guard await self.inventoryService.hasStock(
                        for: item.productId, quantity: item.quantity
                    ) else { throw OrderError.insufficientStock(item.productId) }
                }
            }
        }

        let order = Order.create(customerId: command.customerId, items: command.items)
        await orderStore.add(order)
        await eventBus.publish(OrderPlacedEvent(
            orderId: order.id,
            customerId: order.customerId,
            occurredAt: order.placedAt
        ))
    }
}
```

### Query Side (Leitura)

```swift
// 1. Query e seu Result
struct GetOrderHistoryQuery: Query {
    typealias Result = [OrderSummary]
    let customerId: UUID
}

// 2. DTO — Sendable e Equatable sintetizados (não escreva manualmente)
struct OrderSummary: Sendable, Equatable {
    let id: UUID
    let total: Decimal
    let status: OrderStatus
    let placedAt: Date
}

// 3. Query Handler — struct pura, sem estado mutável
struct GetOrderHistoryQueryHandler: QueryHandling {
    typealias Q = GetOrderHistoryQuery

    private let readStore: OrderReadStore

    func handle(_ query: GetOrderHistoryQuery) async throws -> [OrderSummary] {
        try await readStore.fetchOrders(for: query.customerId)
            .sorted { $0.placedAt > $1.placedAt }
    }
}
```

### CommandBus e ViewModel Completos

```swift
// Enum AppCommand — pattern matching com exhaustiveness garantida
enum AppCommand: Sendable {
    case placeOrder(PlaceOrderCommand)
    case completeTodo(CompleteTodoCommand)
    case registerUser(RegisterUserCommand)
}

// Delegate — AnyObject para permitir weak
protocol OrdersDelegate: AnyObject {
    func ordersDidChange()
    func commandDidFail(with error: Error)
}

// CommandBus — actor com delegate weak
actor CommandBus {
    weak var delegate: OrdersDelegate?

    func dispatch(_ command: AppCommand) async throws {
        do {
            switch command {
            case .placeOrder(let cmd):    try await placeOrderHandler.handle(cmd)
            case .completeTodo(let cmd):  try await completeTodoHandler.handle(cmd)
            case .registerUser(let cmd):  try await registerUserHandler.handle(cmd)
            }
            await delegate?.ordersDidChange()
        } catch {
            await delegate?.commandDidFail(with: error)
            throw error
        }
    }
}

// ViewModel — @MainActor, some no init / any na propriedade
@MainActor
@Observable
final class OrdersViewModel: OrdersDelegate {
    var orders: [OrderSummary] = []
    var isLoading = false
    var errorMessage: String?

    private let queryHandler: any QueryHandling<GetUserOrdersQuery>
    private let commandBus: CommandBus

    init(
        queryHandler: some QueryHandling<GetUserOrdersQuery>,  // some = type-safe na injeção
        commandBus: CommandBus
    ) {
        self.queryHandler = queryHandler   // armazenado como any
        self.commandBus = commandBus
        commandBus.delegate = self         // weak no CommandBus — sem retain cycle
    }

    func loadOrders(for customerId: UUID) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                orders = try await queryHandler.handle(GetUserOrdersQuery(userId: customerId))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Chamado pelo delegate quando command bem-sucedido altera o estado
    nonisolated func ordersDidChange() {
        Task { @MainActor in await self.loadOrders(for: currentUserId) }
    }
    nonisolated func commandDidFail(with error: Error) {
        Task { @MainActor in self.errorMessage = error.localizedDescription }
    }
}
```

---

## 📐 Níveis de Deployment em Swift

### Nível 1 — Mesmo store, handlers separados (mais simples)
```
[View/@MainActor] → [CommandBus/actor] → [actor Store]
[View/@MainActor] → [some QueryHandling] → [actor Store] (mesma instância)
```
Adequado para: apps iOS/macOS com domínio moderado.

### Nível 2 — Read cache derivado do write store via EventBus
```
[actor CommandHandler] → [actor WriteStore]
                                ↓ (publica DomainEvent via actor EventBus)
                  [actor ReadCache: [any DomainEvent] → projeções]
                                ↑
[struct QueryHandler] ──────────┘
```
Adequado para: apps com listas grandes que precisam de leitura offline/rápida.

### Nível 3 — Backend separado (Vapor + microserviços)
```
[actor CommandHandler] → [PostgreSQL — Write]
                                ↓
                        [Debezium / CDC]
                                ↓
                        [Kafka / Redis Streams]
                                ↓
                  [ElasticSearch / Read DB]
                                ↑
[struct QueryHandler]  ─────────┘
```
Adequado para: sistemas Vapor com alta escala e múltiplos read models.

---

## `some` vs `any` em CQRS — Tabela de Decisão Rápida

| Situação | Decisão | Por quê |
|----------|---------|---------|
| Factory de handler (sempre mesmo tipo) | `some QueryHandling<Q>` | Zero-cost, type identity preservada |
| Propriedade em ViewModel (permite mock) | `any QueryHandling<Q>` | Flexibilidade para injeção de dependência |
| EventBus com eventos variados | `[any DomainEvent]` | Coleção heterogênea de tipos |
| Handler com múltiplos requisitos | `some CommandHandling<C> & Loggable` | Composição, sem protocol extra |
| Protocol com `associatedtype` como retorno | `some Protocol` | `any` não funciona como return type aqui |
| Encadeamento de transformações | `some Protocol` | `any` não pode ser passado como argumento genérico |
| Injeção no `init` | `some Protocol` no parâmetro | Syntax sugar para genérico — type-safe |

---

## 🗺️ Checklist para a IA — Antes de Sugerir CQRS em Swift

```
[ ] O sistema tem lógica de domínio complexa na escrita?
[ ] Leitura e escrita têm requisitos de escala diferentes?
[ ] O estado mutável compartilhado precisa ser protegido? (→ actor)
[ ] O sistema usa ou planeja Event Sourcing?
[ ] Há necessidade de múltiplos read models otimizados?
[ ] A UI precisa reagir a mudanças de estado? (→ @MainActor + ViewModel + Delegate)
[ ] Operações no CommandHandler podem ser paralelizadas? (→ async let / TaskGroup)
[ ] Tasks longas precisam de suporte a cancelamento? (→ checkCancellation)
[ ] O handler vai mudar de implementação sem quebrar chamadores? (→ some em factory)
[ ] Precisa armazenar handlers de tipos diferentes? (→ any na propriedade)

Se 2+ forem "Sim" → CQRS é adequado.
Se todas forem "Não" → prefira actor/repository simples.
```

---

## 📌 Resumo das Regras de Ouro — Swift Edition

| Regra | Idioma Swift |
|---|---|
| **Commands não retornam dados de domínio** | `func handle(_ cmd: C) async throws` — sem return ou apenas UUID |
| **Queries não mudam estado** | `struct` QueryHandler, sem `mutating`, sem writes |
| **Estado mutável protegido** | `actor` — `CommandHandling: Actor` torna isso explícito |
| **UI atualizada no thread certo** | `@MainActor` no ViewModel, nunca no handler |
| **Operações independentes em paralelo** | `async let` (fixo) ou `withTaskGroup` (dinâmico) |
| **Erros comunicados corretamente** | `throws` — nunca `Bool` ou `Optional` como sinal de falha |
| **Types entre domínios de concorrência** | `Sendable` em Commands, Queries, Events — sintetizado |
| **Tipo único concreto oculto** | `some Protocol` — zero-cost, type identity preservada |
| **Coleção de tipos diferentes** | `any Protocol` — boxing, use só quando necessário |
| **Protocol com `associatedtype`** | `some Protocol` — nunca `any` como return type |
| **Múltiplos protocols combinados** | `Protocol1 & Protocol2` — não crie protocol intermediário |
| **Comportamento transversal** | Protocol extension — não toque nos handlers concretos |
| **Notificação de mudanças para UI** | Delegation com `AnyObject` + `weak` — evita retain cycle |
| **Conformidades simples** | Deixe Swift sintetizar `Equatable`/`Hashable`/`Sendable` |
| **CQRS ≠ dois bancos obrigatórios** | Separação de comportamento, não de storage |
| **CQRS ≠ Event Sourcing** | Complementares, mas independentes |
| **Não use em CRUD simples** | `actor Repository` direto é suficiente |

---

*Guia baseado em: CQRS original (Greg Young / EventStore), The Swift Programming Language — Protocols; Opaque and Boxed Protocol Types; Concurrency; Memory Safety; Patterns (Apple Inc.), Swift API Design Guidelines (swift.org).*