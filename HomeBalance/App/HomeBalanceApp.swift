import SwiftUI
import SwiftData

@main
struct HomeBalanceApp: App {

    let modelContainer: ModelContainer = {
        let schema = Schema(ModelVersion.v1.models)

        // Try CloudKit first (production / signed build)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .private("iCloud.com.homebalance.app")
                )
            ]
        ) {
            return container
        }

        // Fallback: local SQLite store (simulator, test host, no entitlements)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema)]
        ) {
            return container
        }

        // Last resort: in-memory (tests that use TEST_HOST)
        guard let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) else {
            fatalError("Could not create any ModelContainer variant")
        }
        return container
    }()

    var body: some Scene {
        #if os(macOS)
        Window("HomeBalance", id: "main") {
            ContentView()
                .modelContainer(modelContainer)
        }
        .commands {
            AppCommands()
        }
        #else
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
        #endif
    }
}
