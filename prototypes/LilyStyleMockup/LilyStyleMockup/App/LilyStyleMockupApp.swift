import SwiftUI

@main
struct LilyStyleMockupApp: App {
    @State private var app: AppModel

    init() {
        let launch = LaunchConfiguration.current
        if launch.resetDemo { StorePersistence.eraseAll() }
        let store = DemoStore.loadOrFixtures()
        if launch.skipOnboarding { store.hasCompletedOnboarding = true }
        let model = AppModel(store: store, fastMocks: launch.fastMocks)
        _app = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .tint(Palette.primaryAction)
                .preferredColorScheme(LaunchConfiguration.current.appearance)
                .task { await LaunchConfiguration.current.apply(to: app) }
        }
        .commands { AppCommands(app: app) }
    }
}

/// Hardware-keyboard commands (iPad). Each maps to an existing touch action.
/// None of them run behind a root sheet. Style Me uses ⇧⌘↩ so the screens' own ⌘↩
/// (Send, Review, Search, Submit) keep it, and Search and Add Item step aside on the
/// Closet, Saved and Feedback screens, which bind ⌘F / ⌘N themselves.
struct AppCommands: Commands {
    let app: AppModel

    var body: some Commands {
        CommandMenu("Styling") {
            Button("Style Me") { app.styleMe() }
                .keyboardShortcut(.return, modifiers: [.command, .shift])
                .disabled(app.sheet != nil || !app.styleBlockers.isEmpty)
            Button("Search") { search() }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(app.sheet != nil || rootShowing(.closet) || rootShowing(.saved))
            Button("Add Item") { app.present(.addGarment(nil)) }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(app.sheet != nil || rootShowing(.closet) || rootShowing(.feedback))
        }
    }

    /// True while a section's root screen is in front, so its own toolbar shortcuts apply.
    private func rootShowing(_ section: AppSection) -> Bool {
        app.section == section && (app.paths[section]?.isEmpty ?? true)
    }

    /// Opens Search, or goes back to it when it's already the top screen (no stacked copies).
    private func search() {
        let target: AppSection = app.section.isCompactTab ? app.section : .closet
        if case .search? = app.topRoute(in: target) {
            app.select(target)
        } else {
            app.push(.search(.everything), in: target)
        }
    }
}
