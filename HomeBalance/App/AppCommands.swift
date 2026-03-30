import SwiftUI

/// macOS menu bar commands.
struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
    }
}
