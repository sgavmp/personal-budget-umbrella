import SwiftUI

/// Sheet showing all filter options for the transaction list.
struct TransactionFilterView: View {
    @Binding var viewModel: TransactionListViewModel
    let household: Household
    var onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("date_range") {
                    DateRangePicker(
                        startDate: $viewModel.startDate,
                        endDate: $viewModel.endDate
                    )
                }

                Section("category") {
                    Picker("category", selection: $viewModel.selectedCategory) {
                        Text("all_categories").tag(Optional<Category>.none)
                        ForEach(household.categories.sorted { $0.sortOrder < $1.sortOrder }) { cat in
                            Label(cat.name, systemImage: cat.icon)
                                .tag(Optional(cat))
                        }
                    }
                }

                Section("account") {
                    Picker("account", selection: $viewModel.selectedAccount) {
                        Text("all_accounts").tag(Optional<BankAccount>.none)
                        ForEach(household.bankAccounts) { account in
                            Text(account.name).tag(Optional(account))
                        }
                    }
                }

                Section {
                    Toggle("show_transfers", isOn: $viewModel.showTransfers)
                }

                Section {
                    Button("clear_filters", role: .destructive) {
                        viewModel.clearFilters()
                    }
                }
            }
            .navigationTitle("filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("apply") {
                        onApply()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
        }
    }
}
