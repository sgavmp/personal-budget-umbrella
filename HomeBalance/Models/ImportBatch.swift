import SwiftData
import Foundation

/// Records a single file import operation for audit and undo purposes.
@Model
final class ImportBatch {
    var id: UUID = UUID()
    var date: Date = Date()
    var filename: String = ""
    var rowCount: Int = 0
    /// "completed", "partial", "failed"
    var status: String = "completed"

    var account: BankAccount? = nil

    @Relationship(deleteRule: .nullify, inverse: \Transaction.importBatch)
    var transactions: [Transaction] = []

    init(filename: String, rowCount: Int, status: String = "completed") {
        self.filename = filename
        self.rowCount = rowCount
        self.status = status
    }
}
