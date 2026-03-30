import SwiftUI
import SwiftData

// MARK: - Edit Rule View

struct EditRuleView: View {

    @State private var rule: CategoryRule
    let household: Household
    let onSave: (CategoryRule) -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var allCategories: [Category]

    // Local form state (we don't bind directly to the @Model to allow cancellation)
    @State private var field: CategoryRule.Field = .description
    @State private var matchType: CategoryRule.MatchType = .contains
    @State private var pattern: String = ""
    @State private var isNegative: Bool = false
    @State private var priority: Int = 100
    @State private var isEnabled: Bool = true
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?

    // Impact calculation
    @State private var impactCount: Int = 0

    init(rule: CategoryRule, household: Household, onSave: @escaping (CategoryRule) -> Void, onCancel: @escaping () -> Void) {
        _rule = State(initialValue: rule)
        self.household = household
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var isNew: Bool { rule.pattern.isEmpty && rule.modelContext == nil }
    var isValid: Bool { !pattern.isEmpty && selectedCategory != nil }

    private var targetCategorySection: some View {
        let householdId = household.id
        let householdCats = allCategories.filter { $0.household?.id == householdId }
        return VStack(alignment: .leading, spacing: HBSpacing.xs) {
            Text("TARGET CATEGORY")
                .sectionLabel()
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                selectedSubcategory: $selectedSubcategory,
                categories: householdCats
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HBSpacing.lg) {

                    // Header
                    VStack(alignment: .leading, spacing: HBSpacing.xs) {
                        Text("PHASE 3B SYSTEM")
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbPrimary)
                            .tracking(1.5)
                        Text("Categorization\nLogic")
                            .font(.hbHeadlineLarge)
                            .foregroundStyle(Color.hbOnSurface)
                    }

                    // Match Field + Match Type
                    HStack(spacing: HBSpacing.md) {
                        VStack(alignment: .leading, spacing: HBSpacing.xs) {
                            Text("MATCH FIELD")
                                .sectionLabel()
                            Picker("", selection: $field) {
                                ForEach(CategoryRule.Field.allCases, id: \.self) { f in
                                    Text(f.rawValue.capitalized).tag(f)
                                }
                            }
                            .menuPicker()
                        }
                        VStack(alignment: .leading, spacing: HBSpacing.xs) {
                            Text("MATCH TYPE")
                                .sectionLabel()
                            Picker("", selection: $matchType) {
                                ForEach(CategoryRule.MatchType.allCases, id: \.self) { t in
                                    Text(t.rawValue.capitalized).tag(t)
                                }
                            }
                            .menuPicker()
                        }
                    }

                    // Pattern
                    VStack(alignment: .leading, spacing: HBSpacing.xs) {
                        Text("SEARCH PATTERN")
                            .sectionLabel()
                        TextField("e.g. Starbucks, NETFLIX, gym…", text: $pattern)
                            .padding(HBSpacing.md)
                            .background(Color.hbSurfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
                            .autocorrectionDisabled()
                    }

                    // Target Category
                    targetCategorySection

                    // Priority
                    VStack(alignment: .leading, spacing: HBSpacing.xs) {
                        Text("PRIORITY")
                            .sectionLabel()
                        HStack {
                            Button { priority = max(1, priority - 10) }
                                label: { Image(systemName: "minus.circle").font(.title2) }
                                .foregroundStyle(Color.hbPrimary)
                            Spacer()
                            Text("\(priority)")
                                .font(.hbHeadlineMedium)
                                .foregroundStyle(Color.hbOnSurface)
                                .frame(minWidth: 60, alignment: .center)
                            Spacer()
                            Button { priority = min(999, priority + 10) }
                                label: { Image(systemName: "plus.circle").font(.title2) }
                                .foregroundStyle(Color.hbPrimary)
                        }
                        .padding(HBSpacing.md)
                        .background(Color.hbSurfaceLow)
                        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
                    }

                    // Negative rule toggle
                    Toggle(isOn: $isNegative) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exclusion Rule")
                                .font(.hbLabelLarge.weight(.medium))
                            Text("If this pattern matches, skip all category assignments for this transaction.")
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                        }
                    }
                    .tint(Color.hbError)
                    .padding(HBSpacing.md)
                    .background(Color.hbSurfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))

                    // Rule Impact card
                    RuleImpactCard(impactCount: impactCount, pattern: pattern)

                    // Delete button (edit mode only)
                    if !isNew {
                        Button(role: .destructive) {
                            onCancel()
                        } label: {
                            Label("Delete this rule", systemImage: "trash")
                                .font(.hbLabelLarge)
                                .foregroundStyle(Color.hbError)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(HBSpacing.lg)
            }
            .background(Color.hbSurface.ignoresSafeArea())
            .navigationTitle(isNew ? "New Rule" : "Edit Rule")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commitSave() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populateForm() }
        }
    }

    // MARK: - Actions

    private func populateForm() {
        field = CategoryRule.Field(rawValue: rule.field) ?? .description
        matchType = CategoryRule.MatchType(rawValue: rule.matchType) ?? .contains
        pattern = rule.pattern
        isNegative = rule.isNegative
        priority = rule.priority
        isEnabled = rule.isEnabled
        selectedCategory = rule.category
        selectedSubcategory = rule.subcategory
    }

    private func commitSave() {
        rule.field = field.rawValue
        rule.matchType = matchType.rawValue
        rule.pattern = pattern
        rule.isNegative = isNegative
        rule.priority = priority
        rule.isEnabled = isEnabled
        rule.category = selectedCategory
        rule.subcategory = selectedSubcategory
        onSave(rule)
    }
}

// MARK: - Rule Impact Card

private struct RuleImpactCard: View {
    let impactCount: Int
    let pattern: String

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HStack {
                Text("Rule Impact")
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                Spacer()
                Text("LIVE TEST")
                    .font(.hbLabelSmall.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HBSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.hbSecondary)
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: HBSpacing.xs) {
                Text("\(impactCount)")
                    .font(.hbDisplayMedium)
                    .foregroundStyle(Color.hbOnSurface)
                Text("Matched transactions\nin the last 12 months")
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ProgressView(value: Double(min(impactCount, 200)) / 200.0)
                .tint(Color.hbSecondary)

            if !pattern.isEmpty {
                Button {
                    // navigate to filtered transactions
                } label: {
                    Text("View Matched Transactions")
                        .font(.hbLabelLarge.weight(.medium))
                        .foregroundStyle(Color.hbPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HBSpacing.sm)
                        .background(Color.hbPrimaryContainer)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
    }
}

// MARK: - Style Helpers

private extension Text {
    func sectionLabel() -> some View {
        self
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.hbOnSurfaceVariant)
            .tracking(1)
    }
}

private extension View {
    func menuPicker() -> some View {
        self
            .pickerStyle(.menu)
            .tint(Color.hbPrimary)
            .padding(HBSpacing.md)
            .background(Color.hbSurfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
            .frame(maxWidth: .infinity)
    }
}
