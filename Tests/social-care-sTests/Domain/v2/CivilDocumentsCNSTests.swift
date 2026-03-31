import Testing
@testable import social_care_s
import Foundation

@Suite("CivilDocuments — CNS Integration Tests")
struct CivilDocumentsCNSTests {

    private static let validCPF = try! CPF("123.456.789-09")
    private static let otherCPF = try! CPF("987.654.321-00")
    private static let validCNSNumber = "700000000000005"

    @Test("Deve aceitar CivilDocuments apenas com CNS")
    func cnsOnly() throws {
        let cns = try CNS(number: Self.validCNSNumber, cpf: Self.validCPF)
        let docs = try CivilDocuments(cpf: nil, nis: nil, rgDocument: nil, cns: cns)
        #expect(docs.cns != nil)
        #expect(docs.cpf == nil)
    }

    @Test("Deve aceitar CivilDocuments com CPF e CNS iguais")
    func matchingCPF() throws {
        let cns = try CNS(number: Self.validCNSNumber, cpf: Self.validCPF)
        let docs = try CivilDocuments(cpf: Self.validCPF, nis: nil, rgDocument: nil, cns: cns)
        #expect(docs.cpf == docs.cns?.cpf)
    }

    @Test("Deve rejeitar CivilDocuments com CPF divergente do CNS")
    func mismatchedCPF() {
        #expect(throws: CivilDocumentsError.cpfMismatchWithCNS) {
            let cns = try CNS(number: Self.validCNSNumber, cpf: Self.validCPF)
            _ = try CivilDocuments(cpf: Self.otherCPF, nis: nil, rgDocument: nil, cns: cns)
        }
    }

    @Test("Deve manter retrocompatibilidade — CivilDocuments sem CNS")
    func backwardsCompatibility() throws {
        let docs = try CivilDocuments(cpf: Self.validCPF, nis: nil, rgDocument: nil)
        #expect(docs.cns == nil)
    }

    @Test("AppError mapping para cpfMismatchWithCNS")
    func mismatchAppError() {
        let err = CivilDocumentsError.cpfMismatchWithCNS.asAppError
        #expect(err.code == "CVD-002")
    }
}
