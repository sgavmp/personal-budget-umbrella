import Testing
import Foundation
@testable import HomeBalance

@Suite("CategorizationEngine")
@MainActor
struct CategorizationEngineTests {

    private let engine = CategorizationEngine()
    private let catId = UUID()
    private let subId = UUID()

    private func row(desc: String, amount: Decimal = -10) -> ImportedRow {
        ImportedRow(
            id: 0, rowIndex: 0,
            date: Date(), valueDate: nil,
            amount: amount, descriptionText: desc,
            externalId: nil, notes: nil, rawColumns: []
        )
    }

    private func rule(
        pattern: String,
        matchType: CategoryRule.MatchType = .contains,
        field: CategoryRule.Field = .description,
        priority: Int = 100,
        isNegative: Bool = false
    ) -> RuleSnapshot {
        RuleSnapshot(
            id: UUID(), field: field.rawValue, matchType: matchType.rawValue,
            pattern: pattern, isNegative: isNegative, priority: priority,
            amountMin: nil, amountMax: nil, isEnabled: true,
            categoryId: catId, categoryName: "Dining", subcategoryId: subId
        )
    }

    @Test("Contains match fires")
    func containsMatch() {
        let result = engine.categorise(row: row(desc: "STARBUCKS COFFEE"), rules: [rule(pattern: "starbucks")])
        #expect(result.categoryId == catId)
    }

    @Test("Exact match requires full equality")
    func exactMatch() {
        let result = engine.categorise(row: row(desc: "NETFLIX"), rules: [rule(pattern: "netflix", matchType: .exact)])
        #expect(result.categoryId == catId)
    }

    @Test("Exact match does not fire on partial")
    func exactMatchPartialFails() {
        let result = engine.categorise(row: row(desc: "NETFLIX INC"), rules: [rule(pattern: "netflix", matchType: .exact)])
        #expect(result.categoryId == nil)
    }

    @Test("StartsWith match")
    func startsWithMatch() {
        let result = engine.categorise(row: row(desc: "Amazon Prime Video"), rules: [rule(pattern: "amazon", matchType: .startsWith)])
        #expect(result.categoryId == catId)
    }

    @Test("Regex match")
    func regexMatch() {
        let result = engine.categorise(row: row(desc: "MERCADONA 0123"), rules: [rule(pattern: "mercadona \\d+", matchType: .regex)])
        #expect(result.categoryId == catId)
    }

    @Test("Lower priority wins over higher number")
    func priorityOrder() {
        let r1 = RuleSnapshot(id: UUID(), field: "description", matchType: "contains",
                              pattern: "coffee", isNegative: false, priority: 10,
                              amountMin: nil, amountMax: nil, isEnabled: true,
                              categoryId: catId, categoryName: "Dining", subcategoryId: nil)
        let r2 = RuleSnapshot(id: UUID(), field: "description", matchType: "contains",
                              pattern: "coffee", isNegative: false, priority: 50,
                              amountMin: nil, amountMax: nil, isEnabled: true,
                              categoryId: UUID(), categoryName: "Other", subcategoryId: nil)
        let result = engine.categorise(row: row(desc: "Costa Coffee"), rules: [r2, r1])
        #expect(result.categoryId == catId)    // r1 (priority 10) wins
    }

    @Test("Negative rule vetoes match")
    func negativeRuleVetoes() {
        let negRule = rule(pattern: "refund", isNegative: true)
        let posRule = rule(pattern: "amazon")
        let result = engine.categorise(row: row(desc: "amazon refund"), rules: [negRule, posRule])
        #expect(result.categoryId == nil)
    }

    @Test("Disabled rules are skipped")
    func disabledRuleSkipped() {
        var disabledRule = rule(pattern: "starbucks")
        let r = RuleSnapshot(
            id: disabledRule.id, field: disabledRule.field, matchType: disabledRule.matchType,
            pattern: disabledRule.pattern, isNegative: disabledRule.isNegative,
            priority: disabledRule.priority, amountMin: nil, amountMax: nil, isEnabled: false,
            categoryId: catId, categoryName: "Dining", subcategoryId: nil
        )
        _ = disabledRule  // suppress warning
        let result = engine.categorise(row: row(desc: "STARBUCKS"), rules: [r])
        #expect(result.categoryId == nil)
    }

    @Test("No rules returns nil category")
    func noRulesReturnsNil() {
        let result = engine.categorise(row: row(desc: "anything"), rules: [])
        #expect(result.categoryId == nil)
    }
}
