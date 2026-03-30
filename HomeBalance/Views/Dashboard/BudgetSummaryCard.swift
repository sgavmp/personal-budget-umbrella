import SwiftUI

/// Shows income / expenses / balance for the selected month.
struct BudgetSummaryCard: View {
    let summary: MonthlySummary
    let currency: String

    var body: some View {
        VStack(spacing: 0) {
            // Balance row
            VStack(spacing: 4) {
                Text("balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(summary.balance.formatted(currency: currency))
                    .font(.title.bold())
                    .foregroundStyle(summary.balance >= 0 ? Color.green : Color.red)
            }
            .padding(.vertical, 16)

            Divider()

            // Income / Expenses row
            HStack(spacing: 0) {
                metricView(
                    label: "income",
                    amount: summary.totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                Divider().frame(height: 48)
                metricView(
                    label: "expenses",
                    amount: summary.totalExpenses,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func metricView(
        label: LocalizedStringKey,
        amount: Decimal,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount.formatted(currency: currency))
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview {
    let summary = MonthlySummary(
        year: 2024,
        month: 3,
        totalIncome: 3000,
        totalExpenses: 1800,
        balance: 1200,
        categoryBreakdown: []
    )
    BudgetSummaryCard(summary: summary, currency: "EUR")
        .padding()
}
