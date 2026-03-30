import SwiftUI
import SwiftData

/// Root view. Routes to OnboardingView or MainView based on whether a Household exists.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var households: [Household]

    var body: some View {
        Group {
            if households.isEmpty {
                OnboardingView()
            } else {
                MainView(household: households[0])
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var householdName = ""
    @State private var selectedCurrency = "EUR"
    @State private var errorMessage: String?

    private let currencies = ["EUR", "USD", "GBP", "CHF", "MXN", "ARS", "COP", "CLP"]

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                Text("HomeBalance")
                    .font(.largeTitle.bold())
                Text("household_economy_management")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("household_name", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("my_family_placeholder", text: $householdName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("main_currency", systemImage: "eurosign.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button {
                createHousehold()
            } label: {
                Label("create_household", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(householdName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 440)
    }

    private func createHousehold() {
        let name = householdName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let household = Household(name: name, currency: selectedCurrency)
        modelContext.insert(household)
        do {
            try DefaultCategorySeeder.seed(into: household, context: modelContext)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Main Navigation

struct MainView: View {
    let household: Household
    @State private var sidebarSelection: SidebarView.SidebarItem? = .dashboard

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            SidebarView(household: household, selection: $sidebarSelection)
        } detail: {
            MainView.detailView(for: sidebarSelection, household: household)
        }
        #else
        TabView {
            NavigationStack {
                DashboardView(household: household)
            }
            .tabItem { Label("dashboard", systemImage: "house.fill") }

            NavigationStack {
                TransactionListView(household: household)
            }
            .tabItem { Label("transactions", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                Text("budget_placeholder")
                    .navigationTitle("budget")
            }
            .tabItem { Label("budget", systemImage: "chart.bar.fill") }

            NavigationStack {
                MoreView(household: household)
            }
            .tabItem { Label("more", systemImage: "ellipsis.circle") }
        }
        #endif
    }
}

// MARK: - macOS Sidebar

struct SidebarView: View {
    let household: Household
    @Binding var selection: SidebarItem?

    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard    = "dashboard"
        case transactions = "transactions"
        case budget       = "budget"
        case charts       = "charts"
        case importData   = "import"
        case rules        = "rules"
        case settings     = "settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard:    "house.fill"
            case .transactions: "list.bullet.rectangle"
            case .budget:       "chart.bar.fill"
            case .charts:       "chart.line.uptrend.xyaxis"
            case .importData:   "arrow.down.doc.fill"
            case .rules:        "tag.fill"
            case .settings:     "gearshape.fill"
            }
        }

        var localizedLabel: LocalizedStringKey { LocalizedStringKey(rawValue) }
    }

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.localizedLabel, systemImage: item.icon)
                .tag(item)
        }
        .navigationTitle(household.name)
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }
}

// MARK: - macOS Detail router

extension MainView {
    @ViewBuilder
    static func detailView(for item: SidebarView.SidebarItem?, household: Household) -> some View {
        switch item {
        case .dashboard, .none:
            DashboardView(household: household)
        case .transactions:
            TransactionListView(household: household)
        case .budget:
            Text("budget_coming_soon").foregroundStyle(.secondary)
        case .charts:
            Text("charts_coming_soon").foregroundStyle(.secondary)
        case .importData:
            ImportWizardContainerView(household: household)
        case .rules:
            CategorizationRulesView(household: household)
        case .settings:
            Text("settings_coming_soon").foregroundStyle(.secondary)
        }
    }
}

// MARK: - Import Wizard Container (macOS detail panel wrapper)

/// On macOS the import wizard is shown as an inline detail; on iOS it's a sheet.
struct ImportWizardContainerView: View {
    let household: Household
    @State private var showingWizard = false

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer()
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.hbPrimary)
            Text("Import Transactions")
                .font(.hbHeadlineLarge)
            Text("Import CSV or Excel bank statements and let HomeBalance categorise them automatically.")
                .font(.hbLabelLarge)
                .foregroundStyle(Color.hbOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HBSpacing.xl)
            Button {
                showingWizard = true
            } label: {
                Text("Start Import Wizard")
                    .font(.hbLabelLarge.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HBSpacing.xl)
                    .padding(.vertical, HBSpacing.md)
                    .background(LinearGradient.hbPrimaryGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.hbSurface)
        .sheet(isPresented: $showingWizard) {
            ImportWizardView(household: household)
        }
    }
}

// MARK: - More View (iOS "More" tab)

struct MoreView: View {
    let household: Household
    @State private var showingImport = false

    var body: some View {
        List {
            Section("Tools") {
                Button {
                    showingImport = true
                } label: {
                    Label("Import Transactions", systemImage: "arrow.down.doc.fill")
                        .foregroundStyle(Color.hbOnSurface)
                }

                NavigationLink {
                    CategorizationRulesView(household: household)
                } label: {
                    Label("Categorization Rules", systemImage: "tag.fill")
                }
            }

            Section("Household") {
                NavigationLink {
                    Text("Settings coming soon")
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .navigationTitle("More")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.hbSurface)
        .sheet(isPresented: $showingImport) {
            ImportWizardView(household: household)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ModelVersion.v1.models, inMemory: true)
}
