import SwiftData
import Foundation

// MARK: - Protocol

protocol BudgetRepositoryProtocol {
    func fetchAll(for household: Household, context: ModelContext) throws -> [Budget]
    func fetch(year: Int, month: Int, household: Household, context: ModelContext) throws -> [Budget]
    func fetch(year: Int, month: Int, category: Category, context: ModelContext) throws -> Budget?
    func save(_ budget: Budget, in context: ModelContext) throws
    func delete(_ budget: Budget, in context: ModelContext) throws
    func copyMonth(fromYear: Int, fromMonth: Int, toYear: Int, toMonth: Int, household: Household, context: ModelContext) throws -> [Budget]
}

// MARK: - Implementation

final class BudgetRepository: BudgetRepositoryProtocol {

    func fetchAll(for household: Household, context: ModelContext) throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>()
        let all = try context.fetch(descriptor)
        let householdId = household.id
        return all.filter { $0.household?.id == householdId }
    }

    func fetch(year: Int, month: Int, household: Household, context: ModelContext) throws -> [Budget] {
        try fetchAll(for: household, context: context).filter {
            $0.year == year && $0.month == month
        }
    }

    func fetch(year: Int, month: Int, category: Category, context: ModelContext) throws -> Budget? {
        let descriptor = FetchDescriptor<Budget>()
        let all = try context.fetch(descriptor)
        let categoryId = category.id
        return all.first {
            $0.year == year && $0.month == month &&
            $0.category?.id == categoryId &&
            $0.subcategory == nil
        }
    }

    func save(_ budget: Budget, in context: ModelContext) throws {
        context.insert(budget)
        try context.save()
    }

    func delete(_ budget: Budget, in context: ModelContext) throws {
        context.delete(budget)
        try context.save()
    }

    /// Duplicates all budget entries from one month to another, skipping already-existing entries.
    func copyMonth(fromYear: Int, fromMonth: Int, toYear: Int, toMonth: Int, household: Household, context: ModelContext) throws -> [Budget] {
        let source = try fetch(year: fromYear, month: fromMonth, household: household, context: context)
        let existing = try fetch(year: toYear, month: toMonth, household: household, context: context)
        let existingKeys = Set(existing.compactMap { b -> String? in
            guard let catId = b.category?.id else { return nil }
            let subId = b.subcategory?.id.uuidString ?? "nil"
            return "\(catId)-\(subId)"
        })

        var created: [Budget] = []
        for original in source {
            guard let cat = original.category else { continue }
            let subId = original.subcategory?.id.uuidString ?? "nil"
            let key = "\(cat.id)-\(subId)"
            guard !existingKeys.contains(key) else { continue }

            let copy = Budget(year: toYear, month: toMonth, plannedAmount: original.plannedAmount)
            copy.household = original.household
            copy.category = cat
            copy.subcategory = original.subcategory
            context.insert(copy)
            created.append(copy)
        }
        try context.save()
        return created
    }
}
