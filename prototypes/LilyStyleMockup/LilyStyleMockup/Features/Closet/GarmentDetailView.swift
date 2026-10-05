import SwiftUI

/// One canonical garment: picture and honest image label, facts with Unknowns,
/// current status with explicit actions and consequences, names, photo,
/// suitcase links, saved looks, and archive / no-longer-own / Trash lifecycle.
///
/// Used pushed (`.garment(id)`) and embedded in the Closet's detail pane.
struct GarmentDetailView: View {
    var garmentID: String
    /// True inside the Closet's side-by-side pane (no navigation title; clears selection on delete).
    var isEmbedded: Bool

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var pending: ClosetPendingAction?
    /// Only the copy Lily can see presents the shared sheets (a hidden tab or a screen
    /// pushed over this one may show the same garment).
    @State private var isOnScreen = false

    init(garmentID: String, isEmbedded: Bool = false) {
        self.garmentID = garmentID
        self.isEmbedded = isEmbedded
    }

    var body: some View {
        Group {
            if let garment = app.store.garment(garmentID) {
                content(garment)
            } else {
                missingState
            }
        }
        .themedScreenBackground()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            foldIntoPaneIfWide(width)
        }
        .modifier(ClosetDetailChrome(isEmbedded: isEmbedded, title: app.store.garment(garmentID)?.displayName ?? "Deleted item"))
        .closetLifecycleConfirmations($pending)
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .sheet(isPresented: sheetBinding(\.factsEditorID)) {
            // The GarmentEditor feature's facts form brings its own navigation
            // stack with Cancel/Save, so it is presented as is.
            GarmentFactsEditor(garmentID: garmentID)
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .sheet(isPresented: sheetBinding(\.detailDeletionReviewID), onDismiss: finishIfDeleted) {
            ClosetDeletionReviewSheet(garmentID: garmentID)
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }

    private func content(_ garment: Garment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                ClosetDetailHeader(garment: garment)
                ClosetStatusCard(garment: garment, pending: $pending, onReviewDeletion: { app.closetUI.detailDeletionReviewID = garmentID })
                if !garment.isTrashed {
                    ClosetStylingCard(garment: garment, pending: $pending)
                }
                GarmentNamingSection(garmentID: garment.id)
                GarmentPhotoSection(garmentID: garment.id)
                ClosetFactsCard(garment: garment, onEdit: { app.closetUI.factsEditorID = garmentID })
                ClosetSuitcaseMembershipCard(garment: garment)
                ClosetSavedLooksCard(garment: garment)
                if !garment.isTrashed {
                    ClosetLifecycleCard(garment: garment, pending: $pending)
                }
            }
            .padding(Spacing.m)
            .padding(.bottom, Spacing.xl)
            .readableWidth(isEmbedded ? .infinity : 760)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("garmentDetail-\(garment.id)")
    }

    private var missingState: some View {
        ScrollView {
            EmptyStateView(
                title: "This item was deleted",
                message: "It was permanently deleted, so its details, photo and names are gone. Saved looks that included it show a missing-piece placeholder.",
                systemImage: "questionmark.square.dashed",
                actionTitle: isEmbedded ? "Close" : "Back",
                action: close
            )
            .padding(.top, Spacing.xxl)
        }
        .accessibilityIdentifier("garmentDetailMissing")
    }

    /// A sheet kept in `closetUI` for this garment, so it reopens on whichever copy of the
    /// detail is showing after a resize, pane fold or shell switch.
    private func sheetBinding(_ key: ReferenceWritableKeyPath<ClosetUIState, String?>) -> Binding<Bool> {
        let ui = app.closetUI
        return Binding(
            get: { isOnScreen && ui[keyPath: key] == garmentID },
            set: { if !$0, isOnScreen, ui[keyPath: key] == garmentID { ui[keyPath: key] = nil } }
        )
    }

    private func close() {
        if app.closetUI.selectedGarmentID == garmentID { app.closetUI.selectedGarmentID = nil }
        if !isEmbedded { dismiss() }
    }

    /// A detail the one-pane grid pushed folds back into the Closet's side pane
    /// when the window becomes wide enough for two panes. The selection stays.
    /// Navigation only; nothing is dispatched.
    private func foldIntoPaneIfWide(_ width: CGFloat) {
        guard !isEmbedded,
              app.section == .closet,
              app.closetUI.pushedDetailID == garmentID,
              app.closetUI.selectedGarmentID == garmentID,
              (app.paths[.closet]?.count ?? 0) == 1,
              ClosetLayout(width: width, isVerticallyCompact: verticalSizeClass == .compact).isTwoPane
        else { return }
        app.closetUI.pushedDetailID = nil
        app.paths[.closet]?.removeLast()
    }

    /// After a reviewed permanent deletion: pop the pushed detail or clear the pane selection.
    private func finishIfDeleted() {
        guard app.store.garment(garmentID) == nil else { return }
        close()
    }
}

/// Navigation title only when pushed; the embedded pane sits under "Closet".
private struct ClosetDetailChrome: ViewModifier {
    var isEmbedded: Bool
    var title: String

    func body(content: Content) -> some View {
        if isEmbedded {
            content
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header

/// Large picture with an honest image label, then name, color, type, brand/size and badges.
struct ClosetDetailHeader: View {
    @Environment(AppModel.self) private var app
    var garment: Garment

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.l) {
                picture
                    .frame(width: 260)
                facts
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: Spacing.m) {
                picture
                    .frame(maxWidth: 380)
                    .frame(maxWidth: .infinity)
                facts
            }
        }
    }

    private var picture: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GarmentThumbnail(garment: garment, showsImageKind: false, showsStatus: false)
            imageLabel
        }
    }

    @ViewBuilder private var imageLabel: some View {
        let label = ClosetImageLabel(garment: garment)
        // The short label stays under the picture; the longer explanation is one tap away.
        HStack(spacing: Spacing.xxs) {
            Label(label.title, systemImage: label.systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityIdentifier("garmentImageLabel")
            InfoButton("this picture", title: label.title, text: label.detail)
            Spacer(minLength: 0)
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(garment.displayName)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.xs) {
                if let color = garment.color {
                    ColorSwatch(hex: color.hex, size: 18)
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityHidden(true)
                }
                Text(garment.colorLabel)
                    .italic(garment.color == nil)
                    .foregroundStyle(garment.color == nil ? Palette.secondaryText : Palette.primaryText)
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Color: \(garment.colorLabel)")

            Text("\(garment.category.label) · \(garment.kind.label)")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .accessibilityLabel("Category: \(garment.category.label), type: \(garment.kind.label)")

            Text(brandSizeLine)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            BadgeRow(badges: badges, compact: false)
                .padding(.top, Spacing.xxs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Status: " + badges.map(\.text).joined(separator: ", "))
        }
    }

    private var brandSizeLine: String {
        "Brand: \(garment.brand ?? "Unknown") · Size: \(garment.sizeLabel ?? "Unknown")"
    }

    private var badges: [BadgeKind] {
        var list = garment.closetStatusBadges
        if !garment.isTrashed, app.workingScope.isSuitcase, !app.store.isInScope(garment, app.workingScope) {
            list.append(.outsideSource)
        }
        list.append(garment.closetImageBadge)
        return list
    }
}

/// Honest description of how the garment is pictured.
struct ClosetImageLabel {
    var title: String
    var detail: String
    var systemImage: String

    init(garment: Garment) {
        if garment.photoFilename != nil {
            title = "Your photo"
            detail = "Stored on this device. Simulated processing never replaces the original."
            systemImage = "camera"
        } else if garment.imageKind == .actualPhoto {
            title = "Your photo (demo stand-in)"
            detail = "In this demo an illustration stands in for your photo of this exact garment."
            systemImage = "camera"
        } else if garment.imageKind == .textOnly {
            title = "Representative image"
            detail = "Representative image — add your photo for actual details. Added from text only. The picture is a generic stand-in, not your garment."
            systemImage = "text.alignleft"
        } else {
            title = "Representative image"
            detail = "Representative image — add your photo for actual details. A generic stand-in drawn in its confirmed color, not a photo of your garment."
            systemImage = "photo.artframe"
        }
    }
}

#Preview("Dirty item") {
    NavigationStack {
        GarmentDetailView(garmentID: "g-lace-top")
            .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
    }
    .previewEnvironment()
}

#Preview("Not arrived") {
    NavigationStack {
        GarmentDetailView(garmentID: "g-cream-crop")
    }
    .previewEnvironment()
}

#Preview("In Trash") {
    NavigationStack {
        GarmentDetailView(garmentID: "g-gray-leggings")
    }
    .previewEnvironment()
}

#Preview("Wishlist") {
    NavigationStack {
        GarmentDetailView(garmentID: "g-camel-trench")
    }
    .previewEnvironment()
}

#Preview("Deleted") {
    NavigationStack {
        GarmentDetailView(garmentID: "g-missing")
    }
    .previewEnvironment()
}
