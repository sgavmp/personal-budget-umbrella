import SwiftUI

// MARK: - Step 2: Column Mapping

struct ImportStep2ColumnMappingView: View {

    @Bindable var vm: ImportWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.lg) {

                // Header
                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    Text("IMPORT WIZARD")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbPrimary)
                        .tracking(1.5)
                    Text(ImportWizardStep.columnMapping.title)
                        .font(.hbHeadlineLarge)
                        .foregroundStyle(Color.hbOnSurface)

                    // Auto-detect info banner
                    if !vm.rawPreviewRows.isEmpty {
                        HStack(spacing: HBSpacing.sm) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.hbPrimary)
                            Text("We've selected CSV format automatically. Confirm the detected columns below.")
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                        }
                        .padding(HBSpacing.sm)
                        .background(Color.hbPrimaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
                    }
                }

                // Format settings row
                HStack(spacing: HBSpacing.md) {
                    LabeledChip(label: "FILE RECOGNISED", value: "CSV · \(vm.csvDelimiter == ";" ? "Semicolon" : vm.csvDelimiter == "," ? "Comma" : "Tab")")
                    LabeledChip(label: "DECIMAL", value: vm.csvDecimalSeparator == "," ? "Comma" : "Point")
                    LabeledChip(label: "SKIP ROWS", value: "\(vm.csvSkipHeaderRows)")
                }

                Divider()

                // Column assignment pickers
                if !vm.rawPreviewRows.isEmpty {
                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        Text("COLUMN PREVIEW & ASSIGNMENT")
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbOnSurfaceVariant)
                            .tracking(1)

                        Text("Showing \(min(4, (vm.rawPreviewRows.first?.count ?? 0))) of \(vm.rawPreviewRows.first?.count ?? 0) columns")
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbOnSurfaceVariant)

                        ForEach(vm.columnConfig.assignments) { assignment in
                            ColumnMappingRow(
                                assignment: assignment,
                                sampleValues: sampleValues(for: assignment.columnIndex),
                                onChange: { newRole in
                                    updateRole(index: assignment.columnIndex, role: newRole)
                                }
                            )
                        }
                    }
                }

                // Preview table
                if !vm.previewRows.isEmpty {
                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        HStack {
                            Text("DATA PREVIEW")
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                                .tracking(1)
                            Spacer()
                            Text("Pro Tip: Ensure Row 1 has your first transaction")
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbPrimary)
                        }
                        .padding(.bottom, HBSpacing.xs)

                        ForEach(vm.previewRows) { row in
                            PreviewRowView(row: row)
                        }
                    }
                }

                // Pro tip card
                ProTipCard(
                    icon: "lightbulb.fill",
                    title: "Pro-Tip for Mapping",
                    message: "If your file uses a header row, always ensure you map a **Description** column to successfully import your transactions into HomeBalance."
                )
            }
            .padding(HBSpacing.lg)
        }
        .onChange(of: vm.columnConfig.assignments.map(\.role.rawValue).joined()) { _, _ in
            vm.refreshPreview()
        }
    }

    private func sampleValues(for index: Int) -> [String] {
        vm.rawPreviewRows.dropFirst(vm.csvSkipHeaderRows).prefix(3).compactMap { row in
            index < row.count ? row[index] : nil
        }
    }

    private func updateRole(index: Int, role: ColumnRole) {
        guard let idx = vm.columnConfig.assignments.firstIndex(where: { $0.columnIndex == index }) else { return }
        // Remove duplicate role (except .ignore)
        if role != .ignore {
            for i in vm.columnConfig.assignments.indices where vm.columnConfig.assignments[i].role == role && i != idx {
                vm.columnConfig.assignments[i] = ColumnAssignment(columnIndex: vm.columnConfig.assignments[i].columnIndex, role: .ignore)
            }
        }
        vm.columnConfig.assignments[idx] = ColumnAssignment(columnIndex: index, role: role)
    }
}

// MARK: - Column Mapping Row

private struct ColumnMappingRow: View {
    let assignment: ColumnAssignment
    let sampleValues: [String]
    let onChange: (ColumnRole) -> Void

    @State private var selectedRole: ColumnRole

    init(assignment: ColumnAssignment, sampleValues: [String], onChange: @escaping (ColumnRole) -> Void) {
        self.assignment = assignment
        self.sampleValues = sampleValues
        self.onChange = onChange
        _selectedRole = State(initialValue: assignment.role)
    }

    var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.md) {
            // Column header
            VStack(alignment: .leading, spacing: 4) {
                Text("Col \(assignment.columnIndex + 1)")
                    .font(.hbLabelSmall.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                ForEach(sampleValues, id: \.self) { val in
                    Text(val)
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Role picker
            Picker("", selection: $selectedRole) {
                ForEach(ColumnRole.allCases, id: \.self) { role in
                    Text(role.displayName).tag(role)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.hbPrimary)
            .onChange(of: selectedRole) { _, newRole in
                onChange(newRole)
            }
        }
        .padding(HBSpacing.sm)
        .background(assignment.role == .ignore ? Color.clear : Color.hbPrimaryContainer.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.hbSurfaceVariant, lineWidth: 1)
        )
        .onAppear { selectedRole = assignment.role }
    }
}

// MARK: - Preview Row

private struct PreviewRowView: View {
    let row: ImportedRow

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            if let date = row.date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                    .frame(width: 80, alignment: .leading)
            }

            Text(row.descriptionText)
                .font(.hbLabelLarge)
                .foregroundStyle(Color.hbOnSurface)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let amount = row.amount {
                Text(amount.formatted(.currency(code: "EUR")))
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(amount >= 0 ? Color.hbPositive : Color.hbNegative)
            }
        }
        .padding(.vertical, HBSpacing.xs)
        .padding(.horizontal, HBSpacing.sm)
        Divider()
    }
}

// MARK: - Labeled Chip

private struct LabeledChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.hbOnSurfaceVariant)
                .tracking(0.5)
            Text(value)
                .font(.hbLabelSmall.weight(.semibold))
                .foregroundStyle(Color.hbOnSurface)
        }
        .padding(.horizontal, HBSpacing.sm)
        .padding(.vertical, HBSpacing.xs)
        .background(Color.hbSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Pro Tip Card

struct ProTipCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.hbPrimary)
                .padding(HBSpacing.sm)
                .background(Color.hbPrimaryContainer)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: HBSpacing.xs) {
                Text(title)
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                Text(LocalizedStringKey(message))
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbPrimaryContainer.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
    }
}
