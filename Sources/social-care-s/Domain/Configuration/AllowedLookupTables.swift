import Foundation

/// Tabelas de lookup permitidas no sistema.
public enum AllowedLookupTables {
    public static let all: Set<String> = [
        "dominio_tipo_identidade",
        "dominio_parentesco",
        "dominio_condicao_ocupacao",
        "dominio_escolaridade",
        "dominio_efeito_condicionalidade",
        "dominio_tipo_deficiencia",
        "dominio_programa_social",
        "dominio_tipo_ingresso",
        "dominio_tipo_beneficio",
        "dominio_tipo_violacao",
        "dominio_servico_vinculo",
        "dominio_tipo_medida",
        "dominio_unidade_realizacao",
    ]

    /// Tabelas com colunas de metadados adicionais.
    public static let tablesWithMetadata: Set<String> = [
        "dominio_tipo_beneficio",
        "dominio_tipo_violacao",
    ]
}
