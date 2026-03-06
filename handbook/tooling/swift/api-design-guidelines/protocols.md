# Guia de Protocols e Opaque/Boxed Types em Swift para IA

> Baseado na documentação oficial do Swift Programming Language.  
> Cada seção inclui ✅ **O QUE FAZER** e ❌ **O QUE NÃO FAZER** com exemplos concretos.

---

## O que é um Protocol?

Um protocol define um **blueprint de métodos, propriedades e outros requisitos** que um tipo deve implementar. Qualquer tipo que satisfaça esses requisitos é dito *conformar* ao protocol.

Além de exigir requisitos, você pode **estender um protocol** para fornecer implementações padrão que todos os conformantes ganham automaticamente.

---

## 1. Sintaxe de Definição e Adoção

```swift
protocol SomeProtocol {
    // definição
}

struct SomeStructure: FirstProtocol, AnotherProtocol { }

// Classe com superclasse: superclasse SEMPRE vem antes dos protocols
class SomeClass: SomeSuperclass, FirstProtocol, AnotherProtocol { }
```

> **Regra:** Protocols são tipos — nomeie-os com letra maiúscula (`FullyNamed`, `Drawable`), assim como `Int`, `String` e `Double`.

### ✅ Ordem correta de herança em classes
```swift
class MyView: UIView, Drawable, Animatable { } // ✅ superclasse primeiro
```

### ❌ Protocols antes da superclasse
```swift
class MyView: Drawable, UIView { } // ❌ Erro de compilação — superclasse deve ser primeira
```

---

## 2. Property Requirements

Um protocol especifica **nome**, **tipo** e **acessibilidade** (`{ get }` ou `{ get set }`), mas nunca o tipo de armazenamento (stored vs computed — isso é decisão do conformante).

### ✅ Declaração correta de propriedades
```swift
protocol SomeProtocol {
    var mustBeSettable: Int { get set }          // ✅ var, não let
    var doesNotNeedToBeSettable: Int { get }     // ✅ read-only
    static var someTypeProperty: Int { get set } // ✅ type property: sempre static no protocol
}

protocol FullyNamed {
    var fullName: String { get }
}

// ✅ Stored property satisfaz { get }
struct Person: FullyNamed {
    var fullName: String
}

// ✅ Computed property também satisfaz { get }
class Starship: FullyNamed {
    var prefix: String?
    var name: String
    init(name: String, prefix: String? = nil) {
        self.name = name
        self.prefix = prefix
    }
    var fullName: String {
        return (prefix != nil ? prefix! + " " : "") + name
    }
}
// Starship(name: "Enterprise", prefix: "USS").fullName == "USS Enterprise"
```

### ❌ Erros comuns com property requirements
```swift
protocol BadProtocol {
    let immutable: Int { get }   // ❌ use var, nunca let em protocol
    var typeProp: Int { get set } // ❌ type property precisa de static
}

// ❌ Constant stored property não satisfaz { get set }
struct Bad: SomeProtocol {
    let mustBeSettable: Int = 0  // ❌ Erro — protocol exige { get set }, let é só leitura
}

// ✅ Correto:
struct Good: SomeProtocol {
    var mustBeSettable: Int      // ✅ var satisfaz { get set }
    let doesNotNeedToBeSettable: Int // ✅ let satisfaz { get } (somente leitura é OK)
    static var someTypeProperty: Int = 0
}
```

---

## 3. Method Requirements

### ✅ Método de instância e tipo
```swift
protocol SomeProtocol {
    static func someTypeMethod() // ✅ sempre static em protocol
}

protocol RandomNumberGenerator {
    func random() -> Double      // ✅ sem corpo, sem default values
}

class LinearCongruentialGenerator: RandomNumberGenerator {
    var lastRandom = 42.0
    let m = 139968.0, a = 3877.0, c = 29573.0
    func random() -> Double {
        lastRandom = ((lastRandom * a + c).truncatingRemainder(dividingBy: m))
        return lastRandom / m
    }
}
```

### ✅ Mutating method requirements
```swift
// ✅ Protocol marca mutating para permitir structs e enums
protocol Togglable {
    mutating func toggle()
}

// ✅ Enum e struct PRECISAM de mutating
enum OnOffSwitch: Togglable {
    case off, on
    mutating func toggle() {
        self = (self == .off) ? .on : .off
    }
}

// ✅ Classes NÃO precisam de mutating (reference semantics)
class MyToggle: Togglable {
    var isOn = false
    func toggle() { isOn.toggle() } // ✅ sem mutating — classes não precisam
}
```

### ❌ Esquecer mutating em struct
```swift
protocol Resettable {
    mutating func reset()
}

struct Counter: Resettable {
    var count = 0
    func reset() { count = 0 } // ❌ Erro de compilação — faltou mutating
    // ✅ mutating func reset() { count = 0 }
}
```

### ❌ Default values em protocol
```swift
protocol Config {
    func setup(timeout: Int = 30) // ❌ Erro — protocols não permitem default values
    // ✅ func setup(timeout: Int)
}
```

---

## 4. Initializer Requirements

### ✅ Required em classes (não-final)
```swift
protocol SomeProtocol {
    init(someParameter: Int)
}

// ✅ Não-final class: required obrigatório (garante que subclasses também conformem)
class SomeClass: SomeProtocol {
    required init(someParameter: Int) { }
}

// ✅ final class: required desnecessário (não pode ter subclasses)
final class FinalClass: SomeProtocol {
    init(someParameter: Int) { }
}

// ✅ Subclasse com override + required (quando sobrescreve init da superclasse)
class SomeSubClass: SomeSuperClass, SomeProtocol {
    required override init() { } // ✅ required (do protocol) + override (da superclasse)
}
```

### ✅ Failable initializer
```swift
protocol Configurable {
    init?(config: [String: Any]) // ✅ failable no protocol
}

struct Settings: Configurable {
    let timeout: Int
    init?(config: [String: Any]) { // ✅ failable satisfaz failable
        guard let t = config["timeout"] as? Int else { return nil }
        self.timeout = t
    }
    // Alternativa: init(config:) sem ? também satisfaz init?(config:) ✅
}
```

### ❌ Esquecer required
```swift
class MyController: SomeProtocol {
    init(someParameter: Int) { } // ❌ faltou required
    // Subclasses de MyController não conformarão automaticamente ao protocol
}
```

---

## 5. Protocols como Tipos

Há três formas de usar um protocol como tipo — cada uma com trade-offs diferentes:

| Forma | Sintaxe | Tipo escolhido por | Type identity | Custo |
|-------|---------|--------------------|---------------|-------|
| **Generic constraint** | `<T: Shape>` | Caller | Visível | Nenhum |
| **Opaque type** | `some Shape` | Implementação | Preservada (compiler) | Nenhum |
| **Boxed protocol** | `any Shape` | Runtime | Apagada | Boxing (indireção) |

### ✅ Protocol como generic constraint
```swift
// Caller escolhe o tipo concreto
func printDescription<T: TextRepresentable>(_ item: T) {
    print(item.textualDescription)
}
```

### ✅ Protocol como boxed type em coleções heterogêneas
```swift
// [any TextRepresentable] pode misturar Dice, SnakesAndLadders, Hamster
let things: [any TextRepresentable] = [game, d12, simonTheHamster]
for thing in things {
    print(thing.textualDescription) // ✅ acesso apenas a membros do protocol
}
```

### ❌ Tentar acessar membros específicos do tipo concreto sem downcast
```swift
let shapes: [any Shape] = [Triangle(size: 3), Square(size: 2)]
print(shapes[0].size) // ❌ Erro — 'size' não é requisito de Shape, só de Triangle

// ✅ Faça downcast primeiro
if let triangle = shapes[0] as? Triangle {
    print(triangle.size) // ✅
}
```

---

## 6. Delegation Pattern

Delegation permite que uma classe/struct delegue responsabilidades a outro tipo via protocol.

### ✅ Implementação correta com AnyObject e weak
```swift
class DiceGame {
    let sides: Int
    let generator = LinearCongruentialGenerator()
    weak var delegate: Delegate? // ✅ weak — evita retain cycle

    init(sides: Int) { self.sides = sides }

    func play(rounds: Int) {
        delegate?.gameDidStart(self)           // ✅ optional chaining — delegate pode ser nil
        for round in 1...rounds {
            let p1 = Int(generator.random() * Double(sides)) + 1
            let p2 = Int(generator.random() * Double(sides)) + 1
            delegate?.game(self, didEndRound: round, winner: p1 > p2 ? 1 : p1 < p2 ? 2 : nil)
        }
        delegate?.gameDidEnd(self)
    }

    // ✅ Protocol aninhado — faz sentido estar dentro de DiceGame
    protocol Delegate: AnyObject {            // ✅ AnyObject = class-only = permite weak
        func gameDidStart(_ game: DiceGame)
        func game(_ game: DiceGame, didEndRound round: Int, winner: Int?)
        func gameDidEnd(_ game: DiceGame)
    }
}

// ✅ Implementação do delegate
class DiceGameTracker: DiceGame.Delegate {
    var playerScore1 = 0, playerScore2 = 0

    func gameDidStart(_ game: DiceGame) {
        playerScore1 = 0; playerScore2 = 0
        print("Novo jogo com dado de \(game.sides) faces")
    }
    func game(_ game: DiceGame, didEndRound round: Int, winner: Int?) {
        switch winner {
        case 1: playerScore1 += 1; print("Jogador 1 venceu a rodada \(round)")
        case 2: playerScore2 += 1; print("Jogador 2 venceu a rodada \(round)")
        default: print("Rodada \(round) empatada")
        }
    }
    func gameDidEnd(_ game: DiceGame) {
        print(playerScore1 > playerScore2 ? "Jogador 1 ganhou!" : "Jogador 2 ganhou!")
    }
}

// Uso:
let tracker = DiceGameTracker()
let game = DiceGame(sides: 6)
game.delegate = tracker
game.play(rounds: 3)
```

### ❌ Delegate sem AnyObject (retain cycle)
```swift
protocol BadDelegate {    // ❌ sem AnyObject — não pode ser weak
    func didFinish()
}

class Host {
    var delegate: BadDelegate? // ❌ não pode marcar como weak — retain cycle!
}

// ✅ Solução:
protocol GoodDelegate: AnyObject { func didFinish() }
class Host { weak var delegate: GoodDelegate? }
```

### ❌ Não usar optional chaining no delegate
```swift
func play() {
    delegate!.gameDidStart(self) // ❌ crash se delegate for nil
    // ✅ delegate?.gameDidStart(self)
}
```

---

## 7. Adicionando Conformidade via Extension

### ✅ Extension em tipo existente (inclusive sem acesso ao source)
```swift
protocol TextRepresentable {
    var textualDescription: String { get }
}

// ✅ Extension adiciona conformidade a tipo já existente
extension Dice: TextRepresentable {
    var textualDescription: String { "Um dado de \(sides) faces" }
}
// Todas as instâncias existentes de Dice já conformam automaticamente

// ✅ Conformidade condicional (só quando Element: TextRepresentable)
extension Array: TextRepresentable where Element: TextRepresentable {
    var textualDescription: String {
        "[" + map { $0.textualDescription }.joined(separator: ", ") + "]"
    }
}
```

### ✅ Declarar conformidade com extension vazia (tipo já satisfaz requisitos)
```swift
struct Hamster {
    var name: String
    var textualDescription: String { "Um hamster chamado \(name)" }
}

extension Hamster: TextRepresentable { } // ✅ corpo vazio — já tem textualDescription
```

### ❌ Assumir que satisfazer requisitos = conformidade automática
```swift
struct Point {
    var x: Double, y: Double
    var textualDescription: String { "(\(x), \(y))" }
    // ❌ Não conforma a TextRepresentable automaticamente — precisa declarar!
}

let p: TextRepresentable = Point(x: 1, y: 2) // ❌ Erro de compilação

// ✅ Adicione a declaração:
extension Point: TextRepresentable { }
```

---

## 8. Synthesized Implementations

Swift gera automaticamente `Equatable`, `Hashable` e `Comparable` em casos simples.

### ✅ Deixar Swift sintetizar (não implemente manualmente)

**Equatable** — structs com stored properties Equatable, enums com associated types Equatable, enums sem associated types:
```swift
struct Vector3D: Equatable { // ✅ Swift gera == automaticamente
    var x = 0.0, y = 0.0, z = 0.0
    // NÃO escreva == manualmente
}

let a = Vector3D(x: 1, y: 2, z: 3)
let b = Vector3D(x: 1, y: 2, z: 3)
print(a == b) // true ✅
```

**Hashable** — mesmas condições de Equatable:
```swift
struct GridPoint: Hashable { // ✅ Swift gera hash(into:) automaticamente
    var x: Int, y: Int
}
var visited: Set<GridPoint> = [] // ✅ pode usar em Set e como chave de Dictionary
```

**Comparable** — enums sem raw value:
```swift
enum SkillLevel: Comparable { // ✅ Swift gera < automaticamente
    case beginner
    case intermediate
    case expert(stars: Int)
}

let levels: [SkillLevel] = [.expert(stars: 5), .beginner, .intermediate, .expert(stars: 3)]
print(levels.sorted())
// beginner, intermediate, expert(stars: 3), expert(stars: 5) ✅
```

### ❌ Implementar manualmente o que Swift já sintetiza
```swift
struct Point: Equatable {
    var x: Double, y: Double
    // ❌ Desnecessário — Swift sintetizaria isso:
    static func == (lhs: Point, rhs: Point) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}
```

### ✅ Conformidades implícitas (Copyable, Sendable, BitwiseCopyable)
```swift
// Swift adiciona Copyable, Sendable e BitwiseCopyable automaticamente quando possível
struct MyData { var value: Int } // implicitamente Copyable e Sendable ✅

// ✅ Suprimir conformidade implícita com ~ (quando necessário por semântica)
struct FileDescriptor: ~Sendable { // suprime Sendable — file descriptor não deve ser compartilhado
    let rawValue: Int
}

// ✅ Supressão mais forte: impede extensões futuras também
@available(*, unavailable)
extension FileDescriptor: Sendable { }
```

---

## 9. Protocol Inheritance

Um protocol pode herdar de outros protocols, acumulando requisitos.

### ✅ Herança simples e múltipla
```swift
protocol TextRepresentable {
    var textualDescription: String { get }
}

// ✅ PrettyTextRepresentable herda todos os requisitos de TextRepresentable
protocol PrettyTextRepresentable: TextRepresentable {
    var prettyTextualDescription: String { get }
}

// ✅ Implementação — precisa satisfazer AMBOS os protocols
extension SnakesAndLadders: PrettyTextRepresentable {
    var prettyTextualDescription: String {
        var output = textualDescription + ":\n" // ✅ usa textualDescription herdado
        for index in 1...finalSquare {
            switch board[index] {
            case let n where n > 0: output += "▲ "
            case let n where n < 0: output += "▼ "
            default:                output += "○ "
            }
        }
        return output
    }
}
```

### ✅ Class-only protocols (quando precisa de weak reference)
```swift
// ✅ AnyObject restringe adoção apenas a classes — permite weak
protocol ClassOnlyDelegate: AnyObject {
    func didComplete()
}

class Controller {
    weak var delegate: ClassOnlyDelegate? // ✅ weak possível por ser AnyObject
}
```

### ❌ Tentar adotar class-only protocol em struct/enum
```swift
protocol ClassOnlyProtocol: AnyObject { }

struct MyStruct: ClassOnlyProtocol { } // ❌ Erro de compilação
enum MyEnum: ClassOnlyProtocol { }    // ❌ Erro de compilação
// ✅ Apenas classes (e actors) podem adotar protocols com AnyObject
```

---

## 10. Protocol Composition

Combina múltiplos protocols em um único requisito **sem criar novo protocol**.

### ✅ Composição com & em parâmetros
```swift
protocol Named { var name: String { get } }
protocol Aged   { var age: Int { get } }

struct Person: Named, Aged {
    var name: String
    var age: Int
}

// ✅ Named & Aged = "qualquer tipo que conforma a ambos"
func wishHappyBirthday(to person: Named & Aged) {
    print("Parabéns, \(person.name)! Você tem \(person.age) anos.")
}

let malcolm = Person(name: "Malcolm", age: 21)
wishHappyBirthday(to: malcolm) // ✅
```

### ✅ Composição com classe base
```swift
class Location { var latitude: Double; var longitude: Double
    init(latitude: Double, longitude: Double) { self.latitude = latitude; self.longitude = longitude }
}
class City: Location, Named {
    var name: String
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name; super.init(latitude: latitude, longitude: longitude)
    }
}

// ✅ Location & Named = "subclasse de Location que conforma a Named"
func beginConcert(in location: Location & Named) {
    print("Olá, \(location.name)!")
}
beginConcert(in: City(name: "São Paulo", latitude: -23.5, longitude: -46.6)) // ✅
```

### ❌ Criar protocol intermediário desnecessário só para combinar dois
```swift
// ❌ NamedAndAged não adiciona nada — é só combinação
protocol NamedAndAged: Named, Aged { }

// ✅ Use composição direta: Named & Aged
func greet(_ person: Named & Aged) { }
```

---

## 11. Verificando Conformidade a Protocol

Use `is`, `as?` e `as!` — mesma sintaxe de type casting.

### ✅ Verificação com is e as?
```swift
protocol HasArea { var area: Double { get } }

class Circle: HasArea {
    var radius: Double
    var area: Double { .pi * radius * radius }
    init(radius: Double) { self.radius = radius }
}

class Country: HasArea {
    var area: Double
    init(area: Double) { self.area = area }
}

class Animal {
    var legs: Int
    init(legs: Int) { self.legs = legs }
}

let objects: [AnyObject] = [Circle(radius: 2), Country(area: 243_610), Animal(legs: 4)]

for object in objects {
    if let obj = object as? HasArea {    // ✅ as? retorna optional — seguro
        print("Área: \(obj.area)")
    } else {
        print("Sem área")
    }
}
// Área: 12.566...
// Área: 243610.0
// Sem área
```

### ❌ Forçar cast sem verificar
```swift
let area = (objects[2] as! HasArea).area // ❌ runtime crash — Animal não tem HasArea
// ✅ Use as? com optional binding
```

---

## 12. Optional Protocol Requirements

Optional requirements são **exclusivos de Objective-C interop** e requerem `@objc`.

### ✅ Uso correto de optional requirements
```swift
// ✅ Protocol e requisito AMBOS marcados com @objc
@objc protocol CounterDataSource {
    @objc optional func increment(forCount count: Int) -> Int
    @objc optional var fixedIncrement: Int { get }
}

class Counter {
    var count = 0
    var dataSource: CounterDataSource?

    func increment() {
        // ✅ Dois níveis de optional chaining: dataSource pode ser nil + método pode não existir
        if let amount = dataSource?.increment?(forCount: count) {
            count += amount
        } else if let amount = dataSource?.fixedIncrement {
            count += amount
        }
    }
}

// ✅ Implementação parcial é válida (requisitos são opcionais)
class ThreeSource: NSObject, CounterDataSource {
    let fixedIncrement = 3 // implementa só a propriedade — o método é opcional
}
```

### ❌ Confundir optional requirements com default implementations
```swift
// Optional requirements (@objc) precisam de optional chaining ao chamar:
source?.increment?(forCount: count) // ✅ dois ? — dataSource e o método

// Default implementations NÃO precisam de optional chaining:
protocol Printable {
    func prettyPrint()
}
extension Printable {
    func prettyPrint() { print(self) } // default implementation
}
let p: Printable = MyType()
p.prettyPrint() // ✅ sem ? — sempre disponível via default implementation
```

### ❌ Tentar usar optional requirements em structs
```swift
@objc protocol DataSource {
    @objc optional func fetchData() -> [String]
}

struct MySource: DataSource { } // ❌ @objc protocols só podem ser adotados por classes
// ✅ Use class MySource: NSObject, DataSource { }
```

---

## 13. Protocol Extensions

Extensions em protocols fornecem implementações padrão para todos os conformantes.

### ✅ Adicionar comportamento via extension
```swift
// ✅ randomBool() disponível para TODOS que conformam a RandomNumberGenerator
extension RandomNumberGenerator {
    func randomBool() -> Bool { random() > 0.5 }
}

let gen = LinearCongruentialGenerator()
print(gen.randomBool()) // ✅ sem implementar nada extra
```

### ✅ Default implementation (pode ser sobrescrita)
```swift
protocol PrettyTextRepresentable: TextRepresentable {
    var prettyTextualDescription: String { get }
}

// ✅ Default implementation — funciona se o tipo não implementar a sua própria
extension PrettyTextRepresentable {
    var prettyTextualDescription: String {
        return textualDescription // usa o requisito herdado como fallback
    }
}
```

### ✅ Extensions com constraints
```swift
// ✅ allEqual() só disponível para Collections cujo Element é Equatable
extension Collection where Element: Equatable {
    func allEqual() -> Bool {
        for element in self {
            if element != first { return false }
        }
        return true
    }
}

[1, 1, 1].allEqual()    // true ✅
[1, 2, 1].allEqual()    // false ✅
// ["a", "b"].allEqual() — String é Equatable, funciona também ✅
```

### ❌ Tentar fazer protocol herdar via extension
```swift
// ❌ Extensions não podem fazer um protocol herdar de outro
extension SomeProtocol: AnotherProtocol { } // ❌ Erro de compilação

// ✅ Herança deve ser declarada no próprio protocol:
protocol SomeProtocol: AnotherProtocol { }
```

### ❌ Depender de extensions para conformidade (sem declaração explícita)
```swift
protocol Describable {
    func describe() -> String
}
extension Int {
    func describe() -> String { "Número: \(self)" } // existe o método, mas...
}
let x: Describable = 42 // ❌ Erro — Int não declara conformidade a Describable

// ✅ Adicione a declaração:
extension Int: Describable { }
```

---

## 14. Opaque Types (`some`)

Um tipo opaco **oculta o tipo concreto do chamador**, mas o **compiler ainda sabe qual é**. A implementação escolhe o tipo — o inverso dos generics.

### O problema que opaque types resolvem

#### ❌ Tipo interno vazando para a interface pública
```swift
// ❌ Chamadores veem JoinedShape<Triangle, FlippedShape<Triangle>> — implementação exposta
func makeShape() -> JoinedShape<Triangle, FlippedShape<Triangle>> {
    JoinedShape(top: Triangle(size: 3), bottom: FlippedShape(shape: Triangle(size: 3)))
}
// Se você mudar a implementação interna, quebra todos os chamadores
```

#### ✅ Opaque type oculta implementação
```swift
func makeTrapezoid() -> some Shape { // ✅ "algum Shape" — tipo concreto oculto
    let top = Triangle(size: 2)
    let middle = Square(size: 2)
    let bottom = FlippedShape(shape: top)
    return JoinedShape(top: top, bottom: JoinedShape(top: middle, bottom: bottom))
}
// Chamadores só sabem que é um Shape — a implementação interna pode mudar livremente
```

### ✅ Combinando opaque types com generics
```swift
func flip<T: Shape>(_ shape: T) -> some Shape {     // ✅ sempre retorna FlippedShape<T>
    return FlippedShape(shape: shape)
}

func join<T: Shape, U: Shape>(_ top: T, _ bottom: U) -> some Shape { // ✅ sempre JoinedShape<T,U>
    JoinedShape(top: top, bottom: bottom)
}

func repeat<T: Shape>(shape: T, count: Int) -> some Collection { // ✅ sempre [T]
    return Array<T>(repeating: shape, count: count)
}

let result = join(Triangle(size: 3), flip(Triangle(size: 3)))
print(result.draw()) // ✅
```

### ❌ Retornar tipos diferentes em opaque type
```swift
func invalidFlip<T: Shape>(_ shape: T) -> some Shape {
    if shape is Square {
        return shape              // ❌ retorna T
    }
    return FlippedShape(shape: shape) // ❌ retorna FlippedShape<T>
    // Erro de compilação: return types don't match
}

// ✅ Solução: mover o caso especial para dentro do tipo
struct FlippedShape<T: Shape>: Shape {
    var shape: T
    func draw() -> String {
        if shape is Square { return shape.draw() } // caso especial encapsulado aqui
        return shape.draw().split(separator: "\n").reversed().joined(separator: "\n")
    }
}
// Agora flip() sempre retorna FlippedShape<T> ✅
```

### ✅ Opaque types com protocols com associatedtype
```swift
protocol Container {
    associatedtype Item
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}
extension Array: Container { }

// ❌ Container com associatedtype não pode ser usado como return type direto
func makeContainer<T>(item: T) -> Container { return [item] }        // ❌ Erro
func makeContainer<T, C: Container>(item: T) -> C { return [item] } // ❌ Erro

// ✅ some Container funciona — compiler infere o tipo concreto
func makeOpaqueContainer<T>(item: T) -> some Container {
    return [item]
}

let container = makeOpaqueContainer(item: 12)
let twelve = container[0]
print(type(of: twelve)) // Int ✅ — type inference funciona com opaque types
```

---

## 15. `some` em Parâmetros (Opaque Parameter Types)

`some` em parâmetros é **syntax sugar para generics**, não um opaque type de verdade.

### ✅ As duas formas são equivalentes
```swift
// Estas duas funções são IDÊNTICAS:
func drawTwice<S: Shape>(_ shape: S) -> String {
    shape.draw() + "\n" + shape.draw()
}

func drawTwice(_ shape: some Shape) -> String { // ✅ mais conciso
    shape.draw() + "\n" + shape.draw()
}
```

### ✅ Múltiplos `some` = tipos independentes (podem ser diferentes)
```swift
func combine(shape s1: some Shape, with s2: some Shape) -> String {
    s1.draw() + "\n" + s2.draw()
    // s1 e s2 são tipos independentes — podem ser Triangle e Square ao mesmo tempo
}

combine(shape: Triangle(size: 3), with: Square(size: 2)) // ✅ tipos diferentes, OK
```

### ❌ Tentar usar `where` ou `==` com `some` em parâmetros
```swift
// ❌ Não é possível com a sintaxe leve — o tipo não tem nome
func same(_ s1: some Shape, _ s2: some Shape) -> Bool where ??? {
    // Não há como referenciar os tipos de s1 e s2
}

// ✅ Use generics nomeados para constraints complexas
func same<S: Shape & Equatable>(_ s1: S, _ s2: S) -> Bool {
    return s1 == s2
}
```

---

## 16. Boxed Protocol Types (`any`)

Um boxed type (existential) armazena **qualquer tipo** que conforma ao protocol, decidido em **runtime**. Usa a keyword `any`.

### ✅ Quando usar `any`
```swift
// ✅ Coleção que precisa misturar tipos diferentes conformantes ao mesmo protocol
struct VerticalShapes: Shape {
    var shapes: [any Shape] // ✅ pode conter Triangle, Square, FlippedShape juntos
    func draw() -> String {
        shapes.map { $0.draw() }.joined(separator: "\n\n")
    }
}

let vertical = VerticalShapes(shapes: [Triangle(size: 3), Square(size: 2)])
print(vertical.draw()) // ✅

// ✅ Downcast quando precisa do tipo concreto
if let triangle = vertical.shapes[0] as? Triangle {
    print(triangle.size) // ✅ acessa size agora que o tipo é conhecido
}
```

### ❌ Operações que dependem de type identity são impossíveis com `any`
```swift
func protoFlip<T: Shape>(_ shape: T) -> any Shape {
    return FlippedShape(shape: shape)
}

let a = protoFlip(Triangle(size: 3))
let b = protoFlip(Triangle(size: 3))
a == b // ❌ Erro — any Shape não preserva type identity, == não está disponível

// ❌ Boxed type não conforma ao próprio protocol (existential problem)
protoFlip(protoFlip(Triangle(size: 3))) // ❌ any Shape não é argumento válido para T: Shape
// "Type 'any Shape' cannot conform to 'Shape'"

// ✅ Use some Shape para encadear transformações:
func flip<T: Shape>(_ shape: T) -> some Shape { FlippedShape(shape: shape) }
flip(flip(Triangle(size: 3))) // ✅ funciona com opaque types
```

---

## 17. `some` vs `any` — Tabela de Decisão

| Critério | `some Shape` | `any Shape` |
|----------|-------------|-------------|
| **Tipo em compile time** | Conhecido pelo compiler | Desconhecido até runtime |
| **Escolhe o tipo** | Implementação | Caller / runtime |
| **Performance** | Zero overhead | Indireção (boxing) |
| **Type identity preservada** | ✅ Sim | ❌ Não |
| **Protocol com `associatedtype`** | ✅ Funciona | ❌ Não funciona como return type |
| **Coleção de tipos diferentes** | ❌ Todos devem ser o mesmo | ✅ Tipos diferentes OK |
| **Encadeamento de transformações** | ✅ Possível | ❌ Impossível |
| **Operadores como `==`** | ✅ Disponível | ❌ Geralmente indisponível |

### ✅ Guia de escolha rápida
```swift
// Use some quando:
// - A função SEMPRE retorna o mesmo tipo concreto (só oculto do caller)
// - O protocol tem associatedtype
// - Precisa encadear transformações
func makeShape() -> some Shape { Triangle(size: 3) } // ✅ some

// Use any quando:
// - Precisa armazenar tipos DIFERENTES em coleção
// - O tipo concreto só é conhecido em runtime
var shapes: [any Shape] = [Triangle(size: 3), Square(size: 2)] // ✅ any

// Use generics quando:
// - O CALLER precisa escolher o tipo
// - Precisa de constraints ou cláusulas where complexas
func max<T: Comparable>(_ x: T, _ y: T) -> T { x > y ? x : y } // ✅ genérico
```

---

## Resumo — Regras Rápidas para a IA

### Protocols

| Situação | Regra |
|----------|-------|
| Property em protocol | Sempre `var`, nunca `let` |
| Type property em protocol | Sempre `static` |
| Mutating method em protocol | Marcar `mutating` — structs precisam, classes ignoram |
| Default values em protocol | **Não são permitidos** em method requirements |
| Initializer em classe não-final | Deve ser `required` |
| Subclasse + override de init + protocol | `required override init` |
| Delegate | `protocol X: AnyObject` + `weak var delegate` |
| Dois protocols como parâmetro | `Protocol1 & Protocol2` (composição, sem criar novo protocol) |
| Optional requirements | Só com `@objc`, só em classes |

### Opaque e Boxed Types

| Situação | Decisão |
|----------|---------|
| Ocultar tipo concreto, sempre o mesmo | `some Protocol` |
| Coleção de tipos diferentes | `[any Protocol]` |
| Protocol com `associatedtype` | `some Protocol` (nunca `any` como return type) |
| Encadear transformações | `some Protocol` |
| Precisar de `==` entre retornos | `some Protocol` |
| `some` em parâmetro | Syntax sugar para genérico (tipos independentes se múltiplos) |
| Complexidade de constraints | Use genérico nomeado (`<T: Protocol>`) com `where` |

---

## Checklist para a IA

Antes de escrever ou revisar código com protocols em Swift:

- [ ] Property requirements usam `var`? Type properties usam `static`?
- [ ] Método que modifica struct/enum está marcado como `mutating` no protocol?
- [ ] Protocol requirement tem default value? → Remover (não é permitido)
- [ ] Classe não-final com initializer de protocol? → Adicionar `required`
- [ ] Delegate sem `AnyObject`? → Adicionar `: AnyObject` + `weak`
- [ ] Delegate chamado sem optional chaining? → Adicionar `?`
- [ ] Tipo satisfaz todos os requisitos mas não declara conformidade? → Adicionar declaração explícita
- [ ] Swift pode sintetizar `Equatable`/`Hashable`/`Comparable`? → Não implementar manualmente
- [ ] Retorno de função com tipo concreto sempre o mesmo mas que deve ser oculto? → `some`
- [ ] Coleção misturando tipos diferentes conformantes? → `any`
- [ ] Protocol com `associatedtype` como return type? → `some`, nunca `any`
- [ ] Tentando encadear `any Protocol` como argumento? → Impossível — usar `some`
- [ ] `some` em dois parâmetros? → São tipos **independentes** (podem ser diferentes)
- [ ] Precisando de `where` em parâmetro `some`? → Usar genérico nomeado

---

*Fonte: The Swift Programming Language — Protocols; Opaque and Boxed Protocol Types. © 2014–2025 Apple Inc. Licenciado sob CC BY 4.0.*