import Foundation

/// Representa um erro padronizado dentro do Bounded Context, seguindo o contrato definido no JSON Schema.
public struct AppError: Error, Sendable, Equatable {
    
    // Manual Equatable implementation since cause (any Error) is not Equatable
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id || (lhs.code == rhs.code && lhs.bc == rhs.bc && lhs.module == rhs.module)
    }

    // MARK: - Required Properties
    
    /// Identificador único gerado na criação do erro.
    public let id: String
    
    /// Código de erro estável para suporte (ex: PAT-001).
    public let code: String
    
    /// Mensagem de erro final para o usuário.
    public let message: String
    
    /// Bounded Context onde o erro se originou.
    public let bc: String
    
    /// Módulo ou subdomínio de origem.
    public let module: String
    
    /// Tipo específico de erro dentro do catálogo do módulo.
    public let kind: String
    
    /// Dados contextuais brutos capturados na criação.
    public let context: [String: AnySendable]
    
    /// Contexto sanitizado, seguro para logs externos e respostas.
    public let safeContext: [String: AnySendable]
    
    /// Dados de observabilidade para telemetria.
    public let observability: Observability
    
    // MARK: - Optional Properties
    
    /// Status HTTP sugerido para camadas de entrega.
    public let http: Int?
    
    /// Stack trace original, se disponível.
    public let stackTrace: String?
    
    /// Causa raiz associada a este erro.
    public let cause: (any Error)?

    // MARK: - Nested Types
    
    public struct Observability: Sendable, Equatable {
        public let category: Category
        public let severity: Severity
        public let fingerprint: [String]
        public let tags: [String: String]
        
        public init(
            category: Category,
            severity: Severity,
            fingerprint: [String],
            tags: [String: String]
        ) {
            self.category = category
            self.severity = severity
            self.fingerprint = fingerprint
            self.tags = tags
        }
    }
    
    public enum Category: String, Sendable {
        case domainRuleViolation = "DOMAIN_RULE_VIOLATION"
        case externalApiFailure = "EXTERNAL_API_FAILURE"
        case externalContractMismatch = "EXTERNAL_CONTRACT_MISMATCH"
        case crossLayerCommunicationFailure = "CROSS_LAYER_COMMUNICATION_FAILURE"
        case dataConsistencyIncident = "DATA_CONSISTENCY_INCIDENT"
        case securityBoundaryViolation = "SECURITY_BOUNDARY_VIOLATION"
        case infrastructureDependencyFailure = "INFRASTRUCTURE_DEPENDENCY_FAILURE"
        case observabilityPipelineFailure = "OBSERVABILITY_PIPELINE_FAILURE"
        case unexpectedSystemState = "UNEXPECTED_SYSTEM_STATE"
        case conflict = "CONFLICT"
    }
    
    public enum Severity: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }

    // MARK: - Initializer
    
    public init(
        id: String = UUID().uuidString,
        code: String,
        message: String,
        bc: String,
        module: String,
        kind: String,
        context: [String: AnySendable],
        safeContext: [String: AnySendable],
        observability: Observability,
        http: Int? = nil,
        stackTrace: String? = nil,
        cause: (any Error)? = nil
    ) {
        self.id = id
        self.code = code
        self.message = message
        self.bc = bc
        self.module = module
        self.kind = kind
        self.context = context
        self.safeContext = safeContext
        self.observability = observability
        self.http = http
        self.stackTrace = stackTrace
        self.cause = cause
    }
}

/// Helper para permitir que dicionários de contexto sejam Sendable e armazenem valores diversos.
public struct AnySendable: @unchecked Sendable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
}

// Extensões para facilitar o uso do Result pattern
public extension Result where Failure == AppError {
    static func appFailure(
        code: String,
        message: String,
        bc: String,
        module: String,
        kind: String,
        category: AppError.Category,
        severity: AppError.Severity,
        context: [String: Any] = [:],
        http: Int? = nil
    ) -> Self {
        let error = AppError(
            code: code,
            message: message,
            bc: bc,
            module: module,
            kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(
                category: category,
                severity: severity,
                fingerprint: [code],
                tags: [:]
            ),
            http: http
        )
        return .failure(error)
    }
}

// MARK: - AppErrorConvertible

/// Protocolo que todo erro de domínio deve assinar para ser traduzido para o contrato de AppError do microserviço.
public protocol AppErrorConvertible: Error {
    /// A representação do erro no formato padronizado AppError.
    var asAppError: AppError { get }
}
