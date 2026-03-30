import SwiftData
import Foundation

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    /// SF Symbol name for the icon, e.g. "fork.knife", "car.fill".
    var icon: String = "questionmark.circle"
    /// Hex color string, e.g. "#FF9500".
    var color: String = "#8E8E93"
    /// "expense", "income", or "transfer" (system-managed, not user-editable).
    var type: String = "expense"
    var sortOrder: Int = 0
    /// System categories (like "Internal Transfer") cannot be deleted or renamed.
    var isSystem: Bool = false

    var household: Household? = nil

    @Relationship(deleteRule: .cascade, inverse: \Subcategory.category)
    var subcategories: [Subcategory] = []

    @Relationship(deleteRule: .nullify, inverse: \CategoryRule.category)
    var rules: [CategoryRule] = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade, inverse: \Budget.category)
    var budgets: [Budget] = []

    init(
        name: String,
        icon: String = "questionmark.circle",
        color: String = "#8E8E93",
        type: String = "expense",
        sortOrder: Int = 0,
        isSystem: Bool = false
    ) {
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.sortOrder = sortOrder
        self.isSystem = isSystem
    }
}
