import SwiftUI
import SwiftData

// MARK: - Import Wizard Container

struct ImportWizardView: View {

    let household: Household

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var vm = ImportWizardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                if vm.step != .complete {
                    StepProgressBar(current: vm.step.rawValue, total: 4)
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.top, HBSpacing.md)
                        .padding(.bottom, HBSpacing.sm)
                }

                // Page content
                Group {
                    switch vm.step {
                    case .fileSelection:
                        ImportStep1FileSelectionView(vm: vm, household: household)
                    case .columnMapping:
                        ImportStep2ColumnMappingView(vm: vm)
                    case .duplicateReview:
                        ImportStep3DuplicateReviewView(vm: vm)
                    case .complete:
                        ImportStep4CompleteView(vm: vm, onDone: { dismiss() })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Error banner
                if let err = vm.errorMessage {
                    HStack(spacing: HBSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(err)
                            .font(.hbLabelLarge)
                    }
                    .foregroundStyle(Color.hbError)
                    .padding(HBSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.hbErrorContainer)
                }

                // Navigation footer
                if vm.step != .complete {
                    WizardFooter(vm: vm, household: household, context: context)
                }
            }
            .background(Color.hbSurface.ignoresSafeArea())
            .navigationTitle("Step \(vm.step.rawValue) of 4")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if vm.isLoading {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(Color.hbPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: HBSpacing.xs) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.hbPrimary : Color.hbSurfaceVariant)
                    .frame(height: 4)
                    .animation(.spring(response: 0.4), value: current)
            }
        }
    }
}

// MARK: - Wizard Footer

private struct WizardFooter: View {
    @Bindable var vm: ImportWizardViewModel
    let household: Household
    let context: ModelContext

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            if vm.step != .fileSelection {
                Button {
                    vm.back()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.hbLabelLarge)
                        .foregroundStyle(Color.hbPrimary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                vm.advance(household: household, context: context)
            } label: {
                Text(vm.step == .duplicateReview ? "Import \(vm.selectedCount) Transactions" : "Continue")
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HBSpacing.xl)
                    .padding(.vertical, HBSpacing.md)
                    .background(
                        vm.canAdvance()
                            ? LinearGradient.hbPrimaryGradient
                            : LinearGradient(colors: [Color.hbSurfaceVariant], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
            .disabled(!vm.canAdvance() || vm.isLoading)
        }
        .padding(HBSpacing.lg)
        .background(.ultraThinMaterial)
    }
}
