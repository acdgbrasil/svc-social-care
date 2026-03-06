import Foundation

/// Modelo auxiliar para processamento analítico de educação no domínio.
public struct EducationalMember: Sendable {
    public let personId: PersonId
    public let birthDate: TimeStamp
    public let attendsSchool: Bool
    public let canReadWrite: Bool
    
    public init(personId: PersonId, birthDate: TimeStamp, attendsSchool: Bool, canReadWrite: Bool) {
        self.personId = personId
        self.birthDate = birthDate
        self.attendsSchool = attendsSchool
        self.canReadWrite = canReadWrite
    }
}
