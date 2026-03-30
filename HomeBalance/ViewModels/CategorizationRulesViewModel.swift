import Foundation
import SwiftData

@MainActor
@Observable
final class CategorizationRulesViewModel {

    // MARK: - State

    var rules: [CategoryRule] = []
    var searchText: String = ""
    var isLoading = false
    var errorMessage: String?
    var showingEditor = false
    var editingRule: CategoryRule?

    // MARK: - Computed

    var filteredRules: [CategoryRule] {
        if searchText.isEmpty { return rules }
        let q = searchText.lowercased()
        return rules.filter {
            $0.pattern.lowercased().contains(q)
            || $0.category?.name.lowercased().contains(q) == true
        }
    }

    var enabledCount: Int { rules.filter(\.isEnabled).count }

    // MARK: - Dependencies

    private let repo = CategoryRuleRepository()

    // MARK: - Load

    func load(for household: Household, context: ModelContext) {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            rules = try repo.fetchAll(for: household, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toggle

    func toggle(_ rule: CategoryRule, context: ModelContext) {
        rule.isEnabled.toggle()
        do { try repo.save(rule, in: context) }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Delete

    func delete(_ rule: CategoryRule, household: Household, context: ModelContext) {
        do {
            try repo.delete(rule, in: context)
            load(for: household, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet, household: Household, context: ModelContext) {
        let toDelete = offsets.map { filteredRules[$0] }
        toDelete.forEach { rule in
            do { try repo.delete(rule, in: context) }
            catch { errorMessage = error.localizedDescription }
        }
        load(for: household, context: context)
    }

    // MARK: - New / Edit

    func startNewRule(household: Household) {
        let rule = CategoryRule(pattern: "")
        rule.household = household
        editingRule = rule
        showingEditor = true
    }

    func startEditing(_ rule: CategoryRule) {
        editingRule = rule
        showingEditor = true
    }

    func saveRule(_ rule: CategoryRule, household: Household, context: ModelContext) {
        rule.household = household
        do {
            try repo.save(rule, in: context)
            load(for: household, context: context)
            showingEditor = false
            editingRule = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
