import SwiftUI

/// Hero card: shows balance as a large display figure, with income / expenses below.
/// Design: "The Financial Curator" — gradient header, ambient card shadow.
struct BudgetSummaryCard: View {
    let summary: MonthlySummary
    let currency: String

    var body: some View {
        VStack(spacing: 0) {
            // ── Hero balance ──────────────────────────────────────────────────
            VStack(spacing: HBSpacing.xs) {
                Text("balance")
                    .font(.hbLabelLarge)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.75))

                Text(summary.balance.formatted(currency: currency))
                    .font(.hbDisplayMedium)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HBSpacing.xl)
            .background(LinearGradient.hbPrimaryGradient)

            // ── Income / Expenses ─────────────────────────────────────────────
            HStack(spacing: 0) {
                metricView(
                    label: "income",
                    amount: summary.totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .hbPositive
                )

                Divider()
                    .frame(height: 48)

                metricView(
                    label: "expenses",
                    amount: summary.totalExpenses,
                    icon: "arrow.up.circle.fill",
                    color: .hbNegative
                )
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.card))
        .hbCardShadow()
    }

    // MARK: - Metric column

    @ViewBuilder
    private func metricView(
        label: LocalizedStringKey,
        amount: Decimal,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: HBSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.medium)

            Text(label)
                .font(.hbLabelSmall)
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.hbOnSurfaceVariant)

            Text(amount.formatted(currency: currency))
                .font(.hbHeadlineMedium)
                .foregroundStyle(.hbOnSurface)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    let summary = MonthlySummary(
        year: 2025,
        month: 3,
        totalIncome: 4200,
        totalExpenses: 2480.50,
        balance: 1719.50,
        categoryBreakdown: []
    )
    BudgetSummaryCard(summary: summary, currency: "EUR")
        .padding()
        .background(Color.hbSurface)
}
