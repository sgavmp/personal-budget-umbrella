import SwiftData
import Foundation

@Model
final class Household {
    var id: UUID = UUID()
    var name: String = ""
    /// ISO 4217 currency code, e.g. "EUR", "USD".
    var currency: String = "EUR"
    var createdDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Member.household)
    var members: [Member] = []

    @Relationship(deleteRule: .cascade, inverse: \BankAccount.household)
    var bankAccounts: [BankAccount] = []

    @Relationship(deleteRule: .cascade, inverse: \Category.household)
    var categories: [Category] = []

    @Relationship(deleteRule: .cascade, inverse: \Budget.household)
    var budgets: [Budget] = []

    @Relationship(deleteRule: .cascade, inverse: \ImportMapping.household)
    var importMappings: [ImportMapping] = []

    @Relationship(deleteRule: .cascade, inverse: \CategoryRule.household)
    var categoryRules: [CategoryRule] = []

    init(name: String, currency: String = "EUR") {
        self.name = name
        self.currency = currency
    }
}
