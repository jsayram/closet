import SwiftUI

/// Brief confirmation/undo/error toast. Respects Reduce Motion.
struct ToastOverlay: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var actionFocused: Bool

    var body: some View {
        if let toast = app.toast {
            ToastCard(toast: toast, bottomPadding: 64, actionFocused: $actionFocused)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .id(toast.id)
                .task(id: toast.id) {
                    switch toast.style {
                    case .error: Haptics.warning()
                    case .success: Haptics.success()
                    case .info: Haptics.lightImpact()
                    }
                    // With VoiceOver or Switch Control, a toast with an action (Undo, Restore, …) stays
                    // until she uses it or dismisses it; reaching it can take longer than any timer.
                    if toast.actionTitle != nil, UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning { return }
                    try? await Task.sleep(nanoseconds: toast.actionTitle == nil ? 3_500_000_000 : 6_000_000_000)
                    // Never pull the action out from under accessibility focus.
                    while actionFocused, !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                    if app.toast?.id == toast.id {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { app.toast = nil }
                    }
                }
                .onAppear {
                    let spoken = toast.actionTitle.map { "\(toast.text). \($0) available." } ?? toast.text
                    UIAccessibility.post(notification: .announcement, argument: spoken)
                }
        }
    }
}

/// The toast's card: icon and tint by style, text, optional action and Dismiss.
/// `ToastOverlay` owns timing, haptics and the VoiceOver announcement; sheet mirrors
/// draw just this card so a toast looks the same wherever it shows.
struct ToastCard: View {
    @Environment(AppModel.self) private var app
    var toast: ToastMessage
    var bottomPadding: CGFloat = Spacing.m
    /// Lets `ToastOverlay` hold the toast while the action has accessibility focus.
    var actionFocused: AccessibilityFocusState<Bool>.Binding?
    @AccessibilityFocusState private var localActionFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: Self.icon(toast.style))
                .foregroundStyle(Self.tint(toast.style))
                .accessibilityHidden(true)
            Text(toast.text)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.xs)
            if let title = toast.actionTitle, let action = toast.action {
                Button(title) {
                    app.toast = nil
                    action()
                }
                .font(.subheadline.weight(.semibold))
                .minimumHitTarget()
                .accessibilityFocused(actionFocused ?? $localActionFocused)
            }
            Button {
                app.toast = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.secondaryText)
                    .minimumHitTarget()
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.surface).shadow(color: .black.opacity(0.12), radius: 10, y: 4))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Self.tint(toast.style).opacity(0.5), lineWidth: 1))
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: 560)
        .accessibilityElement(children: .contain)
    }

    static func icon(_ style: ToastMessage.Style) -> String {
        switch style {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    static func tint(_ style: ToastMessage.Style) -> Color {
        switch style {
        case .success: Palette.success
        case .info: Palette.primaryAction
        case .error: Palette.error
        }
    }
}

/// Development-only counter proving passive interactions don't call services.
struct DispatchHUD: View {
    @Environment(AppModel.self) private var app
    @State private var expanded = false

    var body: some View {
        Button {
            expanded.toggle()
        } label: {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Calls \(app.dispatch.userInitiatedTotal)")
                    Text("· reused \(app.dispatch.avoidedDispatches)")
                    if app.dispatch.automaticDispatches > 0 {
                        Text("· auto \(app.dispatch.automaticDispatches)")
                    }
                }
                .font(.caption2.monospacedDigit().weight(.semibold))
                if expanded {
                    ForEach(ServiceKind.allCases) { kind in
                        Text("\(kind.label): \(app.dispatch.count(kind))")
                            .font(.caption2.monospacedDigit())
                    }
                    Text("Auto: weather the app loads on its own")
                        .font(.caption2)
                }
            }
            .foregroundStyle(Palette.onPrimaryAction)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Palette.primaryAction.opacity(0.92)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dispatchHUD")
        // UI tests read the first two numbers as calls and reused, so keep that order.
        .accessibilityLabel("Simulated service calls you started: \(app.dispatch.userInitiatedTotal). Reused locally: \(app.dispatch.avoidedDispatches). Automatic weather loads: \(app.dispatch.automaticDispatches).")
    }
}

/// Shared source picker used by Style Me and Closet: Main Closet or one named suitcase.
struct SourceSelector: View {
    @Environment(AppModel.self) private var app
    var onManage: (() -> Void)?

    var body: some View {
        Menu {
            Picker("Wardrobe source", selection: Binding(
                get: { app.workingScope },
                set: { app.selectScope($0) }
            )) {
                Label("Main Closet", systemImage: "cabinet").tag(WardrobeScope.mainCloset)
                ForEach(app.store.activeSuitcases()) { suitcase in
                    Label("\(suitcase.name) · \(app.store.memberIDs(of: suitcase.id).count)", systemImage: "suitcase").tag(WardrobeScope.suitcase(suitcase.id))
                }
            }
            if let onManage {
                Divider()
                Button { onManage() } label: { Label("Manage suitcases…", systemImage: "slider.horizontal.3") }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: app.workingScope.isSuitcase ? "suitcase.fill" : "cabinet.fill")
                VStack(alignment: .leading, spacing: 0) {
                    Text("Source")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                    Text(app.workingScopeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(Palette.surface))
            .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
        }
        .accessibilityLabel("Wardrobe source: \(app.workingScopeName)")
        .accessibilityHint("Choose Main Closet or a suitcase")
        .accessibilityIdentifier("sourceSelector")
    }
}
