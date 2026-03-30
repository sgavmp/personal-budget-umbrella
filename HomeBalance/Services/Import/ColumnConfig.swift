import Foundation

// MARK: - Column Role

/// The transaction field a CSV column maps to.
enum ColumnRole: String, CaseIterable, Codable, Sendable {
    case date           = "date"
    case valueDate      = "valueDate"
    case amount         = "amount"
    case debit          = "debit"
    case credit         = "credit"
    case description    = "description"
    case externalId     = "externalId"
    case notes          = "notes"
    case ignore         = "ignore"

    var displayName: String {
        switch self {
        case .date:          return "Date"
        case .valueDate:     return "Value Date"
        case .amount:        return "Amount"
        case .debit:         return "Debit"
        case .credit:        return "Credit"
        case .description:   return "Description"
        case .externalId:    return "External ID"
        case .notes:         return "Notes"
        case .ignore:        return "Ignore"
        }
    }
}

// MARK: - Column Assignment

struct ColumnAssignment: Codable, Sendable, Identifiable {
    var id: Int { columnIndex }
    let columnIndex: Int
    var role: ColumnRole
}

// MARK: - Column Config

struct ColumnConfig: Codable, Sendable {
    var assignments: [ColumnAssignment]

    /// Returns the index of the first column with the given role, if any.
    func index(for role: ColumnRole) -> Int? {
        assignments.first(where: { $0.role == role })?.columnIndex
    }

    /// Default identity mapping for `columnCount` columns.
    static func identity(columnCount: Int) -> ColumnConfig {
        let assignments = (0..<columnCount).map { ColumnAssignment(columnIndex: $0, role: .ignore) }
        return ColumnConfig(assignments: assignments)
    }
}

// MARK: - Imported Row

/// A transient value type (never stored in SwiftData) representing one staged row
/// before the user confirms the import.
struct ImportedRow: Sendable, Identifiable {
    let id: Int                  // = rowIndex
    let rowIndex: Int
    let date: Date?
    let valueDate: Date?
    let amount: Decimal?
    let descriptionText: String
    let externalId: String?
    let notes: String?
    let rawColumns: [String]

    /// SHA-256 composite dedup key: normalised(date + amount + description).
    var importHash: String? {
        guard let date, let amount else { return nil }
        let key = "\(date.timeIntervalSince1970)|\(amount)|\(descriptionText.normalised)"
        return key.sha256
    }
}
