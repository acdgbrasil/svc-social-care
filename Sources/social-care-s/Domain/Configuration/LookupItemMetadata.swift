import Foundation

/// Metadados extras para tabelas de lookup com colunas adicionais.
/// Aplica-se a dominio_tipo_beneficio e dominio_tipo_violacao.
public struct LookupItemMetadata: Sendable {
    public let exigeRegistroNascimento: Bool?
    public let exigeCpfFalecido: Bool?
    public let exigeDescricao: Bool?

    public init(
        exigeRegistroNascimento: Bool? = nil,
        exigeCpfFalecido: Bool? = nil,
        exigeDescricao: Bool? = nil
    ) {
        self.exigeRegistroNascimento = exigeRegistroNascimento
        self.exigeCpfFalecido = exigeCpfFalecido
        self.exigeDescricao = exigeDescricao
    }
}
