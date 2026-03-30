import SwiftUI

/// Shows the most recent transactions as a compact card.
struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let currency: String
    var onViewAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("recent_transactions")
                    .font(.headline)
                Spacer()
                if let onViewAll {
                    Button("view_all", action: onViewAll)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if transactions.isEmpty {
                Text("no_transactions_this_month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    transactionRow(transaction)
                    if index < transactions.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.category?.color ?? "#8E8E93").opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: transaction.category?.color ?? "#8E8E93"))
            }

            // Description + date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.descriptionText)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text(transaction.amount.formatted(currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.amount >= 0 ? .green : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

