import SwiftUI

/// Profile + onboarding UI state, owned by `AppModel` (`app.profileUI`).
///
/// Open editors and their drafts live here (not in `@State`) so a rotation or
/// window resize that moves Profile between the compact sheet and the iPad
/// sidebar detail keeps the editor open with the text she already typed.
/// Nothing in here ever dispatches a service.
@Observable
final class ProfileUIState {
    // MARK: Profile editors
    var editor: ProfileEditorSheet?
    var measurementDraft = ProfileMeasurementDraft(dimension: .inseam, fact: nil)
    var weightDraft = ProfileWeightDraft(weight: nil)
    var fitReferenceDraft = ProfileUIState.blankFitReference()
    var fitReferenceIsNew = true
    var textDraft = ""
    var newStyleWord = ""
    var newLikedPair = ""
    var newAvoidedPair = ""
    var newRetailer = ""
    var onMeDeleteScope: ProfileOnMeDeleteScope = .referenceOnly

    // MARK: Disclosures
    /// Open details rows and expanded chip rows, by key, so they stay open through a
    /// rotation and the tab/sidebar switch.
    var openDetails: Set<String> = []

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

    // MARK: Onboarding
    var onboardingStep: ProfileOnboardingStep = .welcome
    var onboardingEditingHeight = false
    var onboardingHeightFeet = 4
    var onboardingHeightInches = 11
    var onboardingAddingInseam = false
    var onboardingInseamText = ""
    var onboardingInseamUnit: MeasurementUnit = .inches
    var onboardingInseamBasis: MeasurementBasis = .body
    var onboardingAddingBody = false
    var onboardingBodyDraft = ProfileBodyTrioDraft()
    var onboardingAddingWeight = false
    var onboardingWeightDraft = ProfileWeightDraft(weight: nil)
    var onboardingSavedNote: String?

    init() {}

    static func blankFitReference() -> FitReference {
        FitReference(brand: "", category: .bottom, sizeLabel: "", result: .fitsWell)
    }

    func openMeasurement(_ dimension: MeasurementDimension, profile: UserProfile) {
        measurementDraft = ProfileMeasurementDraft(dimension: dimension, fact: profile.measurement(dimension))
        editor = .measurement
    }

    func openWeight(profile: UserProfile) {
        weightDraft = ProfileWeightDraft(weight: profile.weight)
        editor = .weight
    }

    func openNewFitReference() {
        fitReferenceDraft = Self.blankFitReference()
        fitReferenceIsNew = true
        editor = .fitReference
    }

    func openFitReference(_ reference: FitReference) {
        fitReferenceDraft = reference
        fitReferenceIsNew = false
        editor = .fitReference
    }

    func openText(_ field: ProfileTextField, profile: UserProfile) {
        textDraft = field.value(in: profile) ?? ""
        editor = .text(field)
    }

    func resetOnboarding() {
        onboardingStep = .welcome
        onboardingEditingHeight = false
        onboardingAddingInseam = false
        onboardingInseamText = ""
        onboardingAddingBody = false
        onboardingBodyDraft = ProfileBodyTrioDraft()
        onboardingAddingWeight = false
        onboardingWeightDraft = ProfileWeightDraft(weight: nil)
        onboardingSavedNote = nil
    }
}

/// Sheets presented from the Profile screen. Drafts live in `ProfileUIState`.
enum ProfileEditorSheet: Identifiable, Hashable {
    case measurement
    case weight
    case fitReference
    case text(ProfileTextField)
    case onMeReplace
    case onMeDelete

    var id: String {
        switch self {
        case .measurement: "measurement"
        case .weight: "weight"
        case .fitReference: "fitReference"
        case let .text(field): "text-\(field.rawValue)"
        case .onMeReplace: "onMeReplace"
        case .onMeDelete: "onMeDelete"
        }
    }
}

// MARK: - Profile screen

/// Optional confirmed measurements, fit references, fit/style/shopping
/// preferences, separate processing permissions and the simulated On Me
/// reference. Every edit is a local `store.updateProfile` / `setPermission`
/// call: no stylist, image or search service is ever called from here.
struct ProfileScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var editMode: EditMode = .inactive

    var body: some View {
        @Bindable var ui = app.profileUI
        GeometryReader { geo in
            let twoColumns = geo.size.width >= 760 && !dynamicTypeSize.isAccessibilitySize
            Group {
                if twoColumns {
                    HStack(alignment: .top, spacing: 0) {
                        column {
                            ProfileIdentitySection()
                            ProfileMeasurementsSection()
                            ProfileFitReferencesSection()
                            ProfileFitPreferencesSection()
                            ProfileOnMeSection()
                        }
                        Rectangle()
                            .fill(Palette.divider)
                            .frame(width: 1)
                            .accessibilityHidden(true)
                        column {
                            ProfileStyleColorSection()
                            ProfileShoppingSection()
                            ProfilePermissionsSection()
                            ProfileAnalyticsSection()
                        }
                    }
                } else {
                    column {
                        ProfileIdentitySection()
                        ProfileMeasurementsSection()
                        ProfileFitReferencesSection()
                        ProfileFitPreferencesSection()
                        ProfileStyleColorSection()
                        ProfileShoppingSection()
                        ProfilePermissionsSection()
                        ProfileOnMeSection()
                        ProfileAnalyticsSection()
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .themedScreenBackground()
        .navigationTitle("Profile")
        .sheet(item: $ui.editor) { sheet in
            ProfileEditorHost(sheet: sheet)
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }

    private func column<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        List {
            content()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background)
    }
}

/// Routes the Profile screen's sheets.
private struct ProfileEditorHost: View {
    var sheet: ProfileEditorSheet

    var body: some View {
        switch sheet {
        case .measurement: ProfileMeasurementEditor()
        case .weight: ProfileWeightEditor()
        case .fitReference: ProfileFitReferenceEditor()
        case let .text(field): ProfileTextEditor(field: field)
        case .onMeReplace: ProfileOnMeReplaceReview()
        case .onMeDelete: ProfileOnMeDeleteReview()
        }
    }
}

// MARK: - Identity header

/// Short orientation: whose profile, where it is saved, and that editing never calls a service.
struct ProfileIdentitySection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                // Stacks at accessibility sizes so the name and badge never truncate.
                let header = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.xs))
                header {
                    Text(app.store.profile.displayName)
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.xs) }
                    StatusBadge(kind: .demo, compact: true)
                }
                CollapsibleText(
                    "Everything here is optional and editable. It is saved on this device, and editing it never calls the stylist or makes new pictures.",
                    summary: "Optional, editable, saved on this device.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "your profile",
                    isExpanded: app.profileUI.detailsBinding("identity")
                )
                Button {
                    app.profileUI.resetOnboarding()
                    app.present(.onboarding)
                } label: {
                    Label("View the welcome again", systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Opens the short welcome. Nothing is reset.")
            }
            .padding(.vertical, Spacing.xs)
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Previews

#Preview("Profile · compact") {
    NavigationStack {
        ProfileScreen()
    }
    .previewEnvironment()
}

#Preview("Profile · wide", traits: .fixedLayout(width: 1100, height: 900)) {
    NavigationStack {
        ProfileScreen()
    }
    .previewEnvironment()
}

#Preview("Onboarding") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            OnboardingView()
                .previewEnvironment()
        }
}
