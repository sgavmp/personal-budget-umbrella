import SwiftUI

// MARK: - Step 4: Complete

struct ImportStep4CompleteView: View {

    let vm: ImportWizardViewModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: HBSpacing.xl) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.hbSecondaryContainer)
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.hbSecondary)
                    .symbolEffect(.bounce, value: vm.importedCount)
            }

            VStack(spacing: HBSpacing.sm) {
                Text("Import Complete!")
                    .font(.hbHeadlineLarge)
                    .foregroundStyle(Color.hbOnSurface)

                Text("\(vm.importedCount) transaction\(vm.importedCount == 1 ? "" : "s") added to your ledger.")
                    .font(.hbLabelLarge)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                    .multilineTextAlignment(.center)

                if let batch = vm.completedBatch {
                    Text("Batch: \(batch.filename)")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant.opacity(0.7))
                }
            }

            // Stats
            HStack(spacing: HBSpacing.lg) {
                StatPill(label: "Imported", value: "\(vm.importedCount)", color: Color.hbSecondary)
                StatPill(label: "Skipped", value: "\(vm.duplicateResults.filter { !$0.isSelected }.count)", color: Color.hbOnSurfaceVariant)
                StatPill(label: "Exact Dups", value: "\(vm.exactCount)", color: Color.hbError)
            }
            .padding(HBSpacing.lg)
            .background(Color.hbSurfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.card))

            Spacer()

            // Done button
            Button(action: onDone) {
                Text("View Transactions")
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HBSpacing.md)
                    .background(LinearGradient.hbPrimaryGradient)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, HBSpacing.lg)
            .padding(.bottom, HBSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(Color.hbSurface)
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: HBSpacing.xs) {
            Text(value)
                .font(.hbHeadlineMedium)
                .foregroundStyle(color)
            Text(label)
                .font(.hbLabelSmall)
                .foregroundStyle(Color.hbOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }
}
