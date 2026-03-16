import Vapor

@main
enum social_care_s {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)
        defer { Task { try await app.asyncShutdown() } }

        do {
            try await configure(app)
        } catch {
            app.logger.critical("Startup failed: \(error)")
            throw error
        }

        try await app.execute()
    }
}
