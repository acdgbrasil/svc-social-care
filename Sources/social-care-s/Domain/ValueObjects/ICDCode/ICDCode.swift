import Foundation

/// Um Value Object que representa um código CID.
///
/// Este objeto garante que o código esteja sempre em um formato normalizado.
public struct ICDCode: Codable, Equatable, Hashable, Sendable {
    /// O código CID normalizado (ex: "B20.1").
    public let value: String

    // MARK: - Initializer

    /// Inicializa um `ICDCode` aplicando regras de normalização.
    ///
    /// - Parameters:
    ///   - rawValue: A string bruta (ex: "b201").
    ///   - requiresDot: Se `true`, exige a presença de um ponto.
    ///   - autoDot: Se `true`, insere o ponto automaticamente.
    /// - Throws: `ICDCodeError` em caso de erro de validação.
    public init(_ rawValue: String, requiresDot: Bool = false, autoDot: Bool = true) throws {
        guard !rawValue.isEmpty else { throw ICDCodeError.emptyCidCode }
        
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if requiresDot && !sanitized.contains(".") { 
            throw ICDCodeError.invalidCidNumber(value: sanitized) 
        }
        
        if autoDot && !sanitized.contains(".") && sanitized.count >= 3 {
            var codeWithDot = sanitized
            let dotIndex = codeWithDot.index(codeWithDot.endIndex, offsetBy: -1)
            codeWithDot.insert(".", at: dotIndex)
            self.value = codeWithDot
            return
        }

        self.value = sanitized
    }

    // MARK: - Formatting Helpers

    /// Retorna o código formatado sem pontos.
    public var normalized: String {
        value.replacingOccurrences(of: ".", with: "")
    }

    // MARK: - Comparison

    /// Verifica se este código refere-se ao mesmo diagnóstico que outro, ignorando pontos.
    public func isEquivalent(to other: ICDCode) -> Bool {
        return self.normalized == other.normalized
    }
}
