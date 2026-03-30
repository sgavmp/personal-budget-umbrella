import Foundation
import SwiftData

// MARK: - Import Engine

/// Orchestrates the full import pipeline:
///   parse → classify duplicates → apply categorisation → commit to SwiftData.
@MainActor
final class ImportEngine {

    private let csvParser = CSVParser()
    private let xlsxParser = XLSXParser()
    private let duplicateDetector = DuplicateDetector()
    private let categorizationEngine = CategorizationEngine()

    // MARK: - Step 1: Parse

    /// Parse a file (CSV or XLSX) and return staged rows.
    func parseFile(
        url: URL,
        csvConfig: CSVParser.Configuration,
        columnConfig: ColumnConfig,
        previewOnly: Bool = false
    ) throws -> [ImportedRow] {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "csv", "txt":
            return try csvParser.parse(url: url, config: csvConfig, columnConfig: columnConfig, previewOnly: previewOnly)
        case "xlsx":
            var xlsxConfig = XLSXParser.Configuration()
            xlsxConfig.decimalSeparator = csvConfig.decimalSeparator
            xlsxConfig.dateFormats = csvConfig.dateFormats
            xlsxConfig.skipHeaderRows = csvConfig.skipHeaderRows
            return try xlsxParser.parse(url: url, config: xlsxConfig, columnConfig: columnConfig, previewOnly: previewOnly)
        default:
            throw ImportError.unsupportedFileType(ext)
        }
    }

    /// Return raw column headers for display in the mapping step.
    func rawPreview(url: URL, csvConfig: CSVParser.Configuration) throws -> [[String]] {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "csv", "txt":
            return try csvParser.rawPreview(url: url, config: csvConfig)
        case "xlsx":
            var xlsxConfig = XLSXParser.Configuration()
            xlsxConfig.skipHeaderRows = 0
            return try xlsxParser.rawPreview(url: url, config: xlsxConfig)
        default:
            return []
        }
    }

    // MARK: - Step 2: Auto-detect column mapping

    /// Heuristically map column headers to `ColumnRole`s.
    func autoDetectMapping(headers: [String]) -> ColumnConfig {
        var assignments: [ColumnAssignment] = []
        for (idx, header) in headers.enumerated() {
            let h = header.lowercased()
            let role: ColumnRole
            if h.contains("fecha") || h.contains("date") || h == "f. valor" { role = .date }
            else if h.contains("valor") || h.contains("valuedate")           { role = .valueDate }
            else if h.contains("importe") || h.contains("amount") || h.contains("saldo parcial") { role = .amount }
            else if h.contains("debe") || h.contains("debit") || h.contains("cargo")             { role = .debit }
            else if h.contains("haber") || h.contains("credit") || h.contains("abono")           { role = .credit }
            else if h.contains("concepto") || h.contains("descri") || h.contains("movimiento")  { role = .description }
            else if h.contains("referencia") || h.contains("ref") || h.contains("id")            { role = .externalId }
            else if h.contains("nota") || h.contains("comentario") || h.contains("observ")       { role = .notes }
            else                                                                                   { role = .ignore }
            assignments.append(ColumnAssignment(columnIndex: idx, role: role))
        }
        return ColumnConfig(assignments: assignments)
    }

    // MARK: - Step 3: Classify duplicates

    func classifyDuplicates(
        rows: [ImportedRow],
        account: BankAccount?,
        context: ModelContext
    ) throws -> [DuplicateResult] {
        var descriptor = FetchDescriptor<Transaction>()
        if let account {
            let accountId = account.id
            descriptor.predicate = #Predicate<Transaction> { $0.account?.id == accountId }
        }
        let existing = try context.fetch(descriptor).map {
            ExistingTransaction(
                id: $0.id,
                date: $0.date,
                amount: $0.amount,
                descriptionText: $0.descriptionText,
                importHash: $0.importHash,
                externalId: $0.externalId
            )
        }
        return duplicateDetector.classify(rows: rows, against: existing)
    }

    // MARK: - Step 4: Commit

    /// Commits selected rows to SwiftData and records the `ImportBatch`.
    /// Returns the batch ID for display in the completion screen.
    @discardableResult
    func commitImport(
        results: [DuplicateResult],
        account: BankAccount?,
        household: Household,
        rules: [RuleSnapshot],
        filename: String,
        context: ModelContext
    ) throws -> ImportBatch {
        let selectedRows = results.filter(\.isSelected).map(\.row)
        guard !selectedRows.isEmpty else { throw ImportError.noRowsParsed }

        // Fetch categories for rule assignment
        let allCategories = try context.fetch(FetchDescriptor<Category>())
        let allSubcategories = try context.fetch(FetchDescriptor<Subcategory>())

        let batch = ImportBatch(filename: filename, rowCount: selectedRows.count)
        batch.account = account
        context.insert(batch)

        for row in selectedRows {
            let tx = Transaction(
                externalId: row.externalId,
                date: row.date ?? Date(),
                valueDate: row.valueDate,
                amount: row.amount ?? 0,
                descriptionText: row.descriptionText,
                notes: row.notes,
                importHash: row.importHash
            )
            tx.account = account
            tx.importBatch = batch

            // Apply categorisation rules
            let result = categorizationEngine.categorise(row: row, rules: rules)
            if let catId = result.categoryId {
                tx.category = allCategories.first { $0.id == catId }
            }
            if let subId = result.subcategoryId {
                tx.subcategory = allSubcategories.first { $0.id == subId }
            }

            context.insert(tx)
            batch.transactions.append(tx)
        }

        try context.save()
        return batch
    }
}
