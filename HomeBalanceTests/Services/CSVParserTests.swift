import Testing
import Foundation
@testable import HomeBalance

@Suite("CSVParser")
@MainActor
struct CSVParserTests {

    // MARK: - Helpers

    private func csvURL(content: String) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".csv")
        try content.write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    private func defaultConfig() -> CSVParser.Configuration {
        CSVParser.Configuration(
            delimiter: ";",
            encoding: .utf8,
            skipHeaderRows: 1,
            decimalSeparator: ",",
            dateFormats: ["dd/MM/yyyy"]
        )
    }

    private func fullMapping() -> ColumnConfig {
        ColumnConfig(assignments: [
            ColumnAssignment(columnIndex: 0, role: .date),
            ColumnAssignment(columnIndex: 1, role: .description),
            ColumnAssignment(columnIndex: 2, role: .amount)
        ])
    }

    // MARK: - Tests

    @Test("Parses basic CSV with header row")
    func parsesBasicCSV() throws {
        let csv = """
        Fecha;Concepto;Importe
        15/01/2024;Mercadona;-52,30
        20/01/2024;Nómina;1500,00
        """
        let url = try csvURL(content: csv)
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: fullMapping())
        #expect(rows.count == 2)
        #expect(rows[0].descriptionText == "Mercadona")
        #expect(rows[1].amount == Decimal(string: "1500"))
    }

    @Test("Parses negative amounts correctly")
    func parsesNegativeAmount() throws {
        let csv = "Fecha;Concepto;Importe\n01/03/2024;Spotify;-9,99"
        let url = try csvURL(content: csv)
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: fullMapping())
        #expect(rows.count == 1)
        #expect(rows[0].amount == Decimal(string: "-9.99"))
    }

    @Test("Skips rows missing date and amount")
    func skipsEmptyRows() throws {
        let csv = "Fecha;Concepto;Importe\n;comentario;\n15/01/2024;Amazon;-30,00"
        let url = try csvURL(content: csv)
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: fullMapping())
        #expect(rows.count == 1)
    }

    @Test("Returns header row in rawPreview")
    func rawPreviewIncludesHeader() throws {
        let csv = "Fecha;Concepto;Importe\n15/01/2024;Amazon;-30,00"
        let url = try csvURL(content: csv)
        let preview = try CSVParser().rawPreview(url: url, config: defaultConfig(), count: 3)
        #expect(preview.isEmpty == false)
        #expect(preview[0] == ["Fecha", "Concepto", "Importe"])
    }

    @Test("Preview mode returns at most maxPreviewRows")
    func previewModeLimit() throws {
        var lines = ["Fecha;Concepto;Importe"]
        for i in 1...10 {
            lines.append("0\(i)/01/2024;Row\(i);-1,00")
        }
        let url = try csvURL(content: lines.joined(separator: "\n"))
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: fullMapping(), previewOnly: true, maxPreviewRows: 3)
        #expect(rows.count == 3)
    }

    @Test("Debit/credit columns resolve to net amount")
    func debitCreditResolution() throws {
        let mapping = ColumnConfig(assignments: [
            ColumnAssignment(columnIndex: 0, role: .date),
            ColumnAssignment(columnIndex: 1, role: .description),
            ColumnAssignment(columnIndex: 2, role: .debit),
            ColumnAssignment(columnIndex: 3, role: .credit)
        ])
        let csv = "Fecha;Concepto;Cargo;Abono\n01/01/2024;Alquiler;800,00;\n01/01/2024;Nómina;;2000,00"
        let url = try csvURL(content: csv)
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: mapping)
        #expect(rows.count == 2)
        #expect(rows[0].amount == Decimal(-800))  // credit 0 - debit 800
        #expect(rows[1].amount == Decimal(2000))  // credit 2000 - debit 0
    }

    @Test("importHash is computed from date+amount+description")
    func importHashNotNil() throws {
        let csv = "Fecha;Concepto;Importe\n15/01/2024;Netflix;-12,99"
        let url = try csvURL(content: csv)
        let rows = try CSVParser().parse(url: url, config: defaultConfig(), columnConfig: fullMapping())
        #expect(rows[0].importHash != nil)
    }
}
