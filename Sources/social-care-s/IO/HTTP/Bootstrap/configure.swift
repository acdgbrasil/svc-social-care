import Vapor
import PostgresKit
import JWT

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
        ConvertJsonbToText(),
    ])

    // MARK: - Service Container

    app.services = ServiceContainer(db: sqlDb)

    // MARK: - Server

    app.http.server.configuration.hostname = Environment.get("SERVER_HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    // MARK: - JWT (Zitadel OIDC)

    let jwksUrl = Environment.get("JWKS_URL") ?? "https://auth.acdgbrasil.com.br/oauth/v2/keys"
    let jwksResponse = try await app.client.get(URI(string: jwksUrl))
    guard let jwksData = jwksResponse.body else {
        throw Abort(.internalServerError, reason: "Failed to fetch JWKS from identity provider.")
    }
    let jwksJSON = String(buffer: jwksData)
    try await app.jwt.keys.add(jwksJSON: jwksJSON)

    // MARK: - Token Introspection (fallback for service accounts without role claims)

    if let introspectClientId = Environment.get("ZITADEL_INTROSPECT_CLIENT_ID"),
       let introspectClientSecret = Environment.get("ZITADEL_INTROSPECT_CLIENT_SECRET") {
        let issuer = Environment.get("ZITADEL_ISSUER") ?? "https://auth.acdgbrasil.com.br"
        app.tokenIntrospector = ZitadelTokenIntrospector(
            introspectURL: "\(issuer)/oauth/v2/introspect",
            clientId: introspectClientId,
            clientSecret: introspectClientSecret
        )

        if let allowedIds = Environment.get("ALLOWED_SERVICE_ACCOUNTS") {
            app.allowedServiceAccounts = Set(allowedIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
    }

    // MARK: - Middleware

    app.middleware.use(AppErrorMiddleware())
    app.middleware.use(JWTAuthMiddleware())

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
