import SwiftData
import Foundation
import Observation

/// Manages the state for the transaction list, including filters and search.
@MainActor
@Observable
final class TransactionListViewModel {

    // MARK: - Filter State

    var searchText: String = ""
    var selectedCategory: Category?
    var selectedAccount: BankAccount?
    var startDate: Date?
    var endDate: Date?
    var showTransfers: Bool = false

    // MARK: - Result State

    var transactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private

    private let repository: any TransactionRepositoryProtocol

    init(repository: any TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
    }

    // MARK: - Computed

    var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedAccount != nil ||
        startDate != nil ||
        endDate != nil ||
        !searchText.isEmpty
    }

    // MARK: - Loading

    func loadTransactions(for household: Household, context: ModelContext) {
        isLoading = true
        errorMessage = nil

        do {
            var result: [Transaction]
            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                result = try repository.search(searchText, household: household, context: context)
            } else {
                result = try repository.fetchAll(for: household, context: context)
            }

            // Apply filters
            result = applyFilters(to: result)
            transactions = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedAccount = nil
        startDate = nil
        endDate = nil
    }

    // MARK: - Helpers

    private func applyFilters(to list: [Transaction]) -> [Transaction] {
        var filtered = list

        if !showTransfers {
            filtered = filtered.filter { !$0.isTransfer }
        }
        if let cat = selectedCategory {
            let catId = cat.id
            filtered = filtered.filter { $0.category?.id == catId }
        }
        if let acc = selectedAccount {
            let accId = acc.id
            filtered = filtered.filter { $0.account?.id == accId }
        }
        if let from = startDate {
            filtered = filtered.filter { $0.date >= from }
        }
        if let to = endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: to) ?? to
            filtered = filtered.filter { $0.date < endOfDay }
        }
        return filtered
    }
}
