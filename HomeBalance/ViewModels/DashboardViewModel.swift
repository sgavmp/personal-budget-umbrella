import SwiftData
import Foundation
import Observation

/// Provides aggregated monthly data for the Dashboard screen.
@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - State

    var selectedDate: Date = Date()
    var summary: MonthlySummary?
    var recentTransactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private

    private let repository: any TransactionRepositoryProtocol

    init(repository: any TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
    }

    // MARK: - Computed helpers

    var displayMonth: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    var canGoForward: Bool {
        let cal = Calendar.current
        let now = Date()
        return !(cal.isDate(selectedDate, equalTo: now, toGranularity: .month) ||
                 selectedDate > now)
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }

    func goToNextMonth() {
        guard canGoForward else { return }
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }

    func goToCurrentMonth() {
        selectedDate = Date()
    }

    // MARK: - Data Loading

    func loadData(for household: Household, context: ModelContext) {
        isLoading = true
        errorMessage = nil
        let cal = Calendar.current
        let year = cal.component(.year, from: selectedDate)
        let month = cal.component(.month, from: selectedDate)

        do {
            summary = try repository.monthlySummary(year: year, month: month, household: household, context: context)
            let all = try repository.fetch(year: year, month: month, household: household, context: context)
            recentTransactions = Array(
                all.filter { !$0.isTransfer }.prefix(10)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
