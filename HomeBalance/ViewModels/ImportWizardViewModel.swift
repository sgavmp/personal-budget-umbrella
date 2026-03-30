import Foundation
import SwiftData
import SwiftUI

// MARK: - Wizard Step

enum ImportWizardStep: Int, CaseIterable {
    case fileSelection   = 1
    case columnMapping   = 2
    case duplicateReview = 3
    case complete        = 4

    var title: String {
        switch self {
        case .fileSelection:   return "Upload Your Records"
        case .columnMapping:   return "Refine Your Data Structure"
        case .duplicateReview: return "Refining Your Import"
        case .complete:        return "Import Complete"
        }
    }
}

// MARK: - ImportWizardViewModel

@MainActor
@Observable
final class ImportWizardViewModel {

    // MARK: - State

    var step: ImportWizardStep = .fileSelection
    var isLoading = false
    var errorMessage: String?

    // Step 1: File selection
    var fileURL: URL?
    var filename: String = ""
    var selectedAccount: BankAccount?
    var bankName: String = ""

    // CSV Configuration
    var csvDelimiter: Character = ";"
    var csvEncoding: String.Encoding = .utf8
    var csvSkipHeaderRows: Int = 1
    var csvDecimalSeparator: Character = ","
    var csvDateFormats: [String] = ["dd/MM/yyyy", "yyyy-MM-dd", "MM/dd/yyyy"]

    // Step 2: Column mapping
    var rawPreviewRows: [[String]] = []       // First 6 rows for display
    var columnConfig: ColumnConfig = ColumnConfig(assignments: [])
    var previewRows: [ImportedRow] = []       // First 5 parsed rows

    // Step 3: Duplicate review
    var duplicateResults: [DuplicateResult] = []
    var newCount: Int { duplicateResults.filter { $0.status == .new }.count }
    var potentialCount: Int { duplicateResults.filter { $0.status == .potential }.count }
    var exactCount: Int { duplicateResults.filter { $0.status == .exact }.count }
    var selectedCount: Int { duplicateResults.filter(\.isSelected).count }

    // Step 4: Complete
    var completedBatch: ImportBatch?
    var importedCount: Int = 0

    // MARK: - Dependencies

    private let engine = ImportEngine()
    private let ruleRepo = CategoryRuleRepository()
    private let batchRepo = ImportBatchRepository()

    // MARK: - Navigation

    func canAdvance() -> Bool {
        switch step {
        case .fileSelection:   return fileURL != nil && selectedAccount != nil
        case .columnMapping:   return columnConfig.index(for: .date) != nil
                                   || columnConfig.index(for: .amount) != nil
        case .duplicateReview: return selectedCount > 0
        case .complete:        return false
        }
    }

    func advance(household: Household, context: ModelContext) {
        switch step {
        case .fileSelection:
            Task { await loadPreview() }
        case .columnMapping:
            Task { await classifyDuplicates(context: context) }
        case .duplicateReview:
            Task { await commitImport(household: household, context: context) }
        case .complete:
            break
        }
    }

    func back() {
        guard step != .fileSelection else { return }
        step = ImportWizardStep(rawValue: step.rawValue - 1) ?? .fileSelection
        errorMessage = nil
    }

    // MARK: - Step transitions

    /// Called when user picks a file (Step 1 → starts parsing preview for Step 2).
    func setFile(url: URL) {
        fileURL = url
        filename = url.lastPathComponent
        // Auto-detect delimiter from extension
        if url.pathExtension.lowercased() == "csv" {
            // Peek at first line to detect delimiter
            if let raw = try? String(contentsOf: url, encoding: .utf8),
               let first = raw.components(separatedBy: "\n").first {
                if first.contains(";") { csvDelimiter = ";" }
                else if first.contains("\t") { csvDelimiter = "\t" }
                else { csvDelimiter = "," }
            }
        }
    }

    private func loadPreview() async {
        guard let url = fileURL else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let csvConfig = makeCSVConfig()
            let raw = try engine.rawPreview(url: url, csvConfig: csvConfig)
            rawPreviewRows = raw

            // Auto-detect from headers (first row)
            let headers = raw.first ?? []
            columnConfig = engine.autoDetectMapping(headers: headers)

            // Parse 5 preview rows with current mapping
            previewRows = try engine.parseFile(
                url: url,
                csvConfig: csvConfig,
                columnConfig: columnConfig,
                previewOnly: true
            )

            step = .columnMapping
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when column mappings change — refreshes the 5-row preview.
    func refreshPreview() {
        guard let url = fileURL else { return }
        Task {
            do {
                let csvConfig = makeCSVConfig()
                previewRows = try engine.parseFile(
                    url: url,
                    csvConfig: csvConfig,
                    columnConfig: columnConfig,
                    previewOnly: true
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func classifyDuplicates(context: ModelContext) async {
        guard let url = fileURL else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let csvConfig = makeCSVConfig()
            let allRows = try engine.parseFile(
                url: url,
                csvConfig: csvConfig,
                columnConfig: columnConfig
            )
            duplicateResults = try engine.classifyDuplicates(
                rows: allRows,
                account: selectedAccount,
                context: context
            )
            step = .duplicateReview
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commitImport(household: Household, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let rules = try ruleRepo.snapshots(for: household, context: context)
            let batch = try engine.commitImport(
                results: duplicateResults,
                account: selectedAccount,
                household: household,
                rules: rules,
                filename: filename,
                context: context
            )
            completedBatch = batch
            importedCount = batch.rowCount
            step = .complete
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func makeCSVConfig() -> CSVParser.Configuration {
        CSVParser.Configuration(
            delimiter: csvDelimiter,
            encoding: csvEncoding,
            skipHeaderRows: csvSkipHeaderRows,
            decimalSeparator: csvDecimalSeparator,
            dateFormats: csvDateFormats
        )
    }

    func toggleResult(id: Int) {
        guard let idx = duplicateResults.firstIndex(where: { $0.id == id }) else { return }
        duplicateResults[idx].isSelected.toggle()
    }

    func selectAll(_ selected: Bool) {
        for idx in duplicateResults.indices {
            duplicateResults[idx].isSelected = selected
        }
    }
}
