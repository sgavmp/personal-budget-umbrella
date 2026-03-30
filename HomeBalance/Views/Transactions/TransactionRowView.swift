import SwiftUI

/// A single row in the transaction list.
struct TransactionRowView: View {
    let transaction: Transaction
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            // Category icon badge
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(badgeColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.descriptionText)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let cat = transaction.category {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(cat.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount.formatted(currency: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(amountColor)

                if transaction.isTransfer {
                    Text("transfer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var iconName: String {
        if transaction.isTransfer { return "arrow.left.arrow.right" }
        return transaction.category?.icon ?? "questionmark.circle"
    }

    private var badgeColor: Color {
        if transaction.isTransfer { return .blue }
        return Color(hex: transaction.category?.color ?? "#8E8E93")
    }

    private var amountColor: Color {
        if transaction.isTransfer { return .blue }
        return transaction.amount >= 0 ? .green : .primary
    }
}
