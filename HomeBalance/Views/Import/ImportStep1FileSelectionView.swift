import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Step 1: File Selection

struct ImportStep1FileSelectionView: View {

    @Bindable var vm: ImportWizardViewModel
    let household: Household

    @Environment(\.modelContext) private var context
    @Query private var accounts: [BankAccount]

    @State private var showingFilePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.lg) {

                // Header
                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    Text("THE FINANCIAL CURATOR")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbPrimary)
                        .tracking(1.5)
                    Text(ImportWizardStep.fileSelection.title)
                        .font(.hbHeadlineLarge)
                        .foregroundStyle(Color.hbOnSurface)
                    Text("Connect your past spending to your future goals. Select a bank statement file and assign it to an account.")
                        .font(.hbLabelLarge)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // File drop zone
                Button {
                    showingFilePicker = true
                } label: {
                    DropZoneView(filename: vm.filename)
                }
                .buttonStyle(.plain)
                .fileImporter(
                    isPresented: $showingFilePicker,
                    allowedContentTypes: [.commaSeparatedText, UTType(filenameExtension: "xlsx") ?? .data, .plainText],
                    allowsMultipleSelection: false
                ) { result in
                    if case .success(let urls) = result, let url = urls.first {
                        let accessing = url.startAccessingSecurityScopedResource()
                        vm.setFile(url: url)
                        if accessing { url.stopAccessingSecurityScopedResource() }
                    }
                }

                // Bank name
                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    Text("SELECT BANK STATEMENT")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                        .tracking(1)

                    TextField("Bank name (e.g. BBVA, Santander…)", text: $vm.bankName)
                        .padding(HBSpacing.md)
                        .background(Color.hbSurfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
                }

                // Destination Account
                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    Text("DESTINATION ACCOUNT")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                        .tracking(1)

                    let householdAccounts = accounts.filter { $0.household?.id == household.id }
                    ForEach(householdAccounts) { account in
                        AccountSelectionRow(
                            account: account,
                            isSelected: vm.selectedAccount?.id == account.id,
                            action: { vm.selectedAccount = account }
                        )
                    }
                }

                // CSV options (collapsible)
                CSVOptionsSection(vm: vm)

            }
            .padding(HBSpacing.lg)
        }
    }
}

// MARK: - Drop Zone

private struct DropZoneView: View {
    let filename: String

    var body: some View {
        VStack(spacing: HBSpacing.md) {
            Image(systemName: filename.isEmpty ? "arrow.up.doc.fill" : "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(filename.isEmpty ? Color.hbOnSurfaceVariant : Color.hbSecondary)

            if filename.isEmpty {
                Text("Click to upload or drag and drop")
                    .font(.hbLabelLarge)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                Text("CSV, Excel, or PDF statements\nsupported")
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Text(filename)
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                Text("Tap to change file")
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(HBSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: HBRadius.card)
                .strokeBorder(
                    filename.isEmpty ? Color.hbSurfaceVariant : Color.hbSecondary,
                    style: StrokeStyle(lineWidth: 2, dash: filename.isEmpty ? [8, 4] : [])
                )
                .background(Color.hbSurfaceLow.clipShape(RoundedRectangle(cornerRadius: HBRadius.card)))
        )
    }
}

// MARK: - Account Row

private struct AccountSelectionRow: View {
    let account: BankAccount
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HBSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.hbPrimary : Color.hbSurfaceVariant)
                        .frame(width: 40, height: 40)
                    Image(systemName: accountIcon(account.accountType))
                        .foregroundStyle(isSelected ? .white : Color.hbOnSurfaceVariant)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.hbLabelLarge.weight(.semibold))
                        .foregroundStyle(Color.hbOnSurface)
                    if let last4 = account.lastFourDigits {
                        Text("**** \(last4)")
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbOnSurfaceVariant)
                    }
                }

                Spacer()

                // Status badge
                Text(account.accountType.uppercased())
                    .font(.hbLabelSmall.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.hbPrimary : Color.hbOnSurfaceVariant)
                    .padding(.horizontal, HBSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(isSelected ? Color.hbPrimaryContainer : Color.hbSurfaceVariant)
                    )

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.hbPrimary : Color.hbSurfaceVariant)
                    .font(.system(size: 20))
            }
            .padding(HBSpacing.md)
            .background(isSelected ? Color.hbPrimaryContainer.opacity(0.3) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.chip)
                    .stroke(isSelected ? Color.hbPrimary : Color.hbSurfaceVariant, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func accountIcon(_ type: String) -> String {
        switch type {
        case "savings": return "banknote"
        case "credit":  return "creditcard"
        default:        return "building.columns"
        }
    }
}

// MARK: - CSV Options

private struct CSVOptionsSection: View {
    @Bindable var vm: ImportWizardViewModel
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(spacing: HBSpacing.sm) {
                    // Delimiter
                    Picker("Delimiter", selection: $vm.csvDelimiter) {
                        Text("Semicolon (;)").tag(Character(";"))
                        Text("Comma (,)").tag(Character(","))
                        Text("Tab").tag(Character("\t"))
                    }
                    .pickerStyle(.segmented)

                    // Decimal separator
                    Picker("Decimal separator", selection: $vm.csvDecimalSeparator) {
                        Text("Comma (,)").tag(Character(","))
                        Text("Point (.)").tag(Character("."))
                    }
                    .pickerStyle(.segmented)

                    // Skip header rows
                    Stepper("Skip \(vm.csvSkipHeaderRows) header row(s)", value: $vm.csvSkipHeaderRows, in: 0...5)
                        .font(.hbLabelLarge)
                }
                .padding(.top, HBSpacing.sm)
            },
            label: {
                Label("Advanced Options", systemImage: "slider.horizontal.3")
                    .font(.hbLabelLarge.weight(.medium))
                    .foregroundStyle(Color.hbPrimary)
            }
        )
        .padding(HBSpacing.md)
        .background(Color.hbSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
    }
}
