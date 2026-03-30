import SwiftUI
import SwiftData

/// Full transaction list with search, filters and CRUD actions.
struct TransactionListView: View {
    let household: Household

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionListViewModel()
    @State private var showingEditor = false
    @State private var showingFilters = false
    @State private var editingTransaction: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteConfirm = false

    private let repository = TransactionRepository()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.transactions.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: viewModel.hasActiveFilters
                        ? "no_transactions_matching_filters"
                        : "no_transactions_yet",
                    subtitle: viewModel.hasActiveFilters
                        ? "clear_filters_to_see_all"
                        : "tap_plus_to_add_first",
                    actionTitle: viewModel.hasActiveFilters ? "clear_filters" : nil,
                    action: viewModel.hasActiveFilters ? { viewModel.clearFilters() } : nil
                )
            } else {
                List {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            currency: household.currency
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTransaction = transaction
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                transactionToDelete = transaction
                                showingDeleteConfirm = true
                            } label: {
                                Label("delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingTransaction = transaction
                            } label: {
                                Label("edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("transactions")
        .searchable(text: $viewModel.searchText, prompt: "search_transactions")
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.loadTransactions(for: household, context: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingFilters = true
                } label: {
                    Label("filters", systemImage: viewModel.hasActiveFilters
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            TransactionEditorView(household: household)
                .onDisappear {
                    viewModel.loadTransactions(for: household, context: modelContext)
                }
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionEditorView(household: household, editing: transaction)
                .onDisappear {
                    editingTransaction = nil
                    viewModel.loadTransactions(for: household, context: modelContext)
                }
        }
        .sheet(isPresented: $showingFilters) {
            TransactionFilterView(
                viewModel: $viewModel,
                household: household,
                onApply: {
                    viewModel.loadTransactions(for: household, context: modelContext)
                }
            )
        }
        .confirmationDialog(
            "delete_transaction_title",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("delete", role: .destructive) {
                if let t = transactionToDelete {
                    try? repository.delete(t, in: modelContext)
                    viewModel.loadTransactions(for: household, context: modelContext)
                }
                transactionToDelete = nil
            }
            Button("cancel", role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            Text("delete_transaction_message")
        }
        .onAppear {
            viewModel.loadTransactions(for: household, context: modelContext)
        }
    }
}
