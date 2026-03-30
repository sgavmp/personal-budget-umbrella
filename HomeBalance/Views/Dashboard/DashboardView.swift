import SwiftUI
import SwiftData

/// Main dashboard screen following "The Financial Curator" design system.
/// Shows a hero summary card, spending-by-category breakdown, and recent activity.
struct DashboardView: View {
    let household: Household

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showingTransactions = false

    var body: some View {
        ScrollView {
            VStack(spacing: HBSpacing.lg) {
                // Month navigator
                monthNavigator
                    .padding(.horizontal, HBSpacing.lg)

                // Hero summary card  ── or loading / empty states
                if let summary = viewModel.summary {
                    BudgetSummaryCard(summary: summary, currency: household.currency)
                        .padding(.horizontal, HBSpacing.lg)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, HBSpacing.xl)
                } else {
                    emptyMonthCard
                        .padding(.horizontal, HBSpacing.lg)
                }

                // Category breakdown
                if let summary = viewModel.summary, !summary.categoryBreakdown.isEmpty {
                    categoryBreakdownSection(summary: summary)
                        .padding(.horizontal, HBSpacing.lg)
                }

                // Recent transactions
                RecentTransactionsCard(
                    transactions: viewModel.recentTransactions,
                    currency: household.currency,
                    onViewAll: { showingTransactions = true }
                )
                .padding(.horizontal, HBSpacing.lg)
                .padding(.bottom, HBSpacing.md)
            }
            .padding(.top, HBSpacing.md)
        }
        .background(Color.hbSurface.ignoresSafeArea())
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

    // MARK: - Month navigator

    private var monthNavigator: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .hbSubtleShadow()
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.goToCurrentMonth()
            } label: {
                Text(viewModel.displayMonth)
                    .font(.hbHeadlineMedium)
                    .foregroundStyle(.hbOnSurface)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .hbSubtleShadow()
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGoForward)
            .opacity(viewModel.canGoForward ? 1 : 0.3)
        }
    }

    // MARK: - Empty month

    private var emptyMonthCard: some View {
        VStack(spacing: HBSpacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.hbPrimary.opacity(0.6))

            VStack(spacing: HBSpacing.xs) {
                Text("no_data_this_month")
                    .font(.hbHeadlineMedium)
                    .foregroundStyle(.hbOnSurface)
                Text("add_first_transaction")
                    .font(.subheadline)
                    .foregroundStyle(.hbOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.xxl)
        .hbCard()
    }

    // MARK: - Category breakdown

    @ViewBuilder
    private func categoryBreakdownSection(summary: MonthlySummary) -> some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            // Section title
            Text("spending_by_category")
                .font(.hbHeadlineMedium)
                .foregroundStyle(.hbOnSurface)

            VStack(spacing: HBSpacing.sm) {
                ForEach(
                    Array(summary.categoryBreakdown.prefix(5).enumerated()),
                    id: \.offset
                ) { _, item in
                    categoryRow(
                        category: item.category,
                        amount: item.amount,
                        total: summary.totalExpenses
                    )
                }
            }
            .padding(HBSpacing.md)
            .hbCard()
        }
    }

    @ViewBuilder
    private func categoryRow(
        category: Category,
        amount: Decimal,
        total: Decimal
    ) -> some View {
        let fraction = total > 0
            ? Double(truncating: (amount / total) as NSDecimalNumber)
            : 0
        let color = Color(hex: category.color)

        HStack(spacing: HBSpacing.md) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(color)
            }

            // Label + bar
            VStack(alignment: .leading, spacing: HBSpacing.xs) {
                HStack {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundStyle(.hbOnSurface)
                    Spacer()
                    Text(amount.formatted(currency: household.currency))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.hbOnSurface)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: HBRadius.progressBar)
                            .fill(Color.hbSurfaceVariant)
                        RoundedRectangle(cornerRadius: HBRadius.progressBar)
                            .fill(.hbSecondary)
                            .frame(width: geo.size.width * fraction)
                    }
                    .frame(height: 8)
                }
                .frame(height: 8)
            }
        }
    }
}
