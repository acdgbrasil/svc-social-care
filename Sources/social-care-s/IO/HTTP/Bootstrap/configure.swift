import Vapor
import PostgresKit
import JWT

func configure(_ app: Application) async throws {
    // MARK: - Database

    let isProduction = Environment.get("ENVIRONMENT") == "production"

    if isProduction {
        guard Environment.get("DB_HOST") != nil,
              Environment.get("DB_USER") != nil,
              Environment.get("DB_PASSWORD") != nil,
              Environment.get("DB_NAME") != nil else {
            fatalError("Required DB_HOST, DB_USER, DB_PASSWORD, DB_NAME environment variables are not set.")
        }
    }

    let postgresConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DB_HOST") ?? "localhost",
        port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
        username: Environment.get("DB_USER") ?? "postgres",
        password: Environment.get("DB_PASSWORD") ?? "postgres",
        database: Environment.get("DB_NAME") ?? "social_care",
        tls: isProduction ? .prefer(try .init(configuration: .clientDefault)) : .disable
    )

    let source = PostgresConnectionSource(sqlConfiguration: postgresConfig)
    let pool = EventLoopGroupConnectionPool(source: source, on: app.eventLoopGroup)

    app.lifecycle.use(PoolShutdownHandler(pool: pool))

    let sqlDb = pool.database(logger: app.logger).sql()

    // MARK: - Migrations

    let runner = SQLKitMigrationRunner(db: sqlDb)
    let migrations: [any Migration] = [
        CreateInitialSchema(),
        AddRegistrationFields(),
        CreateLookupTables(),
        AddV2AssessmentFields(),
        AddPerformanceIndexes(),
        NormalizeSchema(),
        CreateAuditTrail(),
        ConvertJsonbToText(),
        CreateLookupRequests(),
        AddCNSAndHomeless(),
        AddUniqueCpfConstraint(),
    ]
    for attempt in 1...10 {
        do {
            try await runner.run(migrations)
            break
        } catch {
            app.logger.warning("Migration attempt \(attempt)/10 failed: \(error)")
            if attempt == 10 { throw error }
            try await Task.sleep(for: .seconds(min(attempt * 2, 30)))
        }
    }

    // MARK: - Domain Event Registry

    await DomainEventRegistry.shared.bootstrap()

    // MARK: - Outbox Relay + NATS

    let natsUrl = Environment.get("NATS_URL")

    let natsPublisher: NATSEventPublisher? = natsUrl.map {
        NATSEventPublisher(url: $0)
    }
    let relay = SQLKitOutboxRelay(db: sqlDb, natsPublisher: natsPublisher)
    Task { await relay.startContinuousPolling() }

    // MARK: - NATS Subscriber (people-context events)

    if let natsUrl {
        let patientRepo = SQLKitPatientRepository(db: sqlDb)
        let linkPersonId = LinkPersonIdCommandHandler(patientRepository: patientRepo)
        let subscriber = NATSEventSubscriber(url: natsUrl)

        Task {
            await subscriber.subscribe(subject: "people.person.registered") { data in
                do {
                    let event = try JSONDecoder().decode(PersonRegisteredEvent.self, from: data)
                    guard let cpf = event.data.cpf else { return }
                    try await linkPersonId.handle(
                        LinkPersonIdCommand(
                            personId: event.data.personId,
                            cpf: cpf,
                            actorId: event.actorId
                        )
                    )
                } catch {
                    app.logger.error("Failed to process person.registered event: \(error)")
                }
            }
            await subscriber.start()
        }
    }

    // MARK: - Service Container

    let personValidator: (any PersonExistenceValidating)? = Environment.get("PEOPLE_API_URL").map {
        PeopleContextPersonValidator(baseURL: $0)
    }
    app.services = ServiceContainer(db: sqlDb, personValidator: personValidator)

    // MARK: - Server

    app.http.server.configuration.hostname = Environment.get("SERVER_HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    // MARK: - JWT (Zitadel OIDC)

    let jwksUrl = Environment.get("JWKS_URL") ?? "https://auth.acdgbrasil.com.br/oauth/v2/keys"
    var jwksLoaded = false
    for attempt in 1...10 {
        do {
            let jwksResponse = try await app.client.get(URI(string: jwksUrl))
            guard let jwksData = jwksResponse.body else {
                throw Abort(.internalServerError, reason: "Empty JWKS response")
            }
            let jwksJSON = String(buffer: jwksData)
            guard jwksJSON.trimmingCharacters(in: .whitespaces).hasPrefix("{") else {
                throw Abort(.internalServerError, reason: "JWKS response is not JSON: \(jwksJSON.prefix(100))")
            }
            try await app.jwt.keys.add(jwksJSON: jwksJSON)
            jwksLoaded = true
            break
        } catch {
            app.logger.warning("JWKS fetch attempt \(attempt)/10 failed: \(error)")
            if attempt < 10 {
                try await Task.sleep(for: .seconds(min(attempt * 2, 30)))
            }
        }
    }
    if !jwksLoaded {
        throw Abort(.internalServerError, reason: "Failed to load JWKS after 10 attempts from \(jwksUrl)")
    }

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

/// @unchecked Sendable justification: Vapor LifecycleHandler requires Sendable.
/// EventLoopGroupConnectionPool is thread-safe by design (internally synchronized).
struct PoolShutdownHandler: LifecycleHandler, @unchecked Sendable {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    func shutdown(_ app: Application) {
        pool.shutdown()
    }
}

// MARK: - Graceful Shutdown

/// @unchecked Sendable justification: Vapor LifecycleHandler requires Sendable.
/// Logger is Sendable; struct has no mutable state.
struct GracefulShutdownHandler: LifecycleHandler, @unchecked Sendable {
    let logger: Logger

    func willBoot(_ app: Application) throws {
        logger.info("social-care service starting up")
    }

    func shutdown(_ app: Application) {
        logger.info("social-care service shutting down — draining connections")
    }
}
