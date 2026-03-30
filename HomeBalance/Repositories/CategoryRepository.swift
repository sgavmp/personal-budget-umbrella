import SwiftData
import Foundation

// MARK: - Protocol

protocol CategoryRepositoryProtocol {
    func fetchAll(for household: Household, context: ModelContext) throws -> [Category]
    func fetchExpense(for household: Household, context: ModelContext) throws -> [Category]
    func fetchIncome(for household: Household, context: ModelContext) throws -> [Category]
    func save(_ category: Category, in context: ModelContext) throws
    func delete(_ category: Category, in context: ModelContext) throws
    func addSubcategory(_ subcategory: Subcategory, to category: Category, context: ModelContext) throws
}

// MARK: - Implementation

final class CategoryRepository: CategoryRepositoryProtocol {

    func fetchAll(for household: Household, context: ModelContext) throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let all = try context.fetch(descriptor)
        let householdId = household.id
        return all.filter { $0.household?.id == householdId }
    }

    func fetchExpense(for household: Household, context: ModelContext) throws -> [Category] {
        try fetchAll(for: household, context: context).filter { $0.type == "expense" }
    }

    func fetchIncome(for household: Household, context: ModelContext) throws -> [Category] {
        try fetchAll(for: household, context: context).filter { $0.type == "income" }
    }

    func save(_ category: Category, in context: ModelContext) throws {
        context.insert(category)
        try context.save()
    }

    func delete(_ category: Category, in context: ModelContext) throws {
        context.delete(category)
        try context.save()
    }

    func addSubcategory(_ subcategory: Subcategory, to category: Category, context: ModelContext) throws {
        subcategory.category = category
        context.insert(subcategory)
        try context.save()
    }
}
