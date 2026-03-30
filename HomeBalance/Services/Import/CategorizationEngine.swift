import Foundation
import SwiftData

// MARK: - Categorization Result

struct CategorizationResult: Sendable {
    let categoryId: UUID?
    let subcategoryId: UUID?
    let categoryName: String?
    let matchedRule: UUID?   // rule.id that fired
}

// MARK: - Rule Snapshot (Sendable DTO)

/// Lightweight copy of a `CategoryRule` that can cross actor boundaries.
struct RuleSnapshot: Sendable {
    let id: UUID
    let field: String
    let matchType: String
    let pattern: String
    let isNegative: Bool
    let priority: Int
    let amountMin: Decimal?
    let amountMax: Decimal?
    let isEnabled: Bool
    let categoryId: UUID?
    let categoryName: String?
    let subcategoryId: UUID?
}

// MARK: - Categorization Engine

/// Applies a sorted list of `RuleSnapshot` objects to a transaction description/notes/payee.
/// The first positive rule that matches wins; negative rules veto a match.
struct CategorizationEngine: Sendable {

    /// Apply all enabled rules (sorted by priority ascending) to the given row.
    /// Returns the winning categorisation, or a nil-id result if no rule matched.
    func categorise(row: ImportedRow, rules: [RuleSnapshot]) -> CategorizationResult {
        let sorted = rules
            .filter(\.isEnabled)
            .sorted { $0.priority < $1.priority }

        for rule in sorted {
            let text = fieldValue(for: rule.field, in: row)
            let matched = evaluate(rule: rule, text: text, amount: row.amount)

            if rule.isNegative {
                // Negative rule: if it fires, stop matching entirely
                if matched { break }
            } else if matched {
                return CategorizationResult(
                    categoryId: rule.categoryId,
                    subcategoryId: rule.subcategoryId,
                    categoryName: rule.categoryName,
                    matchedRule: rule.id
                )
            }
        }

        return CategorizationResult(categoryId: nil, subcategoryId: nil, categoryName: nil, matchedRule: nil)
    }

    // MARK: - Rule evaluation

    private func evaluate(rule: RuleSnapshot, text: String, amount: Decimal?) -> Bool {
        // Amount range filter
        if let min = rule.amountMin, let a = amount, a < min { return false }
        if let max = rule.amountMax, let a = amount, a > max { return false }

        let t = text.normalised
        let p = rule.pattern.normalised

        switch rule.matchType {
        case CategoryRule.MatchType.contains.rawValue:
            return t.contains(p)
        case CategoryRule.MatchType.exact.rawValue:
            return t == p
        case CategoryRule.MatchType.startsWith.rawValue:
            return t.hasPrefix(p)
        case CategoryRule.MatchType.endsWith.rawValue:
            return t.hasSuffix(p)
        case CategoryRule.MatchType.regex.rawValue:
            return (try? NSRegularExpression(pattern: rule.pattern, options: .caseInsensitive))
                .map { $0.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil }
                ?? false
        default:
            return t.contains(p)
        }
    }

    private func fieldValue(for field: String, in row: ImportedRow) -> String {
        switch field {
        case CategoryRule.Field.description.rawValue: return row.descriptionText
        case CategoryRule.Field.notes.rawValue:       return row.notes ?? ""
        default:                                       return row.descriptionText
        }
    }
}

// MARK: - Rule Impact Calculator

/// Given a rule and a list of staged rows, returns how many rows the rule would match.
struct RuleImpactCalculator: Sendable {
    let engine: CategorizationEngine

    func impact(of rule: RuleSnapshot, on rows: [ImportedRow]) -> (count: Int, totalAmount: Decimal) {
        var count = 0
        var total: Decimal = 0
        for row in rows {
            let result = engine.categorise(row: row, rules: [rule])
            if result.matchedRule != nil {
                count += 1
                total += abs(row.amount ?? 0)
            }
        }
        return (count, total)
    }
}
