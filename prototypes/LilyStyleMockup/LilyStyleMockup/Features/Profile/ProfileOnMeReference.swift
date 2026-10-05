import SwiftUI

/// What an explicit reference deletion covers.
enum ProfileOnMeDeleteScope: String, Hashable {
    case referenceOnly
    case referenceAndPreviews
}

extension AppModel {
    /// Placeholder "fitted athletic wear" pieces for the simulated reference figure.
    static let profileReferencePieces: [OutfitPiece] = [
        OutfitPiece(slot: .top, garmentID: nil, capturedName: "fitted athletic top (placeholder)",
                    capturedColor: GarmentColor(name: "Charcoal", hex: "4A4549", family: .gray),
                    capturedKind: .knitTop, capturedImageKind: .representative),
        OutfitPiece(slot: .bottom, garmentID: nil, capturedName: "fitted athletic leggings (placeholder)",
                    capturedColor: GarmentColor(name: "Charcoal", hex: "3A3539", family: .gray),
                    capturedKind: .trousers, capturedImageKind: .representative),
        OutfitPiece(slot: .shoes, garmentID: nil, capturedName: "sneakers (placeholder)",
                    capturedColor: GarmentColor(name: "Soft white", hex: "ECE8EA", family: .white),
                    capturedKind: .sneakers, capturedImageKind: .representative),
    ]

    /// Retained previews made with a given reference version.
    func profilePreviews(madeWithReference version: Int?) -> [PreviewEntry] {
        guard let version else { return [] }
        return store.previews
            .filter { $0.referenceVersion == version }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// The version a new or replacement reference gets. It is always higher than
    /// the current version and than any version a retained preview was made with,
    /// so a new reference never inherits the lineage or render keys of a deleted one.
    var profileNextReferenceVersion: Int {
        let highestPreview = store.previews.map(\.referenceVersion).max() ?? 0
        return max(store.profile.onMeReference.version ?? 0, highestPreview) + 1
    }

    /// Adds or replaces the simulated reference: a new version for future previews.
    func profileUseDemoReference(message: String) {
        let next = profileNextReferenceVersion
        profileSave(message: message) {
            $0.onMeReference = .simulatedReference(version: next, addedAt: .now)
        }
    }
}

// MARK: - Section

/// Profile → On Me reference (simulated). Separate from the On Me permission.
struct ProfileOnMeSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let reference = app.store.profile.onMeReference
        let permission = app.store.profile.permission(.onMeImages)
        Section {
            if case let .simulatedReference(version, addedAt) = reference {
                referenceView(version: version, addedAt: addedAt)
            } else {
                emptyView
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("On Me picture permission")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: Spacing.xs)
                ProfileToneBadge(text: permission.label, systemImage: permission.profileSystemImage, tone: permission.profileTone)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Managed separately under Processing permissions")
        } header: {
            ProfileListHeader(
                "On Me reference",
                subtitle: "Optional and simulated.",
                info: "The reference and the On Me permission are separate choices. Without them, outfit boards work exactly the same.",
                systemImage: "person.crop.rectangle"
            )
        }
        .listRowBackground(Palette.surface)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("No reference")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
            Text("Outfit boards work without it.")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            DetailsDisclosure(
                "About the reference",
                count: app.store.previews.isEmpty ? 2 : 3,
                isExpanded: app.profileUI.detailsBinding("onMeAbout"),
                identifier: "onMeReferenceAbout"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ProfileBullet(systemImage: "figure.stand", text: "In the real app: a clear, full-body photo, standing naturally in fitted athletic wear, in good light.")
                    ProfileBullet(systemImage: "ruler", text: "It's only for approximate pictures. Measurements are never inferred from it, and it isn't a fit check.")
                    if !app.store.previews.isEmpty {
                        ProfileBullet(systemImage: "clock.arrow.circlepath", text: "Previews you kept from an earlier reference stay labeled with their own version. A new reference starts at v\(app.profileNextReferenceVersion).")
                    }
                }
            }
            SimulationNotice(text: "This prototype never uses a real photo. The demo reference is a placeholder figure.", summary: "Placeholder figure, no real photo.")
            Button {
                app.profileUseDemoReference(message: "Demo placeholder reference added. Saved on this device")
            } label: {
                Label("Use demo placeholder reference", systemImage: "person.crop.rectangle.badge.plus")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityIdentifier("onMeReferenceAdd")
        }
        .padding(.vertical, Spacing.xs)
    }

    private func referenceView(version: Int, addedAt: Date) -> some View {
        let madeWith = app.profilePreviews(madeWithReference: version).count
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.m) {
                figure(version: version)
                    .frame(width: 150)
                referenceDetails(version: version, addedAt: addedAt, madeWith: madeWith)
            }
            VStack(alignment: .leading, spacing: Spacing.s) {
                figure(version: version)
                    .frame(maxWidth: 200)
                referenceDetails(version: version, addedAt: addedAt, madeWith: madeWith)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func figure(version: Int) -> some View {
        OnMePreviewFigure(pieces: AppModel.profileReferencePieces, label: "Simulated reference v\(version)")
    }

    private func referenceDetails(version: Int, addedAt: Date, madeWith: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Simulated reference v\(version)")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityIdentifier("onMeReferenceVersion")
            Text("Added \(addedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
            Text(madeWith == 1 ? "1 retained preview was made with this version." : "\(madeWith) retained previews were made with this version.")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            StatusBadge(kind: .simulated, compact: true)
            // Delete sits in the menu and still opens its review before anything is removed.
            ActionGroup(moreIdentifier: "onMeReferenceMore") {
                Button {
                    app.profileUI.editor = .onMeReplace
                } label: {
                    Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Reviews replacing the reference. Earlier previews stay.")
                .accessibilityIdentifier("onMeReferenceReplace")
            } more: {
                Button(role: .destructive) {
                    app.profileUI.onMeDeleteScope = .referenceOnly
                    app.profileUI.editor = .onMeDelete
                } label: {
                    Label("Delete…", systemImage: "trash")
                }
                .accessibilityHint("Reviews what to delete before anything is removed")
                .accessibilityIdentifier("onMeReferenceDelete")
            }
        }
    }
}

// MARK: - Replace review

/// Replace: future previews use the new version; earlier previews keep theirs.
struct ProfileOnMeReplaceReview: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let current = app.store.profile.onMeReference.version
        let next = app.profileNextReferenceVersion
        let earlier = app.profilePreviews(madeWithReference: current)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Future previews use the new version; earlier previews stay.")
                        .font(.editorial(.title3))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    DetailsDisclosure(
                        "What changes",
                        count: current == nil ? 2 : 3,
                        isExpanded: app.profileUI.detailsBinding("onMeReplaceChanges"),
                        identifier: "onMeReplaceDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            if let current {
                                ProfileBullet(systemImage: "clock.arrow.circlepath", text: "Now: simulated reference v\(current). \(earlier.count == 1 ? "1 preview made with it stays" : "\(earlier.count) previews made with it stay") in Saved Looks, still labeled with v\(current).")
                            }
                            ProfileBullet(systemImage: "person.crop.rectangle.badge.plus", text: "Next: simulated reference v\(next), used only for new On Me previews you ask for.")
                            ProfileBullet(systemImage: "sparkles", text: "Nothing is regenerated. Replacing doesn't make new pictures.")
                        }
                    }
                    .cardStyle()
                    SimulationNotice(
                        text: "In the real app you'd choose a new full-body photo. Here a placeholder figure stands in — no photo is taken, stored or uploaded.",
                        summary: "No photo is taken or uploaded."
                    )
                    Button {
                        app.profileUseDemoReference(message: "Reference replaced with v\(next). Earlier previews kept. Saved on this device")
                        dismiss()
                    } label: {
                        Label("Use new demo placeholder (v\(next))", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("onMeReplaceConfirm")
                    Button("Keep v\(current ?? 0)") { dismiss() }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                }
                .padding(Spacing.m)
                .readableWidth(560)
            }
            .themedScreenBackground()
            .navigationTitle("Replace reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Delete review

/// Delete with an explicit scope: the reference only, or the reference and the
/// previews made with that version.
struct ProfileOnMeDeleteReview: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var ui = app.profileUI
        let version = app.store.profile.onMeReference.version
        let previews = app.profilePreviews(madeWithReference: version)
        let scope: ProfileOnMeDeleteScope = previews.isEmpty ? .referenceOnly : ui.onMeDeleteScope
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("What should be deleted?")
                        .font(.editorial(.title3))
                        .foregroundStyle(Palette.primaryText)
                    Text("Simulated reference v\(version ?? 0) will be removed from this device. Choose whether the previews made with it go too.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    ProfileScopeOption(
                        title: "Delete reference only",
                        detail: previews.isEmpty
                            ? "No retained previews were made with this version."
                            : "\(previews.count == 1 ? "The 1 preview" : "All \(previews.count) previews") made with it stay in Saved Looks, labeled with v\(version ?? 0).",
                        isSelected: scope == .referenceOnly
                    ) {
                        ui.onMeDeleteScope = .referenceOnly
                    }
                    .accessibilityIdentifier("onMeDeleteScopeReferenceOnly")

                    if !previews.isEmpty {
                        ProfileScopeOption(
                            title: "Delete reference and \(previews.count) preview\(previews.count == 1 ? "" : "s") made with it",
                            detail: "Removes \(previews.count == 1 ? "this preview" : "these previews") from Saved Looks and collections on this device. Outfits and garments aren't touched.",
                            isSelected: scope == .referenceAndPreviews
                        ) {
                            ui.onMeDeleteScope = .referenceAndPreviews
                        }
                        .accessibilityIdentifier("onMeDeleteScopeWithPreviews")

                        if scope == .referenceAndPreviews {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                ForEach(previews) { preview in
                                    HStack(spacing: Spacing.s) {
                                        Image(systemName: "photo")
                                            .foregroundStyle(Palette.secondaryText)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preview.title)
                                                .font(.subheadline)
                                                .foregroundStyle(Palette.primaryText)
                                            Text(preview.createdAt.formatted(date: .abbreviated, time: .omitted) + (preview.isFavorite ? " · Favorite" : ""))
                                                .font(.caption)
                                                .foregroundStyle(Palette.secondaryText)
                                        }
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            .cardStyle()
                        }
                    }

                    DetailsDisclosure(
                        "What stays the same",
                        count: 2,
                        isExpanded: app.profileUI.detailsBinding("onMeDeleteKept"),
                        identifier: "onMeDeleteDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ProfileBullet(systemImage: "lock.shield", text: "The On Me picture permission isn't changed — manage it under Processing permissions.")
                            ProfileBullet(systemImage: "square.grid.2x2", text: "Outfit boards keep working without a reference.")
                        }
                    }
                    SimulationNotice(
                        text: "Only demo data on this device is deleted. A real app would also show any pending iCloud deletion.",
                        summary: "Only demo data on this device."
                    )

                    Button(role: .destructive) {
                        delete(scope: scope, previews: previews)
                    } label: {
                        Label(scope == .referenceAndPreviews ? "Delete reference and \(previews.count) preview\(previews.count == 1 ? "" : "s")" : "Delete reference", systemImage: "trash")
                    }
                    .buttonStyle(DestructiveButtonStyle(fullWidth: true))
                    .accessibilityIdentifier("onMeDeleteConfirm")
                    Button("Cancel") { dismiss() }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                }
                .padding(Spacing.m)
                .readableWidth(560)
            }
            .themedScreenBackground()
            .navigationTitle("Delete reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }

    private func delete(scope: ProfileOnMeDeleteScope, previews: [PreviewEntry]) {
        let count = previews.count
        if scope == .referenceAndPreviews {
            for preview in previews { app.store.deletePreview(preview.id) }
        }
        app.store.updateProfile { $0.onMeReference = .none }
        let message = scope == .referenceAndPreviews
            ? "Reference and \(count) preview\(count == 1 ? "" : "s") deleted on this device"
            : "Reference deleted on this device. Earlier previews kept"
        app.profileConfirmSave(message)
        app.profileUI.onMeDeleteScope = .referenceOnly
        dismiss()
    }
}

/// Radio-style scope choice with icon + text (selection never shown by color alone).
struct ProfileScopeOption: View {
    var title: String
    var detail: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Palette.primaryAction : Palette.secondaryText)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .cardStyle(highlighted: isSelected)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("On Me delete review") {
    let model = AppModel.preview
    model.profileUseDemoReference(message: "")
    return ProfileOnMeDeleteReview()
        .previewEnvironment(model)
}
