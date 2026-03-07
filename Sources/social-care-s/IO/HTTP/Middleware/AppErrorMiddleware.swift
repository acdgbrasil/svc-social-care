import Vapor

struct AppErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let appError as AppError {
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                request: request
            )
        } catch let convertible as AppErrorConvertible {
            let appError = convertible.asAppError
            return makeResponse(
                status: HTTPResponseStatus(statusCode: appError.http ?? 500),
                code: appError.code,
                message: appError.message,
                request: request
            )
        } catch let abort as AbortError {
            return makeResponse(
                status: abort.status,
                code: "HTTP-\(abort.status.code)",
                message: abort.reason,
                request: request
            )
        } catch {
            request.logger.error("Unhandled error: \(error)")
            return makeResponse(
                status: .internalServerError,
                code: "SYS-500",
                message: "Erro interno do servidor.",
                request: request
            )
        }
    }

    private func makeResponse(
        status: HTTPResponseStatus,
        code: String,
        message: String,
        request: Request
    ) -> Response {
        let body: [String: String] = [
            "code": code,
            "message": message
        ]
        do {
            let data = try JSONEncoder().encode(["error": body])
            var headers = HTTPHeaders()
            headers.contentType = .json
            return Response(status: status, headers: headers, body: .init(data: data))
        } catch {
            return Response(status: .internalServerError)
        }
    }
}
