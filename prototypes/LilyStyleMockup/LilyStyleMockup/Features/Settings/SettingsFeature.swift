import SwiftUI

// MARK: - UI state

/// Settings, Privacy & Data, Styling Access, Help and Demo Controls state, owned by
/// `AppModel` (`app.settingsUI`).
///
/// Open review sheets, the choices made inside them, expanded help topics and the
/// layout lab setup live here (not in `@State`), so rotation, window resizing and the
/// move between the compact sheet and the iPad sidebar keep them. Nothing in here
/// calls a service.
@Observable
final class SettingsUIState {
    // Settings sheets
    var settingsSheet: SettingsSheet?
    var exportResultVisible = false
    var lastExportSimulation: Date?
    var importArchive: SettingsSampleArchive = .valid
    var importMode: SettingsImportMode = .merge
    var importSimulated = false
    var lastConflictResolution: String?

    // Privacy & data
    var privacySheet: SettingsPrivacySheet?
    var deleteScope: SettingsDeleteScope = .closet
    var deleteSheetShowsResult = false
    var deletionResult: SettingsDeletionResult?

    // Styling access
    var accessSheet: SettingsStoreKitAction?
    var storeKitResult: String?

    // Help
    var expandedHelpTopics: Set<Int> = []

    // Disclosures
    /// Open details rows and expanded chip rows, by key, so they stay open through a
    /// rotation and the move between the compact sheet and the iPad sidebar.
    var openDetails: Set<String> = []

    // Demo controls / layout lab
    var layoutLabPresented = false
    var layoutLabWidth: CGFloat = 375
    var layoutLabSection: AppSection = .styleMe
    var layoutLabScaleToFit = true
    /// Style Me's inline-results flag captured before the lab opens, restored when it closes.
    var layoutLabSavedResultsInline: Bool?

    init() {}

    func detailsBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDetails.contains(key) },
            set: { open in
                if open {
                    self.openDetails.insert(key)
                } else {
                    self.openDetails.remove(key)
                }
            }
        )
    }

    func openExport() {
        exportResultVisible = false
        settingsSheet = .export
    }

    func openImport() {
        importSimulated = false
        settingsSheet = .importBackup
    }

    func openDeleteMyData() {
        deleteSheetShowsResult = false
        privacySheet = .deleteMyData
    }

    func openStoreKit(_ action: SettingsStoreKitAction) {
        storeKitResult = nil
        accessSheet = action
    }

    func openLayoutLab(width: CGFloat, resultsShownInline: Bool) {
        layoutLabWidth = width
        if !layoutLabPresented { layoutLabSavedResultsInline = resultsShownInline }
        layoutLabPresented = true
    }
}

/// Review sheets presented from the Settings screen.
enum SettingsSheet: String, Identifiable {
    case export, importBackup, terms, privacyPolicy
    var id: String { rawValue }
}

/// Review sheets presented from Privacy & Data.
enum SettingsPrivacySheet: String, Identifiable {
    case deleteMyData
    var id: String { rawValue }
}

// MARK: - Settings screen

/// Settings & Privacy: default wardrobe view, styling access, processing permissions,
/// simulated iCloud sync and backup review, privacy and deletion, analytics, help,
/// legal placeholders and Demo Controls.
///
/// Every control here is a local store/navigation change. Export, import, sync and
/// billing are simulations with their own clearly labelled review states.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var ui = app.settingsUI
        GeometryReader { geo in
            let twoColumns = WidthClass(width: geo.size.width) == .wide && !dynamicTypeSize.isAccessibilitySize
            if twoColumns {
                HStack(alignment: .top, spacing: 0) {
                    SettingsList(horizontalMargin: 0) {
                        SettingsDefaultViewSection()
                        SettingsPermissionsSection()
                        SettingsSyncSection()
                        SettingsBackupSection()
                        SettingsPrivacyLinkSection()
                    }
                    Rectangle()
                        .fill(Palette.divider)
                        .frame(width: 1)
                        .accessibilityHidden(true)
                    SettingsList(horizontalMargin: 0) {
                        SettingsAccessSection()
                        SettingsAnalyticsSection()
                        SettingsHelpSupportSection()
                        SettingsConnectionsSection()
                        SettingsDevelopmentSection()
                        SettingsAboutSection()
                    }
                }
            } else {
                SettingsList(horizontalMargin: SettingsLayout.readableMargin(for: geo.size.width)) {
                    SettingsDefaultViewSection()
                    SettingsAccessSection()
                    SettingsPermissionsSection()
                    SettingsSyncSection()
                    SettingsBackupSection()
                    SettingsPrivacyLinkSection()
                    SettingsAnalyticsSection()
                    SettingsHelpSupportSection()
                    SettingsConnectionsSection()
                    SettingsDevelopmentSection()
                    SettingsAboutSection()
                }
            }
        }
        .themedScreenBackground()
        .navigationTitle("Settings")
        .settingsLabAwareSheet(item: $ui.settingsSheet) { sheet in
            SettingsSheetHost(sheet: sheet)
        }
    }
}

/// Themed inset-grouped list used by the Settings screens.
struct SettingsList<Content: View>: View {
    var horizontalMargin: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .contentMargins(.horizontal, horizontalMargin > 0 ? horizontalMargin : nil, for: .scrollContent)
    }
}

enum SettingsLayout {
    /// Extra side margin that keeps a single list column at a readable width.
    static func readableMargin(for width: CGFloat, maxContent: CGFloat = 760) -> CGFloat {
        max(0, (width - maxContent) / 2)
    }
}

/// Routes the Settings screen's review sheets.
private struct SettingsSheetHost: View {
    var sheet: SettingsSheet

    var body: some View {
        switch sheet {
        case .export:
            NavigationStack { SettingsExportReview() }
        case .importBackup:
            NavigationStack { SettingsImportReview() }
        case .terms:
            SettingsLegalPlaceholder(document: .terms)
        case .privacyPolicy:
            SettingsLegalPlaceholder(document: .privacy)
        }
    }
}

// MARK: - Previews

#Preview("Settings · compact") {
    NavigationStack {
        SettingsScreen()
            .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
    }
    .previewEnvironment()
}

#Preview("Settings · wide", traits: .fixedLayout(width: 1100, height: 900)) {
    NavigationStack {
        SettingsScreen()
    }
    .previewEnvironment()
}

#Preview("Settings · sync conflict") {
    let model = AppModel.preview
    model.scenario = .syncConflict
    return NavigationStack {
        SettingsScreen()
    }
    .previewEnvironment(model)
}
