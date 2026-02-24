import Foundation

/// Um Value Object que representa uma coleção de benefícios sociais.
///
/// Garante a unicidade de benefícios por nome e fornece propriedades de agregação.
public struct SocialBenefitsCollection: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Lista imutável de benefícios.
    public let items: [SocialBenefit]

    // MARK: - Initializer

    /// Inicializa uma coleção validada de benefícios.
    ///
    /// - Parameter benefits: Array de benefícios (não pode conter nomes duplicados).
    /// - Throws: `SocialBenefitsCollectionError` em caso de erro.
    public init(_ benefits: [SocialBenefit]) throws {
        if benefits.isEmpty {
            self.items = []
            return
        }

        var seenNames = Set<String>()
        for benefit in benefits {
            guard !seenNames.contains(benefit.benefitName) else {
                throw SocialBenefitsCollectionError.duplicateBenefitNotAllowed(name: benefit.benefitName)
            }
            seenNames.insert(benefit.benefitName)
        }

        self.items = benefits
    }

    // MARK: - Instance Computed Properties
    
    /// Indica se a coleção não possui itens.
    public var isEmpty: Bool { items.isEmpty }

    /// O número total de benefícios na coleção.
    public var count: Int { items.count }

    /// A soma monetária total de todos os benefícios da coleção.
    public var totalAmount: Double {
        items.reduce(0.0) { $0 + $1.amount }
    }
}
