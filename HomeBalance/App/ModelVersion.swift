import SwiftData

/// Centralises the list of @Model types so ModelContainer and tests
/// always refer to the same schema.
enum ModelVersion {
    case v1

    var models: [any PersistentModel.Type] {
        switch self {
        case .v1:
            return [
                Household.self,
                Member.self,
                BankAccount.self,
                Transaction.self,
                Category.self,
                Subcategory.self,
                CategoryRule.self,
                Budget.self,
                ImportBatch.self,
                ImportMapping.self,
            ]
        }
    }
}
