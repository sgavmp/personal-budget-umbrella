import SwiftData
import Foundation

@Model
final class Member {
    var id: UUID = UUID()
    var name: String = ""
    var email: String? = nil
    /// Hex color string for UI display, e.g. "#FF5733".
    var color: String = "#5856D6"
    var createdDate: Date = Date()

    var household: Household? = nil

    @Relationship(inverse: \BankAccount.members)
    var bankAccounts: [BankAccount] = []

    init(name: String, email: String? = nil, color: String = "#5856D6") {
        self.name = name
        self.email = email
        self.color = color
    }
}
