import Foundation

struct AddFamilyMemberCommand: Sendable {
  let patientPersonId: String
  let memberPersonId: String
  let relationship: String
  let isResiding: Bool
  let isCaregiver: Bool
}
