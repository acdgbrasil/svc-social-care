import JWT
import Vapor

struct ZitadelJWTPayload: JWTPayload {
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var iss: IssuerClaim
    var aud: AudienceClaim
    var projectRoles: [String: [String: String]]?

    enum CodingKeys: String, CodingKey {
        case sub, exp, iss, aud
        case projectRoles = "urn:zitadel:iam:org:project:roles"
    }

    private static let expectedIssuer = Environment.get("ZITADEL_ISSUER") ?? "https://auth.acdgbrasil.com.br"
    private static let expectedAudience = Environment.get("ZITADEL_PROJECT_ID") ?? "363110312318140539"

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
        guard iss.value == Self.expectedIssuer else {
            throw JWTError.claimVerificationFailure(
                failedClaim: iss, reason: "token issuer '\(iss.value)' does not match expected '\(Self.expectedIssuer)'"
            )
        }
        try aud.verifyIntendedAudience(includes: Self.expectedAudience)
    }

    var roleNames: Set<String> {
        guard let projectRoles else { return [] }
        return Set(projectRoles.keys)
    }
}
