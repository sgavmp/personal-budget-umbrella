import SwiftData
import Foundation
import Observation

/// Manages form state for creating or editing a Transaction.
@MainActor
@Observable
final class TransactionEditorViewModel {

    // MARK: - Form Fields

    var date: Date = Date()
    var amountString: String = ""
    var isExpense: Bool = true           // expense (negative) vs income (positive)
    var descriptionText: String = ""
    var notes: String = ""
    var selectedCategory: Category?
    var selectedSubcategory: Subcategory?
    var selectedAccount: BankAccount?

    // MARK: - State

    var isSaving = false
    var errorMessage: String?
    var didSave = false

    // MARK: - Private

    private let repository: any TransactionRepositoryProtocol
    private let editingTransaction: Transaction?

    init(
        repository: any TransactionRepositoryProtocol = TransactionRepository(),
        editing transaction: Transaction? = nil
    ) {
        self.repository = repository
        self.editingTransaction = transaction
        if let t = transaction {
            populateFields(from: t)
        }
    }

    // MARK: - Computed

    var isValid: Bool {
        !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedAmount != nil &&
        selectedAccount != nil
    }

    var parsedAmount: Decimal? {
        let sep: Character = (Locale.current.decimalSeparator?.first) ?? "."
        return Decimal.parse(amountString, decimalSeparator: sep)
    }

    var isEditing: Bool { editingTransaction != nil }

    // MARK: - Save

    func save(in context: ModelContext) {
        guard let amount = parsedAmount, isValid else {
            errorMessage = String(localized: "invalid_amount_or_missing_fields")
            return
        }

        isSaving = true
        errorMessage = nil

        let signedAmount = isExpense ? -abs(amount) : abs(amount)

        do {
            if let existing = editingTransaction {
                // Mutate in place (all mutations stay in SwiftData graph)
                existing.date = date
                existing.amount = signedAmount
                existing.descriptionText = descriptionText.trimmingCharacters(in: .whitespaces)
                existing.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
                existing.category = selectedCategory
                existing.subcategory = selectedSubcategory
                existing.account = selectedAccount
                try context.save()
            } else {
                let transaction = Transaction(
                    date: date,
                    amount: signedAmount,
                    descriptionText: descriptionText.trimmingCharacters(in: .whitespaces),
                    notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
                )
                transaction.category = selectedCategory
                transaction.subcategory = selectedSubcategory
                transaction.account = selectedAccount
                try repository.save(transaction, in: context)
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    // MARK: - Subcategory refresh

    func refreshSubcategory() {
        if let cat = selectedCategory {
            if let sub = selectedSubcategory, sub.category?.id != cat.id {
                selectedSubcategory = nil
            }
        } else {
            selectedSubcategory = nil
        }
    }

    // MARK: - Private helpers

    private func populateFields(from transaction: Transaction) {
        date = transaction.date
        let abs = Swift.abs(transaction.amount)
        amountString = abs.description
        isExpense = transaction.amount < 0
        descriptionText = transaction.descriptionText
        notes = transaction.notes ?? ""
        selectedCategory = transaction.category
        selectedSubcategory = transaction.subcategory
        selectedAccount = transaction.account
    }
}
