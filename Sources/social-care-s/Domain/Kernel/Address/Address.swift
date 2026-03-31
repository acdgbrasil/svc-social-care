import Foundation

/// Value Object que representa um endereço residencial no contexto brasileiro.
///
/// Este objeto garante que o endereço possua os campos mínimos obrigatórios
/// para geolocalização e atendimento social (UF, Cidade e Localização).
///
/// Quando `isHomeless` é `true`, indica pessoa em situação de rua. UF e cidade
/// continuam obrigatórios para cobertura territorial (CRAS de referência).
///
/// - Note: Todas as strings são normalizadas (trimming e redução de espaços).
public struct Address: Codable, Equatable, Hashable, Sendable {

    // MARK: - Nested Types

    /// Define a localização geográfica da residência.
    public enum ResidenceLocation: String, Codable, Equatable, Hashable, Sendable {
        /// Áreas urbanas consolidadas.
        case urbano = "URBANO"
        /// Áreas rurais, assentamentos ou fazendas.
        case rural = "RURAL"
    }

    // MARK: - Properties

    /// O CEP validado da residência.
    public let cep: CEP?

    /// Indica se o endereço refere-se a um abrigo ou unidade de acolhimento.
    public let isShelter: Bool

    /// Indica se a pessoa encontra-se em situação de rua.
    public let isHomeless: Bool

    /// A classificação da localização (Urbano/Rural).
    public let residenceLocation: ResidenceLocation

    /// Nome do logradouro (Rua, Avenida, etc).
    public let street: String?

    /// Nome do bairro ou distrito.
    public let neighborhood: String?

    /// Número da residência.
    public let number: String?

    /// Complemento do endereço (Apto, Bloco, etc).
    public let complement: String?

    /// Sigla do Estado (UF).
    public let state: String

    /// Nome da cidade.
    public let city: String

    // MARK: - Initializer

    /// Cria um endereço validado.
    ///
    /// - Parameters:
    ///   - cep: String opcional do CEP (será validada pelo VO `CEP`).
    ///   - isShelter: Flag indicando se é um abrigo.
    ///   - isHomeless: Flag indicando pessoa em situação de rua.
    ///   - residenceLocation: Tipo de localização.
    ///   - street: Logradouro opcional.
    ///   - neighborhood: Bairro opcional.
    ///   - number: Número opcional.
    ///   - complement: Complemento opcional.
    ///   - state: Sigla da UF (obrigatória).
    ///   - city: Nome da cidade (obrigatório).
    /// - Throws: `AddressError` se UF ou Cidade forem inválidos ou ausentes.
    public init(
        cep: String? = nil,
        isShelter: Bool,
        isHomeless: Bool = false,
        residenceLocation: ResidenceLocation,
        street: String? = nil,
        neighborhood: String? = nil,
        number: String? = nil,
        complement: String? = nil,
        state: String,
        city: String
    ) throws {
        let normalizedCepInput = Self.normalize(text: cep)
        if let cepValue = normalizedCepInput {
            do {
                self.cep = try CEP(cepValue)
            } catch {
                throw AddressError.invalidCep(value: cepValue)
            }
        } else {
            self.cep = nil
        }

        let normalizedState = Self.normalize(text: state)?.uppercased()
        guard let finalState = normalizedState else {
            throw AddressError.stateRequired
        }
        guard Self.validStates.contains(finalState) else {
            throw AddressError.invalidState(value: finalState)
        }

        let normalizedCity = Self.normalize(text: city)
        guard let finalCity = normalizedCity else {
            throw AddressError.cityRequired
        }

        self.isShelter = isShelter
        self.isHomeless = isHomeless
        self.residenceLocation = residenceLocation
        self.street = Self.normalize(text: street)
        self.neighborhood = Self.normalize(text: neighborhood)
        self.number = Self.normalize(text: number)
        self.complement = Self.normalize(text: complement)
        self.state = finalState
        self.city = finalCity
    }

    // MARK: - Private Static Metadata

    private static let validStates: Set<String> = [
        "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO",
        "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI",
        "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
    ]

    /// Normaliza textos opcionais removendo espaços extras.
    private static func normalize(text: String?) -> String? {
        guard let text else { return nil }
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalized.isEmpty ? nil : normalized
    }
}
