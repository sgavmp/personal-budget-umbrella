import Foundation
import SwiftData

// MARK: - Protocol

protocol CategoryRuleRepositoryProtocol: Sendable {
    func fetchAll(for household: Household, context: ModelContext) throws -> [CategoryRule]
    func fetchEnabled(for household: Household, context: ModelContext) throws -> [CategoryRule]
    func save(_ rule: CategoryRule, in context: ModelContext) throws
    func delete(_ rule: CategoryRule, in context: ModelContext) throws
    func snapshots(for household: Household, context: ModelContext) throws -> [RuleSnapshot]
}

// MARK: - Implementation

struct CategoryRuleRepository: CategoryRuleRepositoryProtocol {

    func fetchAll(for household: Household, context: ModelContext) throws -> [CategoryRule] {
        let householdId = household.id
        var descriptor = FetchDescriptor<CategoryRule>(
            predicate: #Predicate { $0.household?.id == householdId },
            sortBy: [SortDescriptor(\.priority)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.category, \.subcategory]
        return try context.fetch(descriptor)
    }

    func fetchEnabled(for household: Household, context: ModelContext) throws -> [CategoryRule] {
        let householdId = household.id
        let descriptor = FetchDescriptor<CategoryRule>(
            predicate: #Predicate { $0.household?.id == householdId && $0.isEnabled },
            sortBy: [SortDescriptor(\.priority)]
        )
        return try context.fetch(descriptor)
    }

    func save(_ rule: CategoryRule, in context: ModelContext) throws {
        if rule.modelContext == nil {
            context.insert(rule)
        }
        try context.save()
    }

    func delete(_ rule: CategoryRule, in context: ModelContext) throws {
        context.delete(rule)
        try context.save()
    }

    /// Returns `[RuleSnapshot]` — Sendable DTOs safe to pass across actor boundaries.
    func snapshots(for household: Household, context: ModelContext) throws -> [RuleSnapshot] {
        try fetchEnabled(for: household, context: context).map { rule in
            RuleSnapshot(
                id: rule.id,
                field: rule.field,
                matchType: rule.matchType,
                pattern: rule.pattern,
                isNegative: rule.isNegative,
                priority: rule.priority,
                amountMin: rule.amountMin,
                amountMax: rule.amountMax,
                isEnabled: rule.isEnabled,
                categoryId: rule.category?.id,
                categoryName: rule.category?.name,
                subcategoryId: rule.subcategory?.id
            )
        }
    }
}
