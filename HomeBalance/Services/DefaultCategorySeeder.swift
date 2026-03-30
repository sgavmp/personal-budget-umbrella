import SwiftData
import Foundation

/// Seeds the default category + subcategory tree into a newly created Household.
/// Reads from DefaultCategories.json bundled in Resources.
/// Safe to call multiple times: skips seeding if the household already has categories.
struct DefaultCategorySeeder {

    // MARK: - Private Types

    private struct CategorySeed: Decodable {
        let name: String
        let nameEN: String
        let icon: String
        let color: String
        let type: String
        let sortOrder: Int
        let isSystem: Bool?
        let subcategories: [SubcategorySeed]
    }

    private struct SubcategorySeed: Decodable {
        let name: String
        let nameEN: String
        let sortOrder: Int
    }

    // MARK: - Public Interface

    /// Seeds default categories into `household` using the given `modelContext`.
    /// The locale parameter determines which name to use (Spanish or English).
    static func seed(
        into household: Household,
        context: ModelContext,
        locale: Locale = .current
    ) throws {
        guard household.categories.isEmpty else { return }

        let seeds = try loadSeeds()
        let preferSpanish = locale.language.languageCode?.identifier == "es"

        for seed in seeds {
            let category = Category(
                name: preferSpanish ? seed.name : seed.nameEN,
                icon: seed.icon,
                color: seed.color,
                type: seed.type,
                sortOrder: seed.sortOrder,
                isSystem: seed.isSystem ?? false
            )
            category.household = household
            context.insert(category)

            for subSeed in seed.subcategories {
                let subcategory = Subcategory(
                    name: preferSpanish ? subSeed.name : subSeed.nameEN,
                    sortOrder: subSeed.sortOrder
                )
                subcategory.category = category
                context.insert(subcategory)
            }
        }
    }

    // MARK: - Private Helpers

    private static func loadSeeds() throws -> [CategorySeed] {
        guard let url = Bundle.main.url(
            forResource: "DefaultCategories",
            withExtension: "json"
        ) else {
            throw SeederError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CategorySeed].self, from: data)
    }

    // MARK: - Errors

    enum SeederError: LocalizedError {
        case fileNotFound

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "DefaultCategories.json not found in app bundle."
            }
        }
    }
}
