import Vapor
import PostgresKit

func configure(_ app: Application) async throws {
    // MARK: - Database

    let postgresConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DB_HOST") ?? "localhost",
        port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
        username: Environment.get("DB_USER") ?? "postgres",
        password: Environment.get("DB_PASSWORD") ?? "postgres",
        database: Environment.get("DB_NAME") ?? "social_care",
        tls: .disable
    )

    let source = PostgresConnectionSource(sqlConfiguration: postgresConfig)
    let pool = EventLoopGroupConnectionPool(source: source, on: app.eventLoopGroup)

    app.lifecycle.use(PoolShutdownHandler(pool: pool))

    let sqlDb = pool.database(logger: app.logger).sql()

    // MARK: - Migrations

    let runner = SQLKitMigrationRunner(db: sqlDb)
    try await runner.run([
        CreateInitialSchema(),
        AddRegistrationFields(),
        CreateLookupTables(),
        AddV2AssessmentFields(),
        AddPerformanceIndexes(),
        NormalizeSchema(),
        CreateAuditTrail(),
    ])

    // MARK: - Service Container

    app.services = ServiceContainer(db: sqlDb)

    // MARK: - Server

    app.http.server.configuration.hostname = Environment.get("SERVER_HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    // MARK: - Middleware

    app.middleware.use(AppErrorMiddleware())

    // MARK: - Content Configuration

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // MARK: - Graceful Shutdown

    app.lifecycle.use(GracefulShutdownHandler(logger: app.logger))

    // MARK: - Routes

    try app.register(collection: HealthController())
    try app.register(collection: PatientController())
    try app.register(collection: AssessmentController())
    try app.register(collection: ProtectionController())
    try app.register(collection: CareController())
    try app.register(collection: LookupController())
}

// MARK: - Pool Lifecycle

struct PoolShutdownHandler: LifecycleHandler, @unchecked Sendable {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    func shutdown(_ app: Application) {
        pool.shutdown()
    }
}

// MARK: - Graceful Shutdown

struct GracefulShutdownHandler: LifecycleHandler, @unchecked Sendable {
    let logger: Logger

    func willBoot(_ app: Application) throws {
        logger.info("social-care service starting up")
    }

    func shutdown(_ app: Application) {
        logger.info("social-care service shutting down — draining connections")
    }
}
