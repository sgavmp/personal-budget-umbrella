import Testing
import SwiftData
@testable import HomeBalance

/// Tests for DefaultCategorySeeder.
/// Marking the whole suite @MainActor avoids the need for async/await and
/// works around a runtime crash in Swift Testing on Xcode 26 beta when mixing
/// `async throws` test functions with `MainActor.run`.
@Suite("DefaultCategorySeeder")
@MainActor
struct DefaultCategorySeederTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Schema(ModelVersion.v1.models),
            configurations: [config]
        )
    }

    private func makeHousehold(in context: ModelContext) throws -> Household {
        let household = Household(name: "Test Household", currency: "EUR")
        context.insert(household)
        try DefaultCategorySeeder.seed(into: household, context: context)
        return household
    }

    // MARK: - Tests

    @Test("Seeds non-empty category list into a new household")
    func seedsFillsCategories() throws {
        let container = try makeContainer()
        let household = try makeHousehold(in: container.mainContext)
        #expect(!household.categories.isEmpty)
    }

    @Test("Creates the Internal Transfer system category")
    func systemTransferCategoryExists() throws {
        let container = try makeContainer()
        let household = try makeHousehold(in: container.mainContext)
        let transfer = household.categories.first { $0.type == "transfer" }
        #expect(transfer != nil)
        #expect(transfer?.isSystem == true)
    }

    @Test("Seeds both expense and income categories")
    func seedsBothTypes() throws {
        let container = try makeContainer()
        let household = try makeHousehold(in: container.mainContext)
        let hasExpense = household.categories.contains { $0.type == "expense" }
        let hasIncome  = household.categories.contains { $0.type == "income" }
        #expect(hasExpense)
        #expect(hasIncome)
    }

    @Test("Each expense category has at least one subcategory")
    func expenseCategoriesHaveSubcategories() throws {
        let container = try makeContainer()
        let household = try makeHousehold(in: container.mainContext)
        let expenseCategories = household.categories.filter { $0.type == "expense" }
        for category in expenseCategories {
            #expect(!category.subcategories.isEmpty, "Category '\(category.name)' has no subcategories")
        }
    }

    @Test("Calling seed twice does not duplicate categories")
    func seedIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = Household(name: "Idempotency Test", currency: "EUR")
        context.insert(household)

        try DefaultCategorySeeder.seed(into: household, context: context)
        let countAfterFirst = household.categories.count

        try DefaultCategorySeeder.seed(into: household, context: context)
        let countAfterSecond = household.categories.count

        #expect(countAfterFirst == countAfterSecond)
    }

    @Test("Creates at least 10 expense categories from DefaultCategories.json")
    func hasEnoughExpenseCategories() throws {
        let container = try makeContainer()
        let household = try makeHousehold(in: container.mainContext)
        let expenseCount = household.categories.filter { $0.type == "expense" }.count
        #expect(expenseCount >= 10)
    }
}
