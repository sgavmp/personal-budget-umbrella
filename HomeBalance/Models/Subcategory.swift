import SwiftData
import Foundation

@Model
final class Subcategory {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0

    var category: Category? = nil

    @Relationship(deleteRule: .cascade, inverse: \CategoryRule.subcategory)
    var rules: [CategoryRule] = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.subcategory)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade, inverse: \Budget.subcategory)
    var budgets: [Budget] = []

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
