import SwiftUI
import SwiftData

/// Root view. Checks whether a Household exists and routes accordingly:
/// - No household → OnboardingView (create first household)
/// - Household present → MainView (full app navigation)
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

// MARK: - Onboarding (Placeholder — Fase 8)

struct OnboardingView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var householdName = ""
    @State private var selectedCurrency = "EUR"

    private let currencies = ["EUR", "USD", "GBP", "CHF", "MXN", "ARS", "COP", "CLP"]

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                Text("HomeBalance")
                    .font(.largeTitle.bold())
                Text("Gestión económica del hogar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Nombre del hogar", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Mi Familia", text: $householdName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("Moneda principal", systemImage: "eurosign.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Moneda", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal)

            Button {
                createHousehold()
            } label: {
                Label("Crear hogar", systemImage: "checkmark")
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
            // TODO: Surface error to user — Phase 8 polish
            print("Error creating household: \(error)")
        }
    }
}

// MARK: - Main Navigation (Placeholder — expandido en Fase 2)

struct MainView: View {

    let household: Household

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            SidebarView(household: household)
        } detail: {
            DashboardPlaceholderView(household: household)
        }
        #else
        TabView {
            NavigationStack {
                DashboardPlaceholderView(household: household)
            }
            .tabItem { Label("Inicio", systemImage: "house.fill") }

            NavigationStack {
                Text("Transacciones")
                    .navigationTitle("Transacciones")
            }
            .tabItem { Label("Transacciones", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                Text("Presupuesto")
                    .navigationTitle("Presupuesto")
            }
            .tabItem { Label("Presupuesto", systemImage: "chart.bar.fill") }

            NavigationStack {
                Text("Más")
                    .navigationTitle("Más")
            }
            .tabItem { Label("Más", systemImage: "ellipsis.circle") }
        }
        #endif
    }
}

// MARK: - macOS Sidebar (Placeholder — Fase 2)

struct SidebarView: View {

    let household: Household
    @State private var selection: SidebarItem? = .dashboard

    enum SidebarItem: String, CaseIterable {
        case dashboard = "Inicio"
        case transactions = "Transacciones"
        case budget = "Presupuesto"
        case charts = "Gráficas"
        case importData = "Importar"
        case settings = "Ajustes"

        var icon: String {
            switch self {
            case .dashboard:     "house.fill"
            case .transactions:  "list.bullet.rectangle"
            case .budget:        "chart.bar.fill"
            case .charts:        "chart.line.uptrend.xyaxis"
            case .importData:    "arrow.down.doc.fill"
            case .settings:      "gearshape.fill"
            }
        }
    }

    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
        }
        .navigationTitle(household.name)
        .listStyle(.sidebar)
    }
}

// MARK: - Dashboard Placeholder (reemplazado en Fase 2)

struct DashboardPlaceholderView: View {

    let household: Household

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status card
                GroupBox {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Hogar creado correctamente")
                            .font(.headline)
                        Text(household.name)
                            .foregroundStyle(.secondary)
                        Text("Moneda: \(household.currency)")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } label: {
                    Label("HomeBalance", systemImage: "house.fill")
                }

                // Category count card
                GroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(household.categories.count)")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.tint)
                            Text("Categorías cargadas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "tag.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tint.opacity(0.3))
                    }
                    .padding()
                } label: {
                    Label("Categorías", systemImage: "tag.fill")
                }

                Text("Las vistas completas se implementarán en la Fase 2")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .navigationTitle("Inicio")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ModelVersion.v1.models, inMemory: true)
}
