import Testing
import SwiftData
import Foundation
@testable import HomeBalance

@Suite("TransactionRepository")
@MainActor
struct TransactionRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(ModelVersion.v1.models), configurations: [config])
    }

    private func makeHousehold(in context: ModelContext) -> Household {
        let household = Household(name: "Test Household", currency: "EUR")
        context.insert(household)
        return household
    }

    private func makeAccount(for household: Household, in context: ModelContext) -> BankAccount {
        let account = BankAccount(name: "Main Account", bankName: "Test Bank")
        account.household = household
        context.insert(account)
        household.bankAccounts.append(account)
        return account
    }

    private func date(year: Int, month: Int, day: Int = 15) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Tests

    @Test("fetchAll returns only transactions belonging to the household")
    func fetchAllFiltersToHousehold() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let h1 = makeHousehold(in: context)
        let h2 = makeHousehold(in: context)
        let acc1 = makeAccount(for: h1, in: context)
        let acc2 = makeAccount(for: h2, in: context)

        let t1 = Transaction(date: date(year: 2024, month: 1), amount: -50, descriptionText: "A")
        t1.account = acc1
        let t2 = Transaction(date: date(year: 2024, month: 1), amount: -30, descriptionText: "B")
        t2.account = acc2
        context.insert(t1); context.insert(t2)

        let repo = TransactionRepository()
        let result = try repo.fetchAll(for: h1, context: context)
        #expect(result.count == 1)
        #expect(result.first?.descriptionText == "A")
    }

    @Test("fetch(year:month:) returns only transactions in that month")
    func fetchByMonth() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = makeHousehold(in: context)
        let account = makeAccount(for: household, in: context)

        let janTx = Transaction(date: date(year: 2024, month: 1), amount: -50, descriptionText: "Jan")
        janTx.account = account
        let febTx = Transaction(date: date(year: 2024, month: 2), amount: -100, descriptionText: "Feb")
        febTx.account = account
        context.insert(janTx); context.insert(febTx)

        let repo = TransactionRepository()
        let jan = try repo.fetch(year: 2024, month: 1, household: household, context: context)
        #expect(jan.count == 1)
        #expect(jan.first?.descriptionText == "Jan")

        let feb = try repo.fetch(year: 2024, month: 2, household: household, context: context)
        #expect(feb.count == 1)
        #expect(feb.first?.descriptionText == "Feb")
    }

    @Test("save persists a transaction and delete removes it")
    func saveAndDelete() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = makeHousehold(in: context)
        let account = makeAccount(for: household, in: context)

        let repo = TransactionRepository()
        let tx = Transaction(date: Date(), amount: -25, descriptionText: "Coffee")
        tx.account = account
        try repo.save(tx, in: context)

        let all = try repo.fetchAll(for: household, context: context)
        #expect(all.count == 1)

        try repo.delete(tx, in: context)
        let afterDelete = try repo.fetchAll(for: household, context: context)
        #expect(afterDelete.isEmpty)
    }

    @Test("monthlySummary aggregates income and expenses excluding transfers")
    func monthlySummary() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = makeHousehold(in: context)
        let account = makeAccount(for: household, in: context)

        let d = date(year: 2024, month: 3)
        let income  = Transaction(date: d, amount: 2000, descriptionText: "Salary")
        income.account = account
        let expense = Transaction(date: d, amount: -500,  descriptionText: "Rent")
        expense.account = account
        let transfer = Transaction(date: d, amount: -200, descriptionText: "Transfer Out")
        transfer.account = account
        transfer.isTransfer = true
        context.insert(income); context.insert(expense); context.insert(transfer)

        let repo = TransactionRepository()
        let summary = try repo.monthlySummary(year: 2024, month: 3, household: household, context: context)

        #expect(summary.totalIncome == 2000)
        #expect(summary.totalExpenses == 500)   // transfer excluded
        #expect(summary.balance == 1500)
    }

    @Test("monthlySummary balance is correct when only expenses exist")
    func summaryOnlyExpenses() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = makeHousehold(in: context)
        let account = makeAccount(for: household, in: context)

        let d = date(year: 2024, month: 4)
        let e1 = Transaction(date: d, amount: -300, descriptionText: "Groceries")
        e1.account = account
        let e2 = Transaction(date: d, amount: -150, descriptionText: "Fuel")
        e2.account = account
        context.insert(e1); context.insert(e2)

        let repo = TransactionRepository()
        let summary = try repo.monthlySummary(year: 2024, month: 4, household: household, context: context)
        #expect(summary.totalIncome == 0)
        #expect(summary.totalExpenses == 450)
        #expect(summary.balance == -450)
    }

    @Test("search filters by description text")
    func searchByText() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = makeHousehold(in: context)
        let account = makeAccount(for: household, in: context)

        let t1 = Transaction(date: Date(), amount: -10, descriptionText: "Mercadona supermarket")
        t1.account = account
        let t2 = Transaction(date: Date(), amount: -5, descriptionText: "Coffee shop")
        t2.account = account
        context.insert(t1); context.insert(t2)

        let repo = TransactionRepository()
        let results = try repo.search("mercadona", household: household, context: context)
        #expect(results.count == 1)
        #expect(results.first?.descriptionText.contains("Mercadona") == true)
    }
}
