import SwiftUI

/// Recent activity card on the Dashboard.
/// Design: "The Financial Curator" — white card, no dividers, icon badges, coloured amounts.
struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let currency: String
    var onViewAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ────────────────────────────────────────────────────────
            HStack {
                Text("recent_transactions")
                    .font(.hbHeadlineMedium)
                    .foregroundStyle(.hbOnSurface)
                Spacer()
                if let onViewAll {
                    Button(action: onViewAll) {
                        Text("view_all")
                            .font(.hbLabelLarge)
                            .foregroundStyle(.hbPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBSpacing.md)
            .padding(.vertical, HBSpacing.md)

            // ── Rows ──────────────────────────────────────────────────────────
            if transactions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
        }
        .hbCard()
    }

    // MARK: - Transaction row

    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        let color = transaction.isTransfer
            ? Color.hbPrimary
            : Color(hex: transaction.category?.color ?? "#8E8E93")

        HStack(spacing: HBSpacing.md) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.isTransfer
                      ? "arrow.left.arrow.right"
                      : (transaction.category?.icon ?? "questionmark.circle"))
                    .font(.system(size: 17))
                    .foregroundStyle(color)
            }

            // Description + date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.hbOnSurface)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.hbLabelSmall)
                    .foregroundStyle(.hbOnSurfaceVariant)
            }

            Spacer()

            // Amount
            Text(transaction.amount.formatted(currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(amountColor(for: transaction))
        }
        .padding(.horizontal, HBSpacing.md)
        .padding(.vertical, HBSpacing.sm + 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: HBSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.hbOnSurfaceVariant.opacity(0.5))
            Text("no_transactions_this_month")
                .font(.subheadline)
                .foregroundStyle(.hbOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.xl)
    }

    // MARK: - Helpers

    private func amountColor(for transaction: Transaction) -> Color {
        if transaction.isTransfer { return .hbPrimary }
        return transaction.amount >= 0 ? .hbPositive : .hbNegative
    }
}
