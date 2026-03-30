import SwiftData
import Foundation

/// Monthly budget allocation for a Category (and optionally a Subcategory).
/// Year and month are stored as integers to avoid timezone-related ambiguity.
@Model
final class Budget {
    var id: UUID = UUID()
    var year: Int = 0
    var month: Int = 0
    var plannedAmount: Decimal = 0

    var household: Household? = nil
    var category: Category? = nil
    /// nil = budget applies to the whole category, not a specific subcategory.
    var subcategory: Subcategory? = nil

    init(year: Int, month: Int, plannedAmount: Decimal) {
        self.year = year
        self.month = month
        self.plannedAmount = plannedAmount
    }
}
