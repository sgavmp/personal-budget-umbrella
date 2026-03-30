import SwiftData
import Foundation

/// Saved column-mapping template for a specific bank.
/// Reused automatically when a file from the same bank is imported again.
@Model
final class ImportMapping {
    var id: UUID = UUID()
    var bankName: String = ""
    /// JSON-encoded ColumnConfig (source column index → transaction field).
    var columnConfigData: Data = Data()
    var skipRows: Int = 0
    var skipColumns: Int = 0
    /// String encoding name: "utf8", "isoLatin1", "windowsCP1252"
    var encoding: String = "utf8"
    /// Column delimiter: ",", ";", "\t"
    var delimiter: String = ";"
    /// Decimal separator used in the file: "." or ","
    var decimalSeparator: String = ","
    /// Date format string, e.g. "dd/MM/yyyy", "yyyy-MM-dd"
    var dateFormat: String = "dd/MM/yyyy"
    var createdDate: Date = Date()

    var household: Household? = nil

    init(
        bankName: String,
        columnConfigData: Data = Data(),
        skipRows: Int = 0,
        skipColumns: Int = 0,
        encoding: String = "utf8",
        delimiter: String = ";",
        decimalSeparator: String = ",",
        dateFormat: String = "dd/MM/yyyy"
    ) {
        self.bankName = bankName
        self.columnConfigData = columnConfigData
        self.skipRows = skipRows
        self.skipColumns = skipColumns
        self.encoding = encoding
        self.delimiter = delimiter
        self.decimalSeparator = decimalSeparator
        self.dateFormat = dateFormat
    }
}
