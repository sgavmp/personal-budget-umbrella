import CoreXLSX
import Foundation

// MARK: - XLSX Parser

/// Parses `.xlsx` files into `[ImportedRow]` using `CoreXLSX`.
struct XLSXParser: Sendable {

    struct Configuration: Sendable {
        var sheetIndex: Int = 0
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
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.unreadableEncoding
        }

        let workbooks = try file.parseWorkbooks()
        guard let workbook = workbooks.first else {
            throw ImportError.noRowsParsed
        }

        let paths = try file.parseWorksheetPathsAndNames(workbook: workbook)
        guard config.sheetIndex < paths.count else {
            throw ImportError.noRowsParsed
        }

        let sheetPath = paths[config.sheetIndex].path
        let worksheet = try file.parseWorksheet(at: sheetPath)
        let sharedStrings = try? file.parseSharedStrings()

        guard let rows = worksheet.data?.rows else { return [] }
        let dataRows = rows.dropFirst(config.skipHeaderRows)
        let targetRows = previewOnly ? Array(dataRows.prefix(maxPreviewRows)) : Array(dataRows)

        return targetRows.enumerated().compactMap { (idx, row) in
            let columns = extractColumns(row: row, sharedStrings: sharedStrings)
            return buildRow(
                index: config.skipHeaderRows + idx,
                columns: columns,
                columnConfig: columnConfig,
                config: config
            )
        }
    }

    /// Returns raw rows (as string arrays) for preview purposes.
    func rawPreview(url: URL, config: Configuration, count: Int = 6) throws -> [[String]] {
        guard let file = XLSXFile(filepath: url.path) else { return [] }
        let workbooks = try file.parseWorkbooks()
        guard let workbook = workbooks.first else { return [] }
        let paths = try file.parseWorksheetPathsAndNames(workbook: workbook)
        guard config.sheetIndex < paths.count else { return [] }
        let worksheet = try file.parseWorksheet(at: paths[config.sheetIndex].path)
        let sharedStrings = try? file.parseSharedStrings()
        guard let rows = worksheet.data?.rows else { return [] }
        return rows.prefix(count).map { extractColumns(row: $0, sharedStrings: sharedStrings) }
    }

    // MARK: - Row extraction

    private func extractColumns(row: Row, sharedStrings: SharedStrings?) -> [String] {
        row.cells.map { cell -> String in
            if let s = sharedStrings.flatMap({ cell.stringValue($0) }) { return s }
            if let v = cell.value { return v }
            return ""
        }
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

        let parsedDate    = col(.date).flatMap { parseDate($0, formats: config.dateFormats) }
        let valueDateParsed = col(.valueDate).flatMap { parseDate($0, formats: config.dateFormats) }
        let desc          = col(.description) ?? ""
        let extId         = col(.externalId)
        let notesStr      = col(.notes)

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

    private func parseDate(_ string: String, formats: [String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let d = formatter.date(from: string) { return d }
        }
        return nil
    }

    private func parseDecimal(_ string: String, separator: Character) -> Decimal? {
        var s = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
        if separator == "," {
            s = s.replacingOccurrences(of: ".", with: "")
                 .replacingOccurrences(of: ",", with: ".")
        } else {
            s = s.replacingOccurrences(of: ",", with: "")
        }
        return Decimal(string: s)
    }
}
