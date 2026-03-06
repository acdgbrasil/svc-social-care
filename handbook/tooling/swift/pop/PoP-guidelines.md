# Protocol-Based Development in Mobile Applications
## Guidelines for AI Coding Agents

> Based on: *Kolla, S. "Protocol-Based Development in Mobile Applications: A Comprehensive Guide" — Sarcouncil Journal of Multidisciplinary 5.9 (2025): pp 70-79.*

---

## 1. Core Principles

Always follow these three foundational principles when designing protocol-based architectures:

### 1.1 Interface Segregation
- Define **small, focused protocols** that describe only what is strictly necessary for a given functionality.
- Never create a single large protocol to handle multiple unrelated behaviors.
- Each architectural layer (presentation, business logic, data) must maintain **clear boundaries and independent responsibilities**.

### 1.2 Composition over Inheritance
- Prefer **composing smaller protocols** rather than building deep inheritance hierarchies.
- Mix and match behaviors through protocol conformance instead of subclassing.
- Each layer defines its own interfaces through protocols, enabling better testability and looser coupling.

### 1.3 Dependency Inversion
- Always depend on **abstractions (protocols)**, never on concrete implementations.
- Dependencies must point inward: outer layers depend on abstractions defined by inner layers.
- Use the **Repository Pattern** — define data access through protocols so the application can switch between sources (local storage, network) without touching business logic.

---

## 2. Protocol Definition Rules

### Do
- Define protocols that represent **what a type can do**, not what it is.
- Use protocol extensions to provide **default implementations** for shared behavior.
- Apply protocol composition to achieve multiple-inheritance-like behavior safely.
- Carefully distinguish which requirements belong in the protocol vs. which can be covered by extensions.

### Don't
- Never create protocols with too many unrelated methods — split them.
- Never duplicate behavior already provided by protocol extensions.
- Never break layer boundaries by making a protocol in an outer layer depend on a concrete type from an inner layer.

---

## 3. Architecture Layers

Structure every mobile application around **three independent layers**, always separated by protocol interfaces:

```
┌─────────────────────────┐
│    Presentation Layer   │  (UI, ViewModels)
├─────────────────────────┤
│   Business Logic Layer  │  (Use Cases, Domain)
├─────────────────────────┤
│       Data Layer        │  (Repositories, Storage, Network)
└─────────────────────────┘
```

- Each layer communicates with adjacent layers **only through protocols**.
- Changes in one layer must **not propagate** to other layers.
- The data layer must be **completely independent** of the business logic layer.

---

## 4. iOS (Swift) Implementation Guidelines

### Protocol Extensions
- Use protocol extensions to share behavior across types **horizontally**, avoiding vertical inheritance hierarchies.
- Provide default implementations for common operations to reduce code duplication.
- Allow conforming types to override defaults when specialized behavior is needed.

### Type Constraints and Generics
- Use associated types and generic constraints to establish type-safe relationships between protocols.
- Apply protocol composition (`TypeA & TypeB`) as a safer alternative to multiple class inheritance.
- Prefer **value types (structs)** over reference types (classes) when conforming to protocols — they offer better thread safety, memory efficiency, and performance.

### Recommended Design Patterns (Swift)
- **Strategy Pattern** — via protocol conformance, swap algorithms at runtime.
- **Delegate Pattern** — define delegation contracts through focused protocols.
- **Observer Pattern** — use protocol-based callbacks and bindings.
- **Factory Pattern** — abstract object creation behind protocols.
- **Repository Pattern** — isolate data access behind protocol interfaces.

---

## 5. Android (Kotlin) Implementation Guidelines

### Interfaces and Delegation
- Use Kotlin **interfaces** as the equivalent of Swift protocols for defining contracts.
- Use the `by` keyword for **delegation over inheritance** — prefer this for composing behaviors.
- Interfaces may include default method implementations — use this to share behavior cleanly.

### Extension Functions and Abstract Classes
- Use **extension functions** to add behavior to existing types without modifying them.
- Use abstract classes when partial implementation is needed alongside interface conformance.

### Recommended Design Patterns (Kotlin)
- **Singleton** — use `object` declarations for concise, safe singletons.
- **Factory** — use companion objects and extension functions for flexible object creation.
- **Observer** — use higher-order functions and delegation properties.
- **Decorator / Adapter** — use Kotlin's delegation pattern (`by`) for clean composition.
- **Template Method / Bridge** — use abstract classes implementing interfaces.

---

## 6. Testing Guidelines

- Always test each architectural layer **in isolation** using mock implementations created via protocol conformance.
- Define use cases through protocols so tests can simulate business scenarios without real data sources.
- Ensure mock objects implement all required protocol methods — the compiler enforces correctness.
- Target **≥ 85% test coverage** for protocol-based systems.
- Protocol-based testing reduces testing complexity by approximately **30%** compared to traditional OOP.

```
Test Strategy per Layer:
- Presentation Layer → Mock ViewModels / Presenters via protocol
- Business Logic Layer → Mock Use Cases / Repositories via protocol
- Data Layer → Mock network/storage providers via protocol
```

---

## 7. Networking Layer Guidelines

- Define all network operations as **protocols**, working with abstractions rather than concrete implementations.
- Use protocol inheritance and extensions to create hierarchical network service definitions.
- Provide **default implementations** for common operations (authentication tokens, request retrying, response caching).
- Ensure the networking layer is type-safe and can handle different data types and response formats consistently.

---

## 8. Data Storage Guidelines

- The data layer must expose access through **protocol interfaces only**.
- The application must be able to **swap storage implementations** (e.g., local database → remote API) without affecting business logic.
- Use the Repository Pattern as the standard data access abstraction.
- Maintain loose coupling between all modules through protocol-based interfaces.

---

## 9. UI Component Guidelines

- Apply the **MVVM architecture** pattern with protocol-defined contracts for view behaviors and data binding.
- Define view protocols to ensure consistency across different UI components.
- Separate UI logic from business logic strictly through protocol interfaces.

---

## 10. Common Pitfalls — Avoid These

| Pitfall | Solution |
|---|---|
| Over-abstraction | Create targeted protocols for real requirements only; avoid speculative abstractions |
| Deep protocol hierarchies | Break large hierarchies into small, composable protocols |
| Dynamic dispatch overhead | Prefer static dispatch where possible; use value types |
| Retain cycles (reference types) | Favor value types (structs) conforming to protocols |
| Coupling between layers | Always communicate across layers via protocol interfaces, never concrete types |
| Protocols with too many requirements | Split into multiple focused protocols (Interface Segregation) |

---

## 11. Performance Considerations

- Favor **value types** (structs in Swift) — they avoid reference counting overhead and retain cycles.
- Be aware of **protocol witness tables and dynamic dispatch** — use static dispatch when performance is critical.
- Well-designed protocol-based architectures achieve response times averaging **50–100ms** in mobile sensing applications, comparable to traditional OOP.
- Regular architecture reviews can reduce maintenance costs by up to **40%** and improve code reusability by **~25%**.

---

## 12. Documentation and Maintenance Standards

- Every protocol must have documentation that covers:
  - **Purpose** — what behavior contract it defines.
  - **Requirements** — all methods and properties that conforming types must implement.
  - **Default Implementations** — which requirements have defaults via extensions and what they do.
- Document the relationship between protocols and their extensions explicitly.
- Establish and enforce **consistent naming conventions** for protocols, extensions, and conformances across the codebase.
- Conduct regular protocol design reviews to reduce complexity and improve maintainability.

---

## 13. Quick Reference Checklist

Before finalizing any protocol-based implementation, verify:

- [ ] Protocol defines only **focused, necessary** requirements
- [ ] No concrete types leak across **layer boundaries**
- [ ] Business logic is **independent** of data source implementations
- [ ] Each component can be **tested in isolation** via mock protocol conformance
- [ ] Value types are preferred where **thread safety and memory** matter
- [ ] Protocol extensions provide **defaults** for shared behavior
- [ ] Dependency direction follows **inward-pointing** clean architecture rules
- [ ] Documentation covers purpose, requirements, and defaults for every protocol
- [ ] Naming conventions are **consistent** across all protocols and conformances
- [ ] Architecture has been **reviewed** for unnecessary complexity

---

*Source: Kolla, S. (2025). Protocol-Based Development in Mobile Applications: A Comprehensive Guide. Sarcouncil Journal of Multidisciplinary, 5(9), 70–79. DOI: https://doi.org/10.5281/zenodo.17105897*