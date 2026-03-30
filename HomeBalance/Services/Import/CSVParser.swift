import CodableCSV
import Foundation

// MARK: - CSV Parser

/// Parses a CSV file into `[ImportedRow]` using the provided column mapping.
/// Thin wrapper over CodableCSV — all work happens off the main thread.
struct CSVParser: Sendable {

    struct Configuration: Sendable {
        var delimiter: Character = ","
        var encoding: String.Encoding = .utf8
        var skipHeaderRows: Int = 1
        var decimalSeparator: Character = "."
        var dateFormats: [String] = ["dd/MM/yyyy", "yyyy-MM-dd", "MM/dd/yyyy", "dd-MM-yyyy"]
    }

    // MARK: - Public API

    func parse(
        url: URL,
        config: Configuration,
        columnConfig: ColumnConfig,
        previewOnly: Bool = false,
        maxPreviewRows: Int = 5
    ) throws -> [ImportedRow] {
        let rawString = try loadString(url: url, encoding: config.encoding)
        let allRows = try readAllRows(string: rawString, delimiter: config.delimiter)
        let dataRows = Array(allRows.dropFirst(config.skipHeaderRows))
        let targetRows = previewOnly ? Array(dataRows.prefix(maxPreviewRows)) : dataRows

        return targetRows.enumerated().compactMap { (idx, columns) in
            buildRow(index: config.skipHeaderRows + idx,
                     columns: columns,
                     columnConfig: columnConfig,
                     config: config)
        }
    }

    func rawPreview(url: URL, config: Configuration, count: Int = 6) throws -> [[String]] {
        let rawString = try loadString(url: url, encoding: config.encoding)
        let allRows = try readAllRows(string: rawString, delimiter: config.delimiter)
        return Array(allRows.prefix(count))
    }

    // MARK: - Core parsing

    private func loadString(url: URL, encoding: String.Encoding) throws -> String {
        let data = try Data(contentsOf: url)
        if let s = String(data: data, encoding: encoding) { return s }
        if let s = String(data: data, encoding: .isoLatin1) { return s }
        if let s = String(data: data, encoding: .windowsCP1252) { return s }
        throw ImportError.unreadableEncoding
    }

    private func readAllRows(string: String, delimiter: Character) throws -> [[String]] {
        let delimStr = String(delimiter)
        var readerConfig = CSVReader.Configuration()
        readerConfig.delimiters.field = Delimiter.Field(stringLiteral: delimStr)
        readerConfig.headerStrategy = .none

        let reader = try CSVReader(input: string, configuration: readerConfig)
        var result: [[String]] = []
        while let row = try reader.readRow() {
            result.append(row)
        }
        return result
    }

    // MARK: - Row Builder

    private func buildRow(
        index: Int,
        columns: [String],
        columnConfig: ColumnConfig,
        config: Configuration
    ) -> ImportedRow? {
        func col(_ role: ColumnRole) -> String? {
            guard let i = columnConfig.index(for: role), i < columns.count else { return nil }
            let v = columns[i].trimmingCharacters(in: .whitespacesAndNewlines)
            return v.isEmpty ? nil : v
        }

        let parsedDate      = col(.date).flatMap { parseDate($0, formats: config.dateFormats) }
        let valueDateParsed = col(.valueDate).flatMap { parseDate($0, formats: config.dateFormats) }
        let desc            = col(.description) ?? ""
        let extId           = col(.externalId)
        let notesStr        = col(.notes)

        let parsedAmount: Decimal?
        if let raw = col(.amount) {
            parsedAmount = parseDecimal(raw, separator: config.decimalSeparator)
        } else {
            let credit = col(.credit).flatMap { parseDecimal($0, separator: config.decimalSeparator) } ?? 0
            let debit  = col(.debit).flatMap  { parseDecimal($0, separator: config.decimalSeparator) } ?? 0
            parsedAmount = (credit != 0 || debit != 0) ? (credit - debit) : nil
        }

        guard parsedDate != nil || parsedAmount != nil else { return nil }

        return ImportedRow(
            id: index,
            rowIndex: index,
            date: parsedDate,
            valueDate: valueDateParsed,
            amount: parsedAmount,
            descriptionText: desc,
            externalId: extId,
            notes: notesStr,
            rawColumns: columns
        )
    }

    // MARK: - Helpers

    private func parseDate(_ string: String, formats: [String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }

    private func parseDecimal(_ string: String, separator: Character) -> Decimal? {
        var normalised = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")

        if separator == "," {
            normalised = normalised
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else {
            normalised = normalised.replacingOccurrences(of: ",", with: "")
        }

        return Decimal(string: normalised)
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case unreadableEncoding
    case missingRequiredColumns([ColumnRole])
    case noRowsParsed
    case unsupportedFileType(String)

    var errorDescription: String? {
        switch self {
        case .unreadableEncoding:
            return "Could not decode the file. Try a different encoding."
        case .missingRequiredColumns(let roles):
            let names = roles.map(\.displayName).joined(separator: ", ")
            return "Required columns not mapped: \(names)."
        case .noRowsParsed:
            return "No valid rows found in the file."
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext). Use CSV or XLSX."
        }
    }
}
