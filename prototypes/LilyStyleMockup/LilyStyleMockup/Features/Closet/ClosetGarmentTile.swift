import SwiftUI

/// One garment in the Closet grid: picture with its status, name, color, image
/// source and suitcase count. Long-press/right-click offers explicit actions;
/// owned pieces can be dragged into Style Me's starting-piece control on iPad.
struct ClosetGarmentTile: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    /// Shown in the side-by-side detail pane.
    var isSelected: Bool
    /// Last opened item in the single-pane layout (kept across rotation).
    var isRemembered: Bool = false
    var onOpen: () -> Void
    var onRequest: (ClosetPendingAction) -> Void

    var body: some View {
        let suitcaseCount = app.store.suitcases(containing: garment.id).count
        Button(action: onOpen) {
            tileContent(suitcaseCount: suitcaseCount)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .contextMenu { ClosetGarmentMenu(garment: garment, onOpen: onOpen, onRequest: onRequest) }
        .modifier(ClosetGarmentDragModifier(garment: garment))
        .accessibilityLabel(garment.accessibilityDescription)
        .accessibilityValue(accessibilityValue(suitcaseCount: suitcaseCount))
        .accessibilityHint(isSelected ? "Shown in the detail pane" : "Opens details")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("garmentTile-\(garment.id)")
        .accessibilityActions {
            if garment.isCurrentlyOwned, garment.availability == .dirty {
                Button("Mark clean") { app.closetMarkClean(garment.id) }
            }
            if garment.isCurrentlyOwned, garment.availability == .available {
                Button("Mark dirty") { app.closetMarkDirty(garment.id) }
            }
        }
    }

    private func tileContent(suitcaseCount: Int) -> some View {
        let statuses = BadgeKind.status(for: garment)
        let extraBadges = Array(statuses.dropFirst()) + [garment.closetImageBadge]
        return VStack(alignment: .leading, spacing: Spacing.xxs + 2) {
            GarmentThumbnail(garment: garment, showsImageKind: false, showsStatus: true)
                .overlay(alignment: .bottomTrailing) {
                    if suitcaseCount > 0 { suitcaseBadge(suitcaseCount) }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                        .strokeBorder(isSelected ? Palette.primaryAction : (isRemembered ? Palette.controlBorder : .clear),
                                      lineWidth: isSelected ? 3 : 1.5)
                }
            Text(garment.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Palette.primaryAction : Palette.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.xxs + 2) {
                if let color = garment.color {
                    ColorSwatch(hex: color.hex, size: 12)
                }
                Text(garment.colorLabel)
                    .font(.caption)
                    .italic(garment.color == nil)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            BadgeRow(badges: extraBadges)
            if let trashedAt = garment.trashedAt {
                Text(ClosetDates.recoveryCaption(trashedAt: trashedAt))
                    .font(.caption2)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: Radius.tile + 2, style: .continuous)
                .fill(isSelected ? Palette.accentSurface.opacity(0.7) : .clear)
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
    }

    private func suitcaseBadge(_ count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "suitcase.fill")
            Text("\(count)")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Palette.primaryText)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(Palette.surface.opacity(0.95)))
        .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
        .padding(6)
        .accessibilityHidden(true)
    }

    private func accessibilityValue(suitcaseCount: Int) -> String {
        var parts: [String] = []
        if isSelected { parts.append("Selected") }
        let statuses = BadgeKind.status(for: garment).map(\.text)
        parts.append(statuses.isEmpty ? (garment.isCurrentlyOwned ? "Available" : garment.ownership.label) : statuses.joined(separator: ", "))
        parts.append(garment.closetImageBadge.text)
        if suitcaseCount > 0 { parts.append(suitcaseCount == 1 ? "In 1 suitcase" : "In \(suitcaseCount) suitcases") }
        if let trashedAt = garment.trashedAt { parts.append(ClosetDates.recoveryCaption(trashedAt: trashedAt)) }
        return parts.joined(separator: ". ")
    }
}

/// Explicit per-item actions. Consequential ones go through a confirmation.
struct ClosetGarmentMenu: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    var onOpen: () -> Void
    var onRequest: (ClosetPendingAction) -> Void

    var body: some View {
        Button(action: onOpen) {
            Label("View details", systemImage: "info.circle")
        }
        if garment.isTrashed {
            Button {
                app.closetRestore(garment.id)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            Button(role: .destructive) {
                app.closetUI.deletionReviewID = garment.id
            } label: {
                Label("Delete permanently…", systemImage: "trash.slash")
            }
        } else {
            statusItems
            if garment.isOwnedOrPurchased {
                suitcaseMenu
            }
            Divider()
            if garment.isCurrentlyOwned, garment.availability != .archived {
                Button {
                    app.closetArchive(garment.id)
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }
            if garment.isOwnedOrPurchased {
                Button {
                    onRequest(.noLongerOwn(garment.id))
                } label: {
                    Label("No longer own…", systemImage: "arrow.uturn.left.circle")
                }
            }
            Button(role: .destructive) {
                onRequest(.moveToTrash(garment.id))
            } label: {
                Label("Move to Trash…", systemImage: "trash")
            }
        }
    }

    @ViewBuilder private var statusItems: some View {
        if garment.isCurrentlyOwned {
            switch garment.availability {
            case .dirty:
                Button {
                    app.closetMarkClean(garment.id)
                } label: {
                    Label("Mark clean", systemImage: "checkmark.circle")
                }
            case .available:
                Button {
                    app.closetMarkDirty(garment.id)
                } label: {
                    Label("Mark dirty", systemImage: BadgeKind.dirty.systemImage)
                }
            case .unavailable:
                Button {
                    app.closetMarkAvailable(garment.id)
                } label: {
                    Label("Mark available", systemImage: "checkmark.circle")
                }
            case .archived:
                Button {
                    app.closetUnarchive(garment.id)
                } label: {
                    Label("Unarchive", systemImage: "archivebox")
                }
            }
        }
        if garment.ownership == .noLongerOwned {
            Button {
                app.closetOwnAgain(garment.id)
            } label: {
                Label("I own this again", systemImage: "arrow.uturn.backward.circle")
            }
        }
        if garment.ownership == .purchasedConfirmed, garment.arrival != .arrived {
            Button {
                app.closetMarkArrived(garment.id)
            } label: {
                Label("Mark arrived", systemImage: "shippingbox")
            }
        }
    }

    private var suitcaseMenu: some View {
        Menu {
            let suitcases = app.store.activeSuitcases()
            if suitcases.isEmpty {
                Button {
                    app.push(.suitcases)
                } label: {
                    Label("Create a suitcase…", systemImage: "plus")
                }
            }
            ForEach(suitcases) { suitcase in
                let isMember = app.store.membership(garmentID: garment.id, suitcaseID: suitcase.id) != nil
                Button {
                    app.closetAddToSuitcase(garment.id, suitcaseID: suitcase.id)
                } label: {
                    Label(isMember ? "\(suitcase.name) (already in)" : suitcase.name,
                          systemImage: isMember ? "checkmark" : "suitcase")
                }
                .disabled(isMember)
            }
        } label: {
            Label("Add to suitcase", systemImage: "suitcase")
        }
    }
}

/// Owned and bought pieces drag as `garment:<id>` for Style Me's starting-piece
/// control. Wishlist/inspiration and Trash items are not draggable as clothes.
struct ClosetGarmentDragModifier: ViewModifier {
    var garment: Garment

    func body(content: Content) -> some View {
        if garment.isOwnedOrPurchased {
            content.draggable(DragPayload.garment(garment.id)) {
                GarmentArtwork(kind: garment.kind, hex: garment.color?.hex)
                    .frame(width: 96, height: 96)
            }
        } else {
            content
        }
    }
}

// MARK: - Shared helpers

extension Garment {
    /// Image-source badge for the closet: your photo (demo), representative or text only.
    var closetImageBadge: BadgeKind {
        BadgeKind.image(for: photoFilename != nil ? .actualPhoto : imageKind)
    }

    /// Status badges plus an explicit Available badge for current clothes with no restriction.
    var closetStatusBadges: [BadgeKind] {
        let statuses = BadgeKind.status(for: self)
        if statuses.isEmpty, isCurrentlyOwned {
            return [.custom("Available", "checkmark.circle")]
        }
        return statuses
    }
}

/// Trash recovery window arithmetic (30 days, shown to the user).
enum ClosetDates {
    static let recoveryDays = 30

    static func recoveryDeadline(trashedAt: Date) -> Date {
        trashedAt.addingTimeInterval(Double(recoveryDays) * 86_400)
    }

    static func daysLeft(trashedAt: Date, now: Date = .now) -> Int {
        let remaining = recoveryDeadline(trashedAt: trashedAt).timeIntervalSince(now)
        return max(0, Int((remaining / 86_400).rounded(.up)))
    }

    static func recoveryCaption(trashedAt: Date) -> String {
        let days = daysLeft(trashedAt: trashedAt)
        return days == 1 ? "Recoverable for 1 more day" : "Recoverable for \(days) more days"
    }
}

#Preview("Tiles") {
    let model = AppModel.preview
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .top)], spacing: 24) {
            ForEach(model.store.garments.prefix(8)) { garment in
                ClosetGarmentTile(garment: garment, isSelected: garment.id == "g-lace-top", onOpen: {}, onRequest: { _ in })
            }
        }
        .padding()
    }
    .themedScreenBackground()
    .previewEnvironment(model)
}
