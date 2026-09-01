import Foundation
@testable import social_care_s

/// Exclusão mútua entre os testes que mexem em `OIDCJWTPayloadBootstrap.shared`.
///
/// POR QUÊ: aquele storage é **global de processo** (ADR-031 — o registro no
/// boot é o que faz `verify(using:)` validar iss/aud/exp/nbf em todo codepath).
/// Em teste isso vira recurso compartilhado: `OIDCJWTPayloadTests` faz
/// `set(...)` e `reset()` a cada caso, e os testes de integração HTTP precisam
/// do storage **preenchido** durante a requisição — se um `reset()` cair no
/// meio, o `JWTAuthMiddleware` responde 401 e o teste falha sem que nada tenha
/// regredido.
///
/// `.serialized` no `@Suite` não resolve: ele serializa os casos *dentro* de uma
/// suíte, e suítes irmãs seguem rodando em paralelo. Este gate é o escopo que
/// falta — todo teste que toca o storage global entra por aqui.
enum OIDCBootstrapGate {

    /// A fila propriamente dita. O corpo protegido roda **fora** do actor: se
    /// fosse passado para dentro, cruzaria o boundary de isolamento (o
    /// compilador recusa em strict concurrency) e ainda serializaria a app de
    /// teste no executor do actor. O actor guarda só o token de posse.
    private actor Queue {
        private var busy = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func acquire() async {
            while busy {
                await withCheckedContinuation { waiters.append($0) }
            }
            busy = true
        }

        func release() {
            busy = false
            guard !waiters.isEmpty else { return }
            waiters.removeFirst().resume()
        }
    }

    private static let queue = Queue()

    /// Executa `body` com acesso exclusivo ao storage global, e **sempre**
    /// devolve o storage ao estado limpo ao final — inclusive se `body` lançar,
    /// para não vazar validators de um teste para o seguinte.
    static func withExclusiveAccess<R>(_ body: () async throws -> R) async rethrows -> R {
        await queue.acquire()
        do {
            let result = try await body()
            OIDCJWTPayloadBootstrap.shared.reset()
            await queue.release()
            return result
        } catch {
            OIDCJWTPayloadBootstrap.shared.reset()
            await queue.release()
            throw error
        }
    }
}
