import Testing
import SwiftData
import Foundation
@testable import HomeBalance

@Suite("DashboardViewModel")
@MainActor
struct DashboardViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(ModelVersion.v1.models), configurations: [config])
    }

    private func date(year: Int, month: Int, day: Int = 10) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Tests

    @Test("loadData populates summary and recent transactions")
    func loadDataPopulates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = Household(name: "Test", currency: "EUR")
        context.insert(household)
        let account = BankAccount(name: "Main", bankName: "Bank")
        account.household = household
        context.insert(account)
        household.bankAccounts.append(account)

        let d = date(year: 2024, month: 5)
        let income = Transaction(date: d, amount: 1000, descriptionText: "Salary")
        income.account = account
        let expense = Transaction(date: d, amount: -200, descriptionText: "Groceries")
        expense.account = account
        context.insert(income); context.insert(expense)

        let vm = DashboardViewModel()
        vm.selectedDate = d
        vm.loadData(for: household, context: context)

        #expect(vm.summary != nil)
        #expect(vm.summary?.totalIncome == 1000)
        #expect(vm.summary?.totalExpenses == 200)
        #expect(!vm.recentTransactions.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadData returns zero totals for empty month")
    func emptyMonthReturnsZeroTotals() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = Household(name: "Test", currency: "EUR")
        context.insert(household)

        let vm = DashboardViewModel()
        vm.selectedDate = date(year: 2024, month: 1)
        vm.loadData(for: household, context: context)

        #expect(vm.summary?.totalIncome == 0)
        #expect(vm.summary?.totalExpenses == 0)
        #expect(vm.recentTransactions.isEmpty)
    }

    @Test("goToPreviousMonth decrements month")
    func previousMonth() throws {
        let vm = DashboardViewModel()
        vm.selectedDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        vm.goToPreviousMonth()
        let comps = Calendar.current.dateComponents([.year, .month], from: vm.selectedDate)
        #expect(comps.month == 5)
        #expect(comps.year == 2024)
    }

    @Test("goToNextMonth is blocked for current/future months")
    func nextMonthBlocked() throws {
        let vm = DashboardViewModel()
        // Set to current month
        vm.selectedDate = Date()
        #expect(!vm.canGoForward)
        vm.goToNextMonth()
        // Date should not change
        let cal = Calendar.current
        let before = cal.dateComponents([.year, .month], from: Date())
        let after  = cal.dateComponents([.year, .month], from: vm.selectedDate)
        #expect(before.year == after.year)
        #expect(before.month == after.month)
    }

    @Test("transfers are excluded from summary totals")
    func transfersExcluded() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = Household(name: "Test", currency: "EUR")
        context.insert(household)
        let account = BankAccount(name: "A", bankName: "Bank")
        account.household = household
        context.insert(account)
        household.bankAccounts.append(account)

        let d = date(year: 2024, month: 7)
        let expense = Transaction(date: d, amount: -100, descriptionText: "Rent")
        expense.account = account
        let transfer = Transaction(date: d, amount: -500, descriptionText: "Move money")
        transfer.account = account
        transfer.isTransfer = true
        context.insert(expense); context.insert(transfer)

        let vm = DashboardViewModel()
        vm.selectedDate = d
        vm.loadData(for: household, context: context)

        #expect(vm.summary?.totalExpenses == 100)
    }
}
