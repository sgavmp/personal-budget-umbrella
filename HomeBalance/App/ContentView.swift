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
                Text("more_placeholder")
                    .navigationTitle("more")
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
        case settings     = "settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard:    "house.fill"
            case .transactions: "list.bullet.rectangle"
            case .budget:       "chart.bar.fill"
            case .charts:       "chart.line.uptrend.xyaxis"
            case .importData:   "arrow.down.doc.fill"
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
            Text("import_coming_soon").foregroundStyle(.secondary)
        case .settings:
            Text("settings_coming_soon").foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ModelVersion.v1.models, inMemory: true)
}
