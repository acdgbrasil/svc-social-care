import Foundation

protocol AddFamilyMemberUseCase: Sendable {
    func execute(command: AddFamilyMemberCommand) async throws(AddFamilyMemberError)
}
