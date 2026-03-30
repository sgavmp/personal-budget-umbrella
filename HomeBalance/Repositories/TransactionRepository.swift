import SwiftData
import Foundation

// MARK: - Monthly Summary

/// Aggregated figures for a given month, excluding internal transfers.
struct MonthlySummary {
    let year: Int
    let month: Int
    let totalIncome: Decimal         // sum of positive amounts
    let totalExpenses: Decimal       // sum of |negative amounts|
    let balance: Decimal             // income − expenses
    let categoryBreakdown: [(category: Category, amount: Decimal)]
}

// MARK: - Protocol

protocol TransactionRepositoryProtocol {
    func fetchAll(for household: Household, context: ModelContext) throws -> [Transaction]
    func fetch(year: Int, month: Int, household: Household, context: ModelContext) throws -> [Transaction]
    func fetch(for account: BankAccount, context: ModelContext) throws -> [Transaction]
    func fetch(for category: Category, context: ModelContext) throws -> [Transaction]
    func search(_ text: String, household: Household, context: ModelContext) throws -> [Transaction]
    func save(_ transaction: Transaction, in context: ModelContext) throws
    func delete(_ transaction: Transaction, in context: ModelContext) throws
    func monthlySummary(year: Int, month: Int, household: Household, context: ModelContext) throws -> MonthlySummary
}

// MARK: - Implementation

final class TransactionRepository: TransactionRepositoryProtocol {

    // MARK: Fetch

    func fetchAll(for household: Household, context: ModelContext) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        let householdId = household.id
        return all.filter { $0.account?.household?.id == householdId }
    }

    func fetch(year: Int, month: Int, household: Household, context: ModelContext) throws -> [Transaction] {
        let all = try fetchAll(for: household, context: context)
        let cal = Calendar.current
        return all.filter {
            let comps = cal.dateComponents([.year, .month], from: $0.date)
            return comps.year == year && comps.month == month
        }
    }

    func fetch(for account: BankAccount, context: ModelContext) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        let accountId = account.id
        return all.filter { $0.account?.id == accountId }
    }

    func fetch(for category: Category, context: ModelContext) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        let categoryId = category.id
        return all.filter { $0.category?.id == categoryId }
    }

    func search(_ text: String, household: Household, context: ModelContext) throws -> [Transaction] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try fetchAll(for: household, context: context)
        }
        let lower = text.lowercased()
        let all = try fetchAll(for: household, context: context)
        return all.filter {
            $0.descriptionText.lowercased().contains(lower) ||
            ($0.notes?.lowercased().contains(lower) ?? false)
        }
    }

    // MARK: Write

    func save(_ transaction: Transaction, in context: ModelContext) throws {
        context.insert(transaction)
        try context.save()
    }

    func delete(_ transaction: Transaction, in context: ModelContext) throws {
        context.delete(transaction)
        try context.save()
    }

    // MARK: Aggregation

    func monthlySummary(year: Int, month: Int, household: Household, context: ModelContext) throws -> MonthlySummary {
        let transactions = try fetch(year: year, month: month, household: household, context: context)
        let nonTransfers = transactions.filter { !$0.isTransfer }

        let income = nonTransfers
            .filter { $0.amount > 0 }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let rawExpenses = nonTransfers
            .filter { $0.amount < 0 }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpenses = abs(rawExpenses)

        // Build category breakdown for expense transactions
        var breakdown: [ObjectIdentifier: (category: Category, amount: Decimal)] = [:]
        for t in nonTransfers where t.amount < 0 {
            guard let cat = t.category else { continue }
            let key = ObjectIdentifier(cat)
            if breakdown[key] == nil {
                breakdown[key] = (cat, 0)
            }
            breakdown[key]!.amount += abs(t.amount)
        }
        let sortedBreakdown = breakdown.values
            .sorted { $0.amount > $1.amount }
            .map { (category: $0.category, amount: $0.amount) }

        return MonthlySummary(
            year: year,
            month: month,
            totalIncome: income,
            totalExpenses: totalExpenses,
            balance: income - totalExpenses,
            categoryBreakdown: sortedBreakdown
        )
    }
}
