/// Documentos pessoais que podem ser solicitados para um membro familiar no contexto do SUAS.
public enum RequiredDocument: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    /// Certidão de Nascimento
    case birthCertificate = "CN"
    /// Registro Geral (RG)
    case rg = "RG"
    /// Carteira de Trabalho e Previdência Social (CTPS)
    case workCard = "CTPS"
    /// Cadastro de Pessoa Física (CPF)
    case cpf = "CPF"
    /// Título de Eleitor (TE)
    case voterRegistration = "TE"
}
