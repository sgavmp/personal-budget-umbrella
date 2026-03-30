import SwiftUI

// MARK: - Step 3: Duplicate Review

struct ImportStep3DuplicateReviewView: View {

    @Bindable var vm: ImportWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.lg) {

                // Header
                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    Text(ImportWizardStep.duplicateReview.title)
                        .font(.hbHeadlineLarge)
                        .foregroundStyle(Color.hbOnSurface)
                    Text("We've analysed all \(vm.duplicateResults.count) transactions. Verify your import before committing to your ledger.")
                        .font(.hbLabelLarge)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Summary chips
                HStack(spacing: HBSpacing.sm) {
                    SummaryChip(count: vm.newCount, label: "New", color: Color.hbSecondary)
                    SummaryChip(count: vm.potentialCount, label: "Potential Dups", color: Color.hbTertiary)
                    SummaryChip(count: vm.exactCount, label: "Exact Dups", color: Color.hbError)
                }

                // Select / deselect all
                HStack {
                    Button("Select All") { vm.selectAll(true) }
                    Spacer()
                    Button("Deselect Duplicates") {
                        for i in vm.duplicateResults.indices where vm.duplicateResults[i].status != .new {
                            vm.duplicateResults[i].isSelected = false
                        }
                    }
                }
                .font(.hbLabelLarge)
                .foregroundStyle(Color.hbPrimary)

                // Sections
                if vm.newCount > 0 {
                    ReviewSection(
                        title: "New Transactions",
                        subtitle: "Will be imported",
                        color: Color.hbSecondary,
                        icon: "plus.circle.fill",
                        results: vm.duplicateResults.filter { $0.status == .new },
                        vm: vm
                    )
                }

                if vm.potentialCount > 0 {
                    ReviewSection(
                        title: "Potential Duplicates",
                        subtitle: "Review carefully — similar transactions exist",
                        color: Color.hbTertiary,
                        icon: "exclamationmark.circle.fill",
                        results: vm.duplicateResults.filter { $0.status == .potential },
                        vm: vm
                    )
                }

                if vm.exactCount > 0 {
                    ReviewSection(
                        title: "Exact Duplicates",
                        subtitle: "Already in your ledger — deselected by default",
                        color: Color.hbError,
                        icon: "xmark.circle.fill",
                        results: vm.duplicateResults.filter { $0.status == .exact },
                        vm: vm
                    )
                }
            }
            .padding(HBSpacing.lg)
        }
    }
}

// MARK: - Summary Chip

private struct SummaryChip: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.hbHeadlineMedium)
                .foregroundStyle(color)
            Text(label)
                .font(.hbLabelSmall)
                .foregroundStyle(Color.hbOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
    }
}

// MARK: - Review Section

private struct ReviewSection: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let results: [DuplicateResult]
    @Bindable var vm: ImportWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            // Section header
            HStack(spacing: HBSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.hbLabelLarge.weight(.semibold))
                        .foregroundStyle(Color.hbOnSurface)
                    Text(subtitle)
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                }
                Spacer()
                Text("\(results.count)")
                    .font(.hbLabelSmall.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, HBSpacing.sm)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            ForEach(results) { result in
                DuplicateReviewRow(
                    result: result,
                    isSelected: result.isSelected,
                    onToggle: { vm.toggleResult(id: result.id) }
                )
            }
        }
    }
}

// MARK: - Duplicate Review Row

private struct DuplicateReviewRow: View {
    let result: DuplicateResult
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.md) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.hbPrimary : Color.hbSurfaceVariant)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: HBSpacing.xs) {
                // New transaction
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.row.descriptionText)
                            .font(.hbLabelLarge.weight(.semibold))
                            .foregroundStyle(Color.hbOnSurface)
                            .lineLimit(1)
                        if let date = result.row.date {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                        }
                    }
                    Spacer()
                    if let amount = result.row.amount {
                        Text(amount.formatted(.currency(code: "EUR")))
                            .font(.hbLabelLarge.weight(.semibold))
                            .foregroundStyle(amount >= 0 ? Color.hbPositive : Color.hbNegative)
                    }
                }

                // Matching transaction (for potential/exact)
                if result.status != .new, let matchDesc = result.matchingTransactionDesc {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(matchDesc)
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                                .lineLimit(1)
                            if let matchDate = result.matchingTransactionDate {
                                Text(matchDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.hbLabelSmall)
                                    .foregroundStyle(Color.hbOnSurfaceVariant.opacity(0.7))
                            }
                        }
                        Spacer()
                        if let matchAmount = result.matchingTransactionAmount {
                            Text(matchAmount.formatted(.currency(code: "EUR")))
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                        }
                    }
                    .padding(HBSpacing.sm)
                    .background(Color.hbSurfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(HBSpacing.md)
        .background(isSelected ? Color.white : Color.hbSurfaceLow.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
        .overlay(
            RoundedRectangle(cornerRadius: HBRadius.chip)
                .stroke(isSelected ? statusColor(result.status) : Color.clear, lineWidth: 1.5)
        )
        .opacity(isSelected ? 1 : 0.6)
    }

    private func statusColor(_ status: DuplicateStatus) -> Color {
        switch status {
        case .new:       return Color.hbSecondary
        case .potential: return Color.hbTertiary
        case .exact:     return Color.hbError
        }
    }
}
