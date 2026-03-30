import SwiftData
import Foundation

/// Auto-categorization rule attached to a Category or Subcategory.
/// Rules are evaluated in ascending `priority` order; the first positive
/// match that passes all filters wins.
@Model
final class CategoryRule {
    var id: UUID = UUID()
    /// Field to evaluate: "description", "payee", "notes"
    var field: String = "description"
    /// Match strategy: "contains", "exact", "startsWith", "endsWith", "regex"
    var matchType: String = "contains"
    /// The text or regular expression pattern.
    var pattern: String = ""
    /// When true this is an exclusion rule: if the pattern matches, skip this category.
    var isNegative: Bool = false
    /// Lower number = higher priority. First winning positive rule is used.
    var priority: Int = 100
    /// Optional lower bound for the transaction amount filter.
    var amountMin: Decimal? = nil
    /// Optional upper bound for the transaction amount filter.
    var amountMax: Decimal? = nil
    var isEnabled: Bool = true

    var household: Household? = nil
    var category: Category? = nil
    /// nil means the rule assigns only the category (no subcategory).
    var subcategory: Subcategory? = nil

    init(
        field: String = "description",
        matchType: String = "contains",
        pattern: String,
        isNegative: Bool = false,
        priority: Int = 100,
        amountMin: Decimal? = nil,
        amountMax: Decimal? = nil,
        isEnabled: Bool = true
    ) {
        self.field = field
        self.matchType = matchType
        self.pattern = pattern
        self.isNegative = isNegative
        self.priority = priority
        self.amountMin = amountMin
        self.amountMax = amountMax
        self.isEnabled = isEnabled
    }
}

// MARK: - Typed helpers

extension CategoryRule {
    enum Field: String, CaseIterable {
        case description
        case payee
        case notes
    }

    enum MatchType: String, CaseIterable {
        case contains
        case exact
        case startsWith
        case endsWith
        case regex
    }
}
