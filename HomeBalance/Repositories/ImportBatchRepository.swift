import Foundation
import SwiftData

// MARK: - Protocol

protocol ImportBatchRepositoryProtocol: Sendable {
    func fetchAll(for household: Household, context: ModelContext) throws -> [ImportBatch]
    func fetchMappings(for household: Household, context: ModelContext) throws -> [ImportMapping]
    func mapping(named bankName: String, household: Household, context: ModelContext) throws -> ImportMapping?
    func save(_ batch: ImportBatch, in context: ModelContext) throws
    func save(_ mapping: ImportMapping, in context: ModelContext) throws
    func delete(_ batch: ImportBatch, in context: ModelContext) throws
    func delete(_ mapping: ImportMapping, in context: ModelContext) throws
}

// MARK: - Implementation

struct ImportBatchRepository: ImportBatchRepositoryProtocol {

    func fetchAll(for household: Household, context: ModelContext) throws -> [ImportBatch] {
        let householdId = household.id
        let descriptor = FetchDescriptor<ImportBatch>(
            predicate: #Predicate { $0.account?.household?.id == householdId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchMappings(for household: Household, context: ModelContext) throws -> [ImportMapping] {
        let householdId = household.id
        let descriptor = FetchDescriptor<ImportMapping>(
            predicate: #Predicate { $0.household?.id == householdId },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func mapping(named bankName: String, household: Household, context: ModelContext) throws -> ImportMapping? {
        let householdId = household.id
        let lowerName = bankName.lowercased()
        let descriptor = FetchDescriptor<ImportMapping>(
            predicate: #Predicate { mapping in
                mapping.household?.id == householdId
            }
        )
        let all = try context.fetch(descriptor)
        return all.first { $0.bankName.lowercased() == lowerName }
    }

    func save(_ batch: ImportBatch, in context: ModelContext) throws {
        if batch.modelContext == nil { context.insert(batch) }
        try context.save()
    }

    func save(_ mapping: ImportMapping, in context: ModelContext) throws {
        if mapping.modelContext == nil { context.insert(mapping) }
        try context.save()
    }

    func delete(_ batch: ImportBatch, in context: ModelContext) throws {
        context.delete(batch)
        try context.save()
    }

    func delete(_ mapping: ImportMapping, in context: ModelContext) throws {
        context.delete(mapping)
        try context.save()
    }
}
