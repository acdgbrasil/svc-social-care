import Foundation

/// Projeções analíticas sobre o Agregado Familiar.
public struct FamilyAnalytics: Sendable {
    
    public enum AgeRange: String, Sendable {
        case range0to6
        case range7to14
        case range15to17
        case range18to29
        case range30to59
        case range60to64
        case range65to69
        case range70Plus
    }
    
    public struct AgeProfile: Sendable {
        private var counts: [AgeRange: Int] = [:]
        
        public mutating func increment(for range: AgeRange) {
            counts[range, default: 0] += 1
        }
        
        public func count(for range: AgeRange) -> Int {
            return counts[range] ?? 0
        }
    }
    
    /// Gera o perfil etário de uma lista de membros da família.
    public static func calculateAgeProfile(from members: [FamilyMember], at now: TimeStamp) -> AgeProfile {
        var profile = AgeProfile()
        
        for member in members {
            let age = member.birthDate.years(at: now)
            
            switch age {
            case 0...6: profile.increment(for: .range0to6)
            case 7...14: profile.increment(for: .range7to14)
            case 15...17: profile.increment(for: .range15to17)
            case 18...29: profile.increment(for: .range18to29)
            case 30...59: profile.increment(for: .range30to59)
            case 60...64: profile.increment(for: .range60to64)
            case 65...69: profile.increment(for: .range65to69)
            default: profile.increment(for: .range70Plus)
            }
        }
        
        return profile
    }
}
