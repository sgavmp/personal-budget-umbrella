import SwiftUI

/// A single row in the transaction list.
/// Design: "The Financial Curator" — category icon badge, coloured amounts.
struct TransactionRowView: View {
    let transaction: Transaction
    let currency: String

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            // Category icon badge
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 19))
                    .foregroundStyle(badgeColor)
            }

            // Description + meta
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.hbOnSurface)
                    .lineLimit(1)

                HStack(spacing: HBSpacing.xs) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.hbLabelSmall)
                        .foregroundStyle(.hbOnSurfaceVariant)

                    if let cat = transaction.category {
                        Text("·")
                            .font(.hbLabelSmall)
                            .foregroundStyle(.hbOnSurfaceVariant)
                        Text(cat.name)
                            .font(.hbLabelSmall)
                            .foregroundStyle(.hbOnSurfaceVariant)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Amount + transfer badge
            VStack(alignment: .trailing, spacing: 3) {
                Text(transaction.amount.formatted(currency: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(amountColor)

                if transaction.isTransfer {
                    Text("transfer")
                        .font(.caption2)
                        .foregroundStyle(.hbPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.hbPrimaryContainer)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, HBSpacing.xs + 2)
    }

    // MARK: - Helpers

    private var iconName: String {
        if transaction.isTransfer { return "arrow.left.arrow.right" }
        return transaction.category?.icon ?? "questionmark.circle"
    }

    private var badgeColor: Color {
        if transaction.isTransfer { return .hbPrimary }
        return Color(hex: transaction.category?.color ?? "#8E8E93")
    }

    private var amountColor: Color {
        if transaction.isTransfer { return .hbPrimary }
        return transaction.amount >= 0 ? .hbPositive : .hbNegative
    }
}
