import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID = UUID()
    /// Optional external ID provided by the bank (used for deduplication).
    var externalId: String? = nil
    var date: Date = Date()
    var valueDate: Date? = nil
    /// Stored as Decimal for exact monetary precision. Never use Double for money.
    var amount: Decimal = 0
    var descriptionText: String = ""
    var notes: String? = nil
    var isTransfer: Bool = false
    /// SHA-256 hash of normalised (date + amount + description) for composite dedup.
    var importHash: String? = nil
    /// UUID of the matching transaction on the other side of an internal transfer.
    /// Stored as a plain UUID (not a @Relationship) to remain CloudKit-compatible.
    var linkedTransactionId: UUID? = nil

    var account: BankAccount? = nil
    var category: Category? = nil
    var subcategory: Subcategory? = nil
    var importBatch: ImportBatch? = nil

    init(
        externalId: String? = nil,
        date: Date,
        valueDate: Date? = nil,
        amount: Decimal,
        descriptionText: String,
        notes: String? = nil,
        isTransfer: Bool = false,
        importHash: String? = nil
    ) {
        self.externalId = externalId
        self.date = date
        self.valueDate = valueDate
        self.amount = amount
        self.descriptionText = descriptionText
        self.notes = notes
        self.isTransfer = isTransfer
        self.importHash = importHash
    }
}
