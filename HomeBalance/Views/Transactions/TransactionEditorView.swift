import SwiftUI
import SwiftData

/// Form to create or edit a Transaction.
/// Design: "The Financial Curator" — styled toolbar buttons, hbSurface background.
struct TransactionEditorView: View {
    let household: Household
    var editingTransaction: Transaction?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: TransactionEditorViewModel

    init(household: Household, editing transaction: Transaction? = nil) {
        self.household = household
        self.editingTransaction = transaction
        _viewModel = State(initialValue: TransactionEditorViewModel(editing: transaction))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type toggle
                Section {
                    Picker("type", selection: $viewModel.isExpense) {
                        Text("expense").tag(true)
                        Text("income").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.hbSurfaceLow)

                // Amount + Description
                Section("details") {
                    AmountField(
                        label: "amount",
                        text: $viewModel.amountString,
                        currency: household.currency
                    )
                    .listRowInsets(EdgeInsets(
                        top: HBSpacing.sm,
                        leading: HBSpacing.md,
                        bottom: HBSpacing.sm,
                        trailing: HBSpacing.md
                    ))

                    TextField("description", text: $viewModel.descriptionText)
                    DatePicker("date", selection: $viewModel.date, displayedComponents: .date)
                }

                // Category
                Section("category") {
                    CategoryPickerView(
                        selectedCategory: $viewModel.selectedCategory,
                        selectedSubcategory: $viewModel.selectedSubcategory,
                        categories: household.categories,
                        typeFilter: viewModel.isExpense ? "expense" : "income"
                    )
                    .onChange(of: viewModel.selectedCategory) { _, _ in
                        viewModel.refreshSubcategory()
                    }
                }

                // Account
                Section("account") {
                    Picker("account", selection: $viewModel.selectedAccount) {
                        Text("none").tag(Optional<BankAccount>.none)
                        ForEach(household.bankAccounts) { account in
                            Text(account.name).tag(Optional(account))
                        }
                    }
                }

                // Notes
                Section("notes_optional") {
                    TextField("notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.hbSurface)
            .navigationTitle(viewModel.isEditing ? "edit_transaction" : "new_transaction")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        viewModel.save(in: modelContext)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.hbPrimary)
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(.hbOnSurfaceVariant)
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
            .alert("error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("ok") { viewModel.errorMessage = nil }
            } message: {
                if let msg = viewModel.errorMessage { Text(msg) }
            }
        }
    }
}
