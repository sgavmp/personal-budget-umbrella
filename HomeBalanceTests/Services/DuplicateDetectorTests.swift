import Testing
import Foundation
@testable import HomeBalance

@Suite("DuplicateDetector")
@MainActor
struct DuplicateDetectorTests {

    private let detector = DuplicateDetector()

    private func calendar() -> Calendar { .current }

    private func row(
        desc: String, amount: Decimal, date: Date = Date(),
        importHash: String? = nil, externalId: String? = nil
    ) -> ImportedRow {
        ImportedRow(
            id: 0, rowIndex: 0,
            date: date, valueDate: nil,
            amount: amount, descriptionText: desc,
            externalId: externalId, notes: nil, rawColumns: []
        )
    }

    private func existing(
        desc: String, amount: Decimal, date: Date = Date(),
        importHash: String? = nil, externalId: String? = nil
    ) -> ExistingTransaction {
        ExistingTransaction(
            id: UUID(), date: date, amount: amount,
            descriptionText: desc, importHash: importHash, externalId: externalId
        )
    }

    // MARK: - Tests

    @Test("New transaction classified as .new when no matches")
    func newTransactionIsNew() {
        let r = row(desc: "Spotify", amount: -9.99)
        let results = detector.classify(rows: [r], against: [])
        #expect(results[0].status == .new)
    }

    @Test("Exact hash match classified as .exact")
    func exactHashMatch() throws {
        let r = row(desc: "Netflix", amount: -12.99, date: Date())
        guard let hash = r.importHash else { throw TestError.missingHash }
        let ex = existing(desc: "Netflix", amount: -12.99, date: Date(), importHash: hash)
        let results = detector.classify(rows: [r], against: [ex])
        #expect(results[0].status == .exact)
    }

    @Test("External ID match classified as .exact")
    func externalIdExact() {
        let r = row(desc: "Foo", amount: -5, externalId: "TXN-123")
        let ex = existing(desc: "Foo", amount: -5, externalId: "TXN-123")
        let results = detector.classify(rows: [r], against: [ex])
        #expect(results[0].status == .exact)
    }

    @Test("Similar description + same date + same amount is potential")
    func fuzzyPotential() {
        let date = Date()
        let r = row(desc: "MERCADONA SL", amount: -52.30, date: date)
        let ex = existing(desc: "Mercadona S.L.", amount: -52.30, date: date)
        let results = detector.classify(rows: [r], against: [ex])
        #expect(results[0].status == .potential)
    }

    @Test("Different amount is .new even if description matches")
    func differentAmountIsNew() {
        let date = Date()
        let r = row(desc: "MERCADONA", amount: -100, date: date)
        let ex = existing(desc: "MERCADONA", amount: -52.30, date: date)
        let results = detector.classify(rows: [r], against: [ex])
        #expect(results[0].status == .new)
    }

    @Test("Exact duplicates are deselected by default")
    func exactDefaultsDeselected() throws {
        let r = row(desc: "X", amount: -1, date: Date())
        guard let hash = r.importHash else { throw TestError.missingHash }
        let ex = existing(desc: "X", amount: -1, date: Date(), importHash: hash)
        let results = detector.classify(rows: [r], against: [ex])
        #expect(results[0].isSelected == false)
    }

    @Test("New rows are selected by default")
    func newDefaultsSelected() {
        let r = row(desc: "New Thing", amount: -5)
        let results = detector.classify(rows: [r], against: [])
        #expect(results[0].isSelected == true)
    }

    @Test("Multiple rows classified independently")
    func multipleRowsClassified() throws {
        let date = Date()
        let r1 = row(desc: "Netflix", amount: -12.99, date: date)
        let r2 = row(desc: "Brand New", amount: -500, date: date)
        guard let hash1 = r1.importHash else { throw TestError.missingHash }
        let ex = existing(desc: "Netflix", amount: -12.99, date: date, importHash: hash1)
        let results = detector.classify(rows: [r1, r2], against: [ex])
        #expect(results[0].status == .exact)
        #expect(results[1].status == .new)
    }
}

// MARK: - Test Error

private enum TestError: Error {
    case missingHash
}
