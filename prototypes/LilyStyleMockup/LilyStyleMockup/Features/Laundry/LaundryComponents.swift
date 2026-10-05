import SwiftUI

// MARK: - Types

/// Which clothes the Laundry screen covers.
enum LaundryScopeChoice: Hashable {
    case entireCloset
    case thisSuitcase
}

/// A reviewed laundry action. Targets (with their ownership/availability and
/// membership revisions) are captured when the review opens, and confirming
/// commits exactly these. Anything marked Dirty afterwards isn't included.
struct LaundryReviewDraft: Identifiable {
    enum Kind: Hashable { case selectedLoad, sweep }

    let id = UUID()
    var kind: Kind
    var scope: LaundryScope
    var scopeLabel: String
    var targets: [LaundryTarget]
    /// What she asked for (selected IDs for a load); compared with targets for honesty.
    var requestedIDs: [String]
    var capturedAt: Date = .now
}

/// Honest result of a committed laundry action.
struct LaundryOutcome: Identifiable {
    struct Skip: Hashable {
        var name: String
        var reason: String
    }

    let id = UUID()
    var kind: LaundryReviewDraft.Kind
    var scopeLabel: String
    var cleanedNames: [String]
    var skipped: [Skip]
    var saveError: String?
    var at: Date = .now

    var title: String {
        cleanedNames.isEmpty ? "Nothing was marked clean" : "Marked \(LaundryText.items(cleanedNames.count)) clean"
    }

    var toastText: String {
        var text = title + "."
        if !skipped.isEmpty {
            text += " \(LaundryText.items(skipped.count)) skipped because \(skipped.count == 1 ? "it" : "they") changed since review."
        }
        if let saveError {
            text += " \(saveError)"
        } else if !cleanedNames.isEmpty {
            text += " Saved on this device."
        }
        return text
    }
}

enum LaundryText {
    static func items(_ n: Int) -> String { "\(n) \(n == 1 ? "item" : "items")" }

    static func list(_ names: [String]) -> String { ListFormatter.localizedString(byJoining: names) }
}

// MARK: - Dirty row

/// One Dirty garment with an explicit Mark clean button, or a selection toggle in load mode.
/// Tapping the photo never marks anything clean.
struct LaundryDirtyRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var garment: Garment
    var suitcaseNames: [String]
    var isSelecting: Bool
    var isSelected: Bool
    var onMarkClean: () -> Void
    var onToggle: () -> Void

    var body: some View {
        Group {
            if isSelecting {
                Button(action: onToggle) {
                    HStack(alignment: .center, spacing: Spacing.s) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? Palette.primaryAction : Palette.controlBorder)
                            .frame(minWidth: 28)
                            .accessibilityHidden(true)
                        info
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
                .accessibilityLabel("\(garment.accessibilityDescription), Dirty")
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityHint(isSelected ? "Removes it from this load" : "Adds it to this load")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("laundrySelect-\(garment.id)")
            } else {
                let vertical = dynamicTypeSize.isAccessibilitySize
                let layout = vertical
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
                    : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
                layout {
                    info
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: onMarkClean) {
                        Label("Mark clean", systemImage: "checkmark")
                            .lineLimit(vertical ? nil : 1)
                    }
                    .buttonStyle(SuccessButtonStyle(fullWidth: vertical))
                    .fixedSize(horizontal: !vertical, vertical: false)
                    .accessibilityLabel("Mark \(garment.displayName) clean")
                    .accessibilityHint("Changes only this item to Available. You can undo.")
                    .accessibilityIdentifier("laundryMarkClean-\(garment.id)")
                }
            }
        }
        .cardStyle(padding: Spacing.s, highlighted: isSelecting && isSelected)
    }

    private var info: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s))
        return layout {
            GarmentThumbnail(garment: garment, size: 64, showsStatus: false)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(garment.displayName)
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(garment.colorLabel) · \(garment.kind.label)")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                StatusBadge(kind: .dirty, compact: true)
                if !suitcaseNames.isEmpty {
                    Label {
                        Text("Same status in \(LaundryText.list(suitcaseNames))")
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "suitcase")
                    }
                    .font(.caption2)
                    .foregroundStyle(Palette.secondaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rules note

/// What laundry does and never does. Shown on the screen and in reviews as a closed
/// details row; the five rules open in place.
struct LaundryRulesNote: View {
    /// Shared open state for the Laundry screen; the review sheet leaves it out and keeps its own.
    var isExpanded: Binding<Bool>?

    var body: some View {
        DetailsDisclosure("What laundry changes", count: 5, systemImage: "info.circle", isExpanded: isExpanded, identifier: "laundryRulesToggle") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                bullet("Only owned, arrived Dirty items become Available.")
                bullet("Unavailable, Archived, No longer owned, not-arrived and Trash items are never changed.")
                bullet("Marking an outfit worn never makes items dirty.")
                bullet("A shared garment has one status, so it's the same in every suitcase and Main Closet.")
                bullet("No AI or pictures are involved, and nothing counts against your styling allowance.")
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.accentSurface.opacity(0.55)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("laundryRulesNote")
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text("•").accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
        .foregroundStyle(Palette.secondaryText)
    }
}

// MARK: - Outcome card

struct LaundryOutcomeCard: View {
    var outcome: LaundryOutcome
    /// Shared open state for "What changed".
    var detailsExpanded: Binding<Bool>?
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(outcome.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
            } icon: {
                Image(systemName: outcome.skipped.isEmpty && outcome.saveError == nil ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(outcome.skipped.isEmpty && outcome.saveError == nil ? Palette.success : Palette.primaryAction)
            }
            // Scope, time and the skipped count stay on screen; names open in place.
            Text(([outcome.scopeLabel, outcome.at.formatted(date: .omitted, time: .shortened)]
                  + (outcome.skipped.isEmpty ? [] : ["\(outcome.skipped.count) skipped"])).joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
            if !outcome.cleanedNames.isEmpty || !outcome.skipped.isEmpty {
                DetailsDisclosure("What changed", count: outcome.cleanedNames.count + outcome.skipped.count,
                                  isExpanded: detailsExpanded, identifier: "laundryOutcomeDetails") {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        if !outcome.cleanedNames.isEmpty {
                            Text("Now Available: \(LaundryText.list(outcome.cleanedNames)).")
                                .font(.footnote)
                                .foregroundStyle(Palette.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        ForEach(outcome.skipped, id: \.self) { skip in
                            Text("Skipped \(skip.name): \(skip.reason.lowercased()). Left as it is.")
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            if let error = outcome.saveError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Dismiss", action: onDismiss)
                .font(.subheadline.weight(.semibold))
                .minimumHitTarget()
                .accessibilityLabel("Dismiss laundry result")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: Spacing.s)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("laundryOutcome")
    }
}
