import Testing
import Foundation
import SwiftData
@testable import HomeBalance

@Suite("ImportWizardViewModel")
@MainActor
struct ImportWizardViewModelTests {

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(ModelVersion.v1.models), configurations: [config])
        return container.mainContext
    }

    private func makeHousehold(context: ModelContext) throws -> Household {
        let h = Household(name: "Test Family", currency: "EUR")
        context.insert(h)
        try context.save()
        return h
    }

    private func csvURL(content: String) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".csv")
        try content.write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    // MARK: - Tests

    @Test("Initial step is fileSelection")
    func initialStep() {
        let vm = ImportWizardViewModel()
        #expect(vm.step == .fileSelection)
    }

    @Test("canAdvance is false without file and account")
    func cannotAdvanceWithoutFileAndAccount() {
        let vm = ImportWizardViewModel()
        #expect(vm.canAdvance() == false)
    }

    @Test("setFile sets filename and detects delimiter")
    func setFileDetectsDelimiter() throws {
        let csv = "Fecha;Concepto;Importe\n01/01/2024;Spotify;-9,99"
        let url = try csvURL(content: csv)
        let vm = ImportWizardViewModel()
        vm.setFile(url: url)
        #expect(vm.filename.hasSuffix(".csv"))
        #expect(vm.csvDelimiter == ";")
    }

    @Test("canAdvance true after file + account set")
    func canAdvanceWithFileAndAccount() throws {
        let context = try makeContext()
        let household = try makeHousehold(context: context)
        let account = BankAccount(name: "Joint", bankName: "BBVA", accountType: "checking")
        account.household = household
        context.insert(account)
        try context.save()

        let csv = "Fecha;Concepto;Importe\n01/01/2024;Amazon;-10,00"
        let url = try csvURL(content: csv)

        let vm = ImportWizardViewModel()
        vm.setFile(url: url)
        vm.selectedAccount = account
        #expect(vm.canAdvance() == true)
    }

    @Test("toggleResult flips isSelected")
    func toggleResult() {
        let row = ImportedRow(
            id: 0, rowIndex: 0, date: Date(), valueDate: nil,
            amount: -10, descriptionText: "Test", externalId: nil, notes: nil, rawColumns: []
        )
        let vm = ImportWizardViewModel()
        vm.duplicateResults = [DuplicateResult(row: row, status: .new)]
        #expect(vm.duplicateResults[0].isSelected == true)
        vm.toggleResult(id: 0)
        #expect(vm.duplicateResults[0].isSelected == false)
    }

    @Test("selectAll sets all rows to given state")
    func selectAll() {
        let rows = (0..<5).map { i in
            ImportedRow(id: i, rowIndex: i, date: Date(), valueDate: nil,
                        amount: -1, descriptionText: "R\(i)", externalId: nil, notes: nil, rawColumns: [])
        }
        let vm = ImportWizardViewModel()
        vm.duplicateResults = rows.map { DuplicateResult(row: $0, status: .new) }
        vm.selectAll(false)
        #expect(vm.selectedCount == 0)
        vm.selectAll(true)
        #expect(vm.selectedCount == 5)
    }

    @Test("selectedCount reflects selected results")
    func selectedCountAccurate() {
        let vm = ImportWizardViewModel()
        let rows = (0..<4).map { i in
            ImportedRow(id: i, rowIndex: i, date: Date(), valueDate: nil,
                        amount: -1, descriptionText: "R\(i)", externalId: nil, notes: nil, rawColumns: [])
        }
        vm.duplicateResults = [
            DuplicateResult(row: rows[0], status: .new),
            DuplicateResult(row: rows[1], status: .exact),   // deselected by default
            DuplicateResult(row: rows[2], status: .new),
            DuplicateResult(row: rows[3], status: .potential)
        ]
        // new=2 selected, exact=0, potential=1 selected → 3 total
        #expect(vm.selectedCount == 3)
    }

    @Test("back() decrements step")
    func backDecrementsStep() {
        let vm = ImportWizardViewModel()
        vm.step = .columnMapping
        vm.back()
        #expect(vm.step == .fileSelection)
    }

    @Test("back() is no-op on first step")
    func backNoOpOnFirstStep() {
        let vm = ImportWizardViewModel()
        vm.back()
        #expect(vm.step == .fileSelection)
    }
}
