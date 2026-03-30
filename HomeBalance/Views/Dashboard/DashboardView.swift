import SwiftUI
import SwiftData

/// Main dashboard screen: shows monthly summary, category breakdown, recent transactions.
struct DashboardView: View {
    let household: Household

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showingTransactions = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month navigator
                monthNavigator

                // Summary card
                if let summary = viewModel.summary {
                    BudgetSummaryCard(summary: summary, currency: household.currency)
                        .padding(.horizontal)
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 32)
                } else {
                    emptyMonthView
                }

                // Category breakdown
                if let summary = viewModel.summary, !summary.categoryBreakdown.isEmpty {
                    categoryBreakdownCard(summary: summary)
                }

                // Recent transactions
                RecentTransactionsCard(
                    transactions: viewModel.recentTransactions,
                    currency: household.currency,
                    onViewAll: { showingTransactions = true }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("dashboard")
        .onAppear { viewModel.loadData(for: household, context: modelContext) }
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.loadData(for: household, context: modelContext)
        }
        .sheet(isPresented: $showingTransactions) {
            NavigationStack {
                TransactionListView(household: household)
            }
        }
        .alert("error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("ok") { viewModel.errorMessage = nil }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
    }

    // MARK: - Sub-views

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .imageScale(.medium)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Button {
                viewModel.goToCurrentMonth()
            } label: {
                Text(viewModel.displayMonth)
                    .font(.headline)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .frame(width: 36, height: 36)
            }
            .disabled(!viewModel.canGoForward)
            .opacity(viewModel.canGoForward ? 1 : 0.3)
        }
        .padding(.horizontal, 24)
    }

    private var emptyMonthView: some View {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "no_data_this_month",
            subtitle: "add_first_transaction"
        )
        .frame(height: 200)
    }

    @ViewBuilder
    private func categoryBreakdownCard(summary: MonthlySummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("spending_by_category")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            ForEach(Array(summary.categoryBreakdown.prefix(5).enumerated()), id: \.offset) { index, item in
                categoryRow(
                    category: item.category,
                    amount: item.amount,
                    total: summary.totalExpenses,
                    currency: household.currency
                )
                if index < min(4, summary.categoryBreakdown.count - 1) {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func categoryRow(
        category: Category,
        amount: Decimal,
        total: Decimal,
        currency: String
    ) -> some View {
        let fraction = total > 0 ? Double(truncating: (amount / total) as NSDecimalNumber) : 0
        let color = Color(hex: category.color)

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.name)
                        .font(.subheadline)
                    Spacer()
                    Text(amount.formatted(currency: currency))
                        .font(.subheadline.weight(.semibold))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geo.size.width * fraction)
                    }
                    .frame(height: 6)
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

