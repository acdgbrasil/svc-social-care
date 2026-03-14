import Vapor

struct AppErrorMiddleware: AsyncMiddleware {
    private static let verboseErrors = Environment.get("VERBOSE_ERRORS") == "true"
    static let buildVersion = Environment.get("BUILD_SHA") ?? "dev"

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            let response = try await next.respond(to: request)
            response.headers.add(name: "X-Build-Version", value: Self.buildVersion)
            return response
        } catch let appError as AppError {
            logAppError(appError, request: request)
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                context: appError.context,
                request: request
            )
        } catch let convertible as AppErrorConvertible {
            let appError = convertible.asAppError
            logAppError(appError, request: request)
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                context: appError.context,
                request: request
            )
        } catch let abort as AbortError {
            return makeResponse(
                status: abort.status,
                code: "HTTP-\(abort.status.code)",
                message: abort.reason,
                context: [:],
                request: request
            )
        } catch {
            request.logger.error("Unhandled error: \(error)")
            return makeResponse(
                status: .internalServerError,
                code: "SYS-500",
                message: "Erro interno do servidor.",
                context: [:],
                request: request
            )
        }
    }

    private func logAppError(_ appError: AppError, request: Request) {
        let contextDescription = appError.context.map { "\($0.key): \($0.value.value)" }.joined(separator: ", ")
        request.logger.error("\(appError.code) [\(appError.kind)] \(appError.message) context: {\(contextDescription)}")
    }

    private func makeResponse(
        status: HTTPResponseStatus,
        code: String,
        message: String,
        context: [String: AnySendable],
        request: Request
    ) -> Response {
        var body: [String: String] = [
            "code": code,
            "message": message
        ]
        if Self.verboseErrors && !context.isEmpty {
            body["details"] = context.map { "\($0.key): \($0.value.value)" }.joined(separator: "; ")
        }
        do {
            let data = try JSONEncoder().encode(["error": body])
            var headers = HTTPHeaders()
            headers.contentType = .json
            headers.add(name: "X-Build-Version", value: Self.buildVersion)
            return Response(status: status, headers: headers, body: .init(data: data))
        } catch {
            return Response(status: .internalServerError)
        }
    }
}
