import JWT

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

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }

    var roleNames: Set<String> {
        guard let projectRoles else { return [] }
        return Set(projectRoles.keys)
    }
}
