import Foundation
import SwiftData

// MARK: - Duplicate Status

enum DuplicateStatus: Sendable {
    /// SHA-256 hash matches an existing transaction exactly.
    case exact
    /// Description similarity ≥ 0.85 and same date + approximate amount.
    case potential
    /// No match found.
    case new
}

// MARK: - Duplicate Result

struct DuplicateResult: Sendable, Identifiable {
    var id: Int { row.rowIndex }
    let row: ImportedRow
    let status: DuplicateStatus
    /// The best-matching existing transaction (nil for `.new`).
    let matchingTransactionId: UUID?
    let matchingTransactionDesc: String?
    let matchingTransactionDate: Date?
    let matchingTransactionAmount: Decimal?

    /// Whether the user has chosen to import this row (default true for `.new` and `.potential`).
    var isSelected: Bool

    init(row: ImportedRow, status: DuplicateStatus,
         matchingId: UUID? = nil, matchingDesc: String? = nil,
         matchingDate: Date? = nil, matchingAmount: Decimal? = nil) {
        self.row = row
        self.status = status
        self.matchingTransactionId = matchingId
        self.matchingTransactionDesc = matchingDesc
        self.matchingTransactionDate = matchingDate
        self.matchingTransactionAmount = matchingAmount
        // Exact duplicates are deselected by default; potential ones stay selected.
        self.isSelected = status != .exact
    }
}

// MARK: - Duplicate Detector

/// Classifies `ImportedRow` instances against existing transactions.
/// Pure logic — no SwiftData access (caller fetches transactions and passes them in).
struct DuplicateDetector: Sendable {

    /// Similarity threshold above which two descriptions are considered "potential duplicates".
    var fuzzyThreshold: Double = 0.85

    // MARK: - API

    /// Classify all rows against the provided existing transactions.
    func classify(rows: [ImportedRow], against existing: [ExistingTransaction]) -> [DuplicateResult] {
        rows.map { classify(row: $0, against: existing) }
    }

    // MARK: - Single row classification

    private func classify(row: ImportedRow, against existing: [ExistingTransaction]) -> DuplicateResult {
        // 1. Exact hash match
        if let hash = row.importHash,
           let match = existing.first(where: { $0.importHash == hash }) {
            return DuplicateResult(
                row: row, status: .exact,
                matchingId: match.id,
                matchingDesc: match.descriptionText,
                matchingDate: match.date,
                matchingAmount: match.amount
            )
        }

        // 2. External ID match (bank-provided unique IDs)
        if let extId = row.externalId, !extId.isEmpty,
           let match = existing.first(where: { $0.externalId == extId }) {
            return DuplicateResult(
                row: row, status: .exact,
                matchingId: match.id,
                matchingDesc: match.descriptionText,
                matchingDate: match.date,
                matchingAmount: match.amount
            )
        }

        // 3. Fuzzy match: same date ± 2 days, same amount, high description similarity
        let candidates = existing.filter { candidate in
            guard let rowDate = row.date else { return false }
            let dayDiff = abs(calendar.dateComponents([.day], from: rowDate, to: candidate.date).day ?? Int.max)
            let amountMatch = row.amount.map { $0 == candidate.amount } ?? false
            return dayDiff <= 2 && amountMatch
        }

        if let bestMatch = candidates.max(by: {
            $0.descriptionText.similarity(to: row.descriptionText) <
            $1.descriptionText.similarity(to: row.descriptionText)
        }), bestMatch.descriptionText.similarity(to: row.descriptionText) >= fuzzyThreshold {
            return DuplicateResult(
                row: row, status: .potential,
                matchingId: bestMatch.id,
                matchingDesc: bestMatch.descriptionText,
                matchingDate: bestMatch.date,
                matchingAmount: bestMatch.amount
            )
        }

        return DuplicateResult(row: row, status: .new)
    }

    private let calendar = Calendar.current
}

// MARK: - ExistingTransaction (lightweight DTO for classification)

/// Lightweight snapshot of an existing transaction — avoids passing SwiftData
/// `@Model` objects across concurrency boundaries.
struct ExistingTransaction: Sendable {
    let id: UUID
    let date: Date
    let amount: Decimal
    let descriptionText: String
    let importHash: String?
    let externalId: String?
}
