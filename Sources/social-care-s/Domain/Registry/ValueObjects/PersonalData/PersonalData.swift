import Foundation

/// Value Object com dados pessoais basicos do paciente.
public struct PersonalData: Codable, Equatable, Hashable, Sendable {
    public enum Sex: String, Codable, Equatable, Hashable, Sendable {
        case masculino
        case feminino
        case outro
    }

    public let firstName: String
    public let lastName: String
    public let motherName: String
    public let nationality: String
    public let sex: Sex
    public let socialName: String?
    public let birthDate: TimeStamp
    /// Telefone de contato. Normalizado (trim), sem validação de formato.
    public let phone: String?

    public init(
        firstName: String,
        lastName: String,
        motherName: String,
        nationality: String,
        sex: Sex,
        socialName: String?,
        birthDate: TimeStamp,
        phone: String? = nil,
        now: TimeStamp = .now
    ) throws {
        let normalizedFirstName = Self.normalizeName(firstName)
        guard !normalizedFirstName.isEmpty else {
            throw PersonalDataError.firstNameEmpty
        }

        let normalizedLastName = Self.normalizeName(lastName)
        guard !normalizedLastName.isEmpty else {
            throw PersonalDataError.lastNameEmpty
        }

        let normalizedMotherName = Self.normalizeName(motherName)
        guard !normalizedMotherName.isEmpty else {
            throw PersonalDataError.motherNameEmpty
        }

        let normalizedNationality = Self.normalizeName(nationality)
        guard !normalizedNationality.isEmpty else {
            throw PersonalDataError.nationalityEmpty
        }

        let normalizedSocialName = socialName.map(Self.normalizeName)
        let sanitizedSocialName = normalizedSocialName?.isEmpty == true ? nil : normalizedSocialName

        guard birthDate.date <= now.date else {
            throw PersonalDataError.birthDateInFuture(
                date: birthDate.toISOString(),
                now: now.toISOString()
            )
        }

        let normalizedPhone = phone.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let sanitizedPhone = normalizedPhone?.isEmpty == true ? nil : normalizedPhone

        self.firstName = normalizedFirstName
        self.lastName = normalizedLastName
        self.motherName = normalizedMotherName
        self.nationality = normalizedNationality
        self.sex = sex
        self.socialName = sanitizedSocialName
        self.birthDate = birthDate
        self.phone = sanitizedPhone
    }

    private static func normalizeName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
