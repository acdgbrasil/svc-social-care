import Vapor

struct AppErrorMiddleware: AsyncMiddleware {
    private static let verboseErrors: Bool = {
        let isProduction = Environment.get("ENVIRONMENT") == "production"
        return !isProduction && Environment.get("VERBOSE_ERRORS") == "true"
    }()

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            let response = try await next.respond(to: request)
            return response
        } catch let appError as AppError {
            logAppError(appError, request: request)
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                safeContext: appError.safeContext,
                request: request
            )
        } catch let convertible as AppErrorConvertible {
            let appError = convertible.asAppError
            logAppError(appError, request: request)
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                safeContext: appError.safeContext,
                request: request
            )
        } catch let abort as AbortError {
            // `abort.headers` é propagado: um `Abort` pode carregar header que
            // faz parte da resposta, não decoração — o 429 do rate limit precisa
            // do `Retry-After` e da cota (ADR-046). Descartá-los transformava a
            // resposta em "erro sem instrução".
            return makeResponse(
                status: abort.status,
                code: "HTTP-\(abort.status.code)",
                message: abort.reason,
                request: request,
                extraHeaders: abort.headers
            )
        } catch {
            request.logger.error("Unhandled error", metadata: LogSanitizer.metadata(for: error))
            return makeResponse(
                status: .internalServerError,
                code: "SYS-500",
                message: "Erro interno do servidor.",
                request: request
            )
        }
    }

    private func logAppError(_ appError: AppError, request: Request) {
        let safeDescription = appError.safeContext.map { "\($0.key): \($0.value.value)" }.joined(separator: ", ")
        request.logger.error("\(appError.code) [\(appError.kind)] \(appError.message) safeContext: {\(safeDescription)}")
    }

    private func makeResponse(
        status: HTTPResponseStatus,
        code: String,
        message: String,
        safeContext: [String: AnySendable] = [:],
        request: Request,
        extraHeaders: HTTPHeaders = [:]
    ) -> Response {
        var details: String?
        if Self.verboseErrors && !safeContext.isEmpty {
            details = safeContext.map { "\($0.key): \($0.value.value)" }.joined(separator: "; ")
        }
        return Self.errorResponse(
            status: status,
            code: code,
            message: message,
            details: details,
            extraHeaders: extraHeaders
        )
    }

    /// O envelope de erro do serviço — `{"error": {"code", "message"}}` — em um
    /// lugar só.
    ///
    /// É `static` porque **não é exclusivo deste middleware**: um middleware que
    /// corta a requisição antes dele (o rate limit, ADR-046) precisa responder no
    /// mesmo formato, e um segundo envelope, ainda que parecido, viraria dois
    /// contratos para o BFF tratar.
    static func errorResponse(
        status: HTTPResponseStatus,
        code: String,
        message: String,
        details: String? = nil,
        extraHeaders: HTTPHeaders = [:]
    ) -> Response {
        var body: [String: String] = [
            "code": code,
            "message": message
        ]
        if let details {
            body["details"] = details
        }
        do {
            let data = try JSONEncoder().encode(["error": body])
            var headers = HTTPHeaders()
            headers.contentType = .json
            for (name, value) in extraHeaders {
                headers.replaceOrAdd(name: name, value: value)
            }
            return Response(status: status, headers: headers, body: .init(data: data))
        } catch {
            return Response(status: .internalServerError)
        }
    }
}
