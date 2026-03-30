import SwiftData
import Foundation

@Model
final class BankAccount {
    var id: UUID = UUID()
    var name: String = ""
    var bankName: String = ""
    var lastFourDigits: String? = nil
    /// "checking", "savings", "credit"
    var accountType: String = "checking"
    var createdDate: Date = Date()

    var household: Household? = nil
    var members: [Member] = []

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade, inverse: \ImportBatch.account)
    var importBatches: [ImportBatch] = []

    init(
        name: String,
        bankName: String,
        lastFourDigits: String? = nil,
        accountType: String = "checking"
    ) {
        self.name = name
        self.bankName = bankName
        self.lastFourDigits = lastFourDigits
        self.accountType = accountType
    }
}
