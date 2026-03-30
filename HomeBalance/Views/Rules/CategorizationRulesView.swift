import SwiftUI
import SwiftData

// MARK: - Categorization Rules View

struct CategorizationRulesView: View {

    let household: Household

    @Environment(\.modelContext) private var context
    @State private var vm = CategorizationRulesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hbSurface.ignoresSafeArea()

                if vm.rules.isEmpty && !vm.isLoading {
                    EmptyStateView(
                        icon: "tag.slash",
                        title: "No Rules Yet",
                        subtitle: "Create rules to automatically categorise your imported transactions.",
                        actionTitle: "Create First Rule"
                    ) {
                        vm.startNewRule(household: household)
                    }
                } else {
                    rulesList
                }
            }
            .navigationTitle("Categorization Rules")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.startNewRule(household: household)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.hbPrimary)
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search by merchant or category…")
            .sheet(isPresented: $vm.showingEditor) {
                if let rule = vm.editingRule {
                    EditRuleView(
                        rule: rule,
                        household: household,
                        onSave: { saved in
                            vm.saveRule(saved, household: household, context: context)
                        },
                        onCancel: {
                            vm.showingEditor = false
                            vm.editingRule = nil
                        }
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if let err = vm.errorMessage {
                    Text(err)
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbError)
                        .padding(HBSpacing.md)
                        .background(Color.hbErrorContainer)
                        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
                        .padding()
                }
            }
        }
        .onAppear { vm.load(for: household, context: context) }
    }

    // MARK: - Rules List

    private var rulesList: some View {
        List {
            // Smart Learning Insight Banner
            Section {
                SmartInsightBanner(
                    ruleCount: vm.enabledCount,
                    onReview: {}
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Active rules grouped by category
            Section {
                ForEach(vm.filteredRules) { rule in
                    RuleRow(rule: rule, onToggle: {
                        vm.toggle(rule, context: context)
                    })
                    .contentShape(Rectangle())
                    .onTapGesture { vm.startEditing(rule) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            vm.delete(rule, household: household, context: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            vm.startEditing(rule)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color.hbPrimary)
                    }
                }
                .onDelete { offsets in
                    vm.delete(at: offsets, household: household, context: context)
                }
            } header: {
                HStack {
                    Text("ACTIVE RULES")
                        .font(.hbLabelSmall)
                        .tracking(1)
                    Text("Rules are applied in order of priority.")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                    Spacer()
                    Button("Edit Order") {}
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbPrimary)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.hbSurface)
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: CategoryRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hbPrimaryContainer)
                    .frame(width: 40, height: 40)
                Image(systemName: rule.category?.icon ?? "tag.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.hbPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.pattern.isEmpty ? "(empty)" : rule.pattern.uppercased())
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                    .lineLimit(1)
                HStack(spacing: HBSpacing.xs) {
                    if let cat = rule.category {
                        Text(cat.name)
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbOnSurfaceVariant)
                        if let sub = rule.subcategory {
                            Text("›")
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                            Text(sub.name)
                                .font(.hbLabelSmall)
                                .foregroundStyle(Color.hbOnSurfaceVariant)
                        }
                    } else {
                        Text("No category assigned")
                            .font(.hbLabelSmall)
                            .foregroundStyle(Color.hbError)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Priority badge
            Text("#\(rule.priority)")
                .font(.hbLabelSmall.weight(.semibold))
                .foregroundStyle(Color.hbOnSurfaceVariant)

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(Color.hbSecondary)
        }
        .padding(.vertical, HBSpacing.xs)
    }
}

// MARK: - Smart Insight Banner

private struct SmartInsightBanner: View {
    let ruleCount: Int
    let onReview: () -> Void

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.hbPrimaryContainer)
                    .frame(width: 44, height: 44)
                Image(systemName: "brain.fill")
                    .foregroundStyle(Color.hbPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Learning Active")
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(Color.hbOnSurface)
                Text("We found \(ruleCount) recurring transactions that can be automated with high accuracy.")
                    .font(.hbLabelSmall)
                    .foregroundStyle(Color.hbOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: HBSpacing.sm) {
                    ProgressView(value: Double(min(ruleCount, 100)) / 100.0)
                        .tint(Color.hbSecondary)
                        .frame(width: 60)
                    Text("94% accuracy · \(ruleCount) applied")
                        .font(.hbLabelSmall)
                        .foregroundStyle(Color.hbOnSurfaceVariant)
                }
            }
            Spacer()
            Button("Review", action: onReview)
                .font(.hbLabelLarge.weight(.medium))
                .foregroundStyle(Color.hbPrimary)
        }
        .padding(HBSpacing.md)
        .background(Color.hbPrimaryContainer.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
        .padding(.horizontal, HBSpacing.md)
        .padding(.vertical, HBSpacing.sm)
    }
}
