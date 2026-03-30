import Testing
import SwiftData
import Foundation
@testable import HomeBalance

// Disambiguate from Testing.Category
typealias HBCategory = HomeBalance.Category

@Suite("BudgetRepository")
@MainActor
struct BudgetRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(ModelVersion.v1.models), configurations: [config])
    }

    private func makeHouseholdWithCategory(in context: ModelContext) throws -> (Household, HBCategory) {
        let household = Household(name: "Test", currency: "EUR")
        context.insert(household)
        try DefaultCategorySeeder.seed(into: household, context: context)
        let cat = household.categories.first { $0.type == "expense" }!
        return (household, cat)
    }

    // MARK: - Tests

    @Test("Saving a budget and fetching it back by month")
    func saveAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let (household, cat) = try makeHouseholdWithCategory(in: context)

        let budget = Budget(year: 2024, month: 3, plannedAmount: 500)
        budget.household = household
        budget.category = cat

        let repo = BudgetRepository()
        try repo.save(budget, in: context)

        let fetched = try repo.fetch(year: 2024, month: 3, household: household, context: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.plannedAmount == 500)
    }

    @Test("copyMonth duplicates budgets to the target month")
    func copyMonth() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let (household, cat) = try makeHouseholdWithCategory(in: context)

        let b1 = Budget(year: 2024, month: 1, plannedAmount: 300)
        b1.household = household; b1.category = cat

        let repo = BudgetRepository()
        try repo.save(b1, in: context)

        let copied = try repo.copyMonth(
            fromYear: 2024, fromMonth: 1,
            toYear: 2024, toMonth: 2,
            household: household, context: context
        )
        #expect(copied.count >= 1)

        let february = try repo.fetch(year: 2024, month: 2, household: household, context: context)
        #expect(!february.isEmpty)
    }

    @Test("copyMonth does not duplicate already-existing entries")
    func copyMonthIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let (household, cat) = try makeHouseholdWithCategory(in: context)

        let src = Budget(year: 2024, month: 5, plannedAmount: 200)
        src.household = household; src.category = cat
        let existing = Budget(year: 2024, month: 6, plannedAmount: 999)
        existing.household = household; existing.category = cat

        let repo = BudgetRepository()
        try repo.save(src, in: context)
        try repo.save(existing, in: context)

        let first = try repo.copyMonth(
            fromYear: 2024, fromMonth: 5,
            toYear: 2024, toMonth: 6,
            household: household, context: context
        )
        #expect(first.isEmpty)  // already exists, nothing new created

        let june = try repo.fetch(year: 2024, month: 6, household: household, context: context)
        #expect(june.count == 1)
        #expect(june.first?.plannedAmount == 999)  // existing value preserved
    }

    @Test("delete removes a budget")
    func deleteBudget() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let (household, cat) = try makeHouseholdWithCategory(in: context)

        let budget = Budget(year: 2024, month: 7, plannedAmount: 100)
        budget.household = household; budget.category = cat
        let repo = BudgetRepository()
        try repo.save(budget, in: context)

        try repo.delete(budget, in: context)
        let result = try repo.fetch(year: 2024, month: 7, household: household, context: context)
        #expect(result.isEmpty)
    }
}
