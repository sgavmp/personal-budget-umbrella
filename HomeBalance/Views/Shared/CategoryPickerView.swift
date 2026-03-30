import SwiftUI
import SwiftData

/// Two-level picker: selects a Category and optionally a Subcategory.
struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    @Binding var selectedSubcategory: Subcategory?
    let categories: [Category]
    var typeFilter: String?  // "expense", "income", nil = all

    private var filteredCategories: [Category] {
        guard let filter = typeFilter else { return categories }
        return categories.filter { $0.type == filter }
    }

    var body: some View {
        Group {
            // Category picker
            Picker("category", selection: $selectedCategory) {
                Text("none").tag(Optional<Category>.none)
                ForEach(filteredCategories) { cat in
                    Label(cat.name, systemImage: cat.icon)
                        .tag(Optional(cat))
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                selectedSubcategory = nil
            }

            // Subcategory picker — only shown when a category is selected
            if let cat = selectedCategory, !cat.subcategories.isEmpty {
                let subs = cat.subcategories.sorted { $0.sortOrder < $1.sortOrder }
                Picker("subcategory", selection: $selectedSubcategory) {
                    Text("none").tag(Optional<Subcategory>.none)
                    ForEach(subs) { sub in
                        Text(sub.name).tag(Optional(sub))
                    }
                }
            }
        }
    }
}
