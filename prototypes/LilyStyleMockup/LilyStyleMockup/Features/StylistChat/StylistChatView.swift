import SwiftUI

/// Ask Stylist (FR-14): a calm, secondary chat. Modeled on minimal assistant
/// patterns — a greeting, a few suggested questions, one composer card with an
/// optional attached look and a Closet only / Closet + new ideas mode. Answers
/// come back as short text plus a flat-lay look you can open or save.
/// Opening, typing or scrolling never dispatches; only Send does.
struct StylistChatView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var composerFocused: Bool

    private var chat: StylistChatSession { app.chat }
    /// At accessibility text sizes the pause banners and footer scroll with the
    /// conversation, so the pinned composer never covers most of the screen.
    private var pinsExtras: Bool { !dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.m) {
                        if chat.messages.isEmpty {
                            StylistChatGreeting(onPick: send)
                                .padding(.top, Spacing.l)
                        }
                        ForEach(Array(chat.messages.enumerated()), id: \.element.id) { index, message in
                            StylistChatMessageRow(message: message, index: index, onFollowUp: send)
                                .id(message.id)
                                .transition(Motion.cardTransition(reduceMotion: reduceMotion))
                        }
                        if chat.isResponding {
                            StylistChatTypingRow()
                                .id("typing")
                                .transition(.opacity)
                        }
                        if !pinsExtras {
                            // After the latest message, so a pause that starts mid-chat shows up where she's reading.
                            StylistChatBlockers()
                            StylistChatFooter()
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.m)
                    .readableWidth(720)
                    .animation(Motion.animation(Motion.layout, reduceMotion: reduceMotion), value: chat.messages.count)
                    .animation(Motion.animation(Motion.standard, reduceMotion: reduceMotion), value: chat.isResponding)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chat.messages.count) { _, _ in
                    guard let last = chat.messages.last else { return }
                    withAnimation(reduceMotion ? nil : Motion.layout) {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
                .onChange(of: chat.isResponding) { _, responding in
                    if responding { withAnimation(reduceMotion ? nil : Motion.layout) { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }
            .themedScreenBackground()
            .safeAreaInset(edge: .bottom) {
                StylistChatComposer(focused: $composerFocused, showsExtras: pinsExtras, onSend: { send(nil) })
                    .padding(.horizontal, Spacing.s)
                    .padding(.bottom, Spacing.xs)
                    .readableWidth(720)
                    .background(Palette.background.ignoresSafeArea(edges: .bottom))
            }
            .navigationTitle("Ask your stylist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !chat.messages.isEmpty {
                        Button {
                            app.clearChat()
                        } label: {
                            Label("New chat", systemImage: "square.and.pencil")
                        }
                        .accessibilityIdentifier("stylistChatNew")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
            .onChange(of: chat.messages.filter { $0.role == .stylist }.count) { old, new in
                if new > old { Haptics.success() }
            }
        }
    }

    private func send(_ text: String?) {
        app.sendChat(text)
    }
}

// MARK: - Greeting

private struct StylistChatGreeting: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onPick: (String) -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return "\(part), Lily"
    }

    private static let visibleSuggestions = 2

    private var suggestions: [String] {
        if app.chat.attachedOutfit != nil {
            return ["Would white sneakers work with this?", "Make it warmer for rain", "Is this too dressy for brunch?"]
        }
        return ["What goes with my olive trousers?", "An outfit for a gallery opening",
                "Make my navy dress pants feel less serious", "Which colors suit my closet?"]
    }

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.m) {
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Palette.primaryAction)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Palette.accentSurface))
                .modifier(StylistChatBreathe(active: !reduceMotion))
                .accessibilityHidden(true)
            VStack(spacing: Spacing.xxs) {
                Text(greeting)
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                Text("What would you like help with?")
                    .font(.title3)
                    .foregroundStyle(Palette.primaryText)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            // One line here; the full promise opens from the info button.
            HStack(spacing: Spacing.xxs) {
                Text("I style from your closet first")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                InfoButton("how the stylist works", title: "How the stylist works",
                           text: "I style from your closet first. Nothing is searched, bought or saved unless you choose.")
            }
            .padding(.horizontal, Spacing.l)

            // Two starters show; the rest open in place from "More ideas".
            VStack(spacing: Spacing.xs) {
                let shown = app.chat.showsMoreSuggestions ? suggestions : Array(suggestions.prefix(Self.visibleSuggestions))
                ForEach(Array(shown.enumerated()), id: \.offset) { index, text in
                    Button { onPick(text) } label: {
                        HStack {
                            Text(text)
                                .font(.subheadline)
                                .foregroundStyle(Palette.primaryText)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Spacing.xs)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.primaryAction)
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .frame(minHeight: HitTarget.minimum)
                        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                    }
                    .buttonStyle(.pressFeedback)
                    .disabled(!app.chatBlockers.isEmpty)
                    .staggeredAppear(index: index)
                    .accessibilityHint("Asks the stylist this question")
                    .accessibilityIdentifier("stylistChatSuggestion-\(index)")
                }
                if suggestions.count > Self.visibleSuggestions {
                    let open = app.chat.showsMoreSuggestions
                    Button {
                        Motion.perform(reduceMotion: reduceMotion) { app.chat.showsMoreSuggestions.toggle() }
                    } label: {
                        HStack(spacing: 2) {
                            Text(open ? "Fewer ideas" : "More ideas")
                            Image(systemName: open ? "chevron.up" : "chevron.down")
                                .imageScale(.small)
                        }
                    }
                    .buttonStyle(.quietLink)
                    .accessibilityValue(open ? "Expanded" : "Collapsed")
                    .accessibilityHint(open ? "Hides the extra questions" : "Shows \(suggestions.count - Self.visibleSuggestions) more questions to ask")
                    .accessibilityIdentifier("stylistChatMoreSuggestions")
                }
            }
            .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StylistChatBreathe: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([1.0, 1.06]) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in .easeInOut(duration: 1.6) }
        } else {
            content
        }
    }
}

// MARK: - Messages

private struct StylistChatMessageRow: View {
    @Environment(AppModel.self) private var app
    var message: StylistChatMessage
    var index: Int
    var onFollowUp: (String) -> Void

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: Spacing.xl)
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                    .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.accentSurface))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You: \(message.text)")
            .accessibilityIdentifier("stylistChatMessage-\(index)")
        case .notice:
            InlineBanner(style: .caution, title: message.text)
                .accessibilityIdentifier("stylistChatMessage-\(index)")
        case .stylist:
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.primaryAction)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Palette.accentSurface))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Stylist: \(message.text)")
                    if let outfit = message.outfit {
                        StylistChatLookCard(messageID: message.id, outfit: outfit)
                    }
                    if !message.followUps.isEmpty {
                        // One row of follow-ups that scrolls; the button at the end shows them all.
                        ChipCarousel(itemsLabel: "follow-up questions") {
                            ForEach(message.followUps, id: \.self) { text in
                                Button { onFollowUp(text) } label: {
                                    Text(text)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Palette.primaryAction)
                                        .padding(.horizontal, Spacing.s)
                                        .padding(.vertical, 6)
                                        .frame(minHeight: 34)
                                        .background(Capsule().fill(Palette.surface))
                                        .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
                                        .frame(minHeight: HitTarget.minimum)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.pressFeedback)
                                .disabled(app.chat.isResponding || !app.chatBlockers.isEmpty)
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stylistChatMessage-\(index)")
        }
    }
}

/// A look inside an answer: flat-lay, labelled pieces, and explicit actions.
private struct StylistChatLookCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The answer this look came with. Follow-up answers can reuse the same
    /// outfit ID, so the saved state is keyed by message.
    var messageID: UUID
    var outfit: Outfit

    /// Kept in the chat session rather than the card, so it survives the chat closing and reopening.
    private var saved: Bool { app.store.outfit(app.chat.savedLookIDs[messageID]) != nil }

    /// The source the answer was built for, so a piece outside a suitcase is labelled.
    private var scope: WardrobeScope { outfit.capturedScope ?? .mainCloset }

    private func badges(_ piece: OutfitPiece) -> [BadgeKind] {
        if app.store.isMissing(piece) { return [.missing] }
        guard let g = app.store.garment(piece.garmentID) else { return [] }
        return app.store.eligibility(of: g, scope: scope).issues.map(BadgeKind.from)
    }

    private var subtitle: String {
        let unowned = outfit.pieces.filter(\.isHypothetical).count
        let blocked = outfit.pieces.contains { piece in
            guard let g = app.store.garment(piece.garmentID) else { return piece.garmentID != nil }
            return !app.store.eligibility(of: g, scope: scope).isEligible
        }
        if blocked { return "Some pieces can't be used in \(app.store.scopeName(scope)) right now — see the labels" }
        switch unowned {
        case 0: return "Only clothes you own"
        case outfit.pieces.count: return "An idea — none of these pieces are yours"
        case 1: return "Your clothes plus one idea you don't own"
        default: return "Your clothes plus \(unowned) ideas you don't own"
        }
    }

    private var title: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text("Stylist suggestion")
                    .font(.editorial(.headline))
                    .foregroundStyle(Palette.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        } icon: {
            Image(systemName: "sparkles").foregroundStyle(Palette.primaryAction)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // Badge beside the title when it fits, under it at large text sizes.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer()
                    StatusBadge(kind: .simulated, compact: true)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    title
                    StatusBadge(kind: .simulated, compact: true)
                }
            }
            .accessibilityElement(children: .combine)
            OutfitFlatLayView(pieces: outfit.pieces, statusFor: badges)
                .frame(maxWidth: 360)
            OutfitPieceChips(pieces: outfit.pieces, statusFor: badges, scrolls: true)
            FlowLayout(spacing: Spacing.xs) {
                Button {
                    app.openChatLookInEditor(outfit)
                } label: {
                    Label("Open in editor", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("stylistChatOpenEditor")
                Button {
                    save()
                } label: {
                    Label(saved ? "Saved" : "Save look", systemImage: saved ? "checkmark.circle.fill" : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(saved || outfit.hasHypotheticalPiece)
                .accessibilityHint(outfit.hasHypotheticalPiece ? "Open it in the editor first to resolve the piece you don't own" : "Saves this look on this device")
            }
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        .onChange(of: saved) { _, isSaved in
            if isSaved { Haptics.success() }
        }
    }

    private func save() {
        guard !saved else { return }
        var copy = outfit
        copy.id = UUID().uuidString
        do {
            try app.store.saveOutfit(copy, asCopy: false)
            Motion.perform(reduceMotion: reduceMotion) { app.chat.savedLookIDs[messageID] = copy.id }
        } catch {
            app.showToast(error.localizedDescription, style: .error)
        }
    }
}

private struct StylistChatTypingRow: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.primaryAction)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Palette.accentSurface))
            WorkingDots()
            Text("Thinking with your closet…")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The stylist is answering")
    }
}

// MARK: - Composer

/// Why chat can't send right now. Pinned above the composer, or scrolled with
/// the conversation at accessibility text sizes.
private struct StylistChatBlockers: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ForEach(app.chatBlockers) { blocker in
            InlineBanner(style: .caution, title: "Chat is paused", message: blocker.message,
                         actionTitle: blocker == .awaitingSourceChoice ? "Use Main Closet" : nil,
                         action: blocker == .awaitingSourceChoice ? { app.selectScope(.mainCloset) } : nil)
        }
    }
}

private struct StylistChatFooter: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Text("Simulated stylist · \(app.workingScopeName) · this chat isn't saved")
            .font(.caption2)
            .foregroundStyle(Palette.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct StylistChatComposer: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var focused: FocusState<Bool>.Binding
    /// False at accessibility text sizes, where the banners and footer move into the scrolling conversation.
    var showsExtras = true
    var onSend: () -> Void
    @State private var sendBounce = 0

    private var canSend: Bool {
        !app.chat.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !app.chat.isResponding && app.chatBlockers.isEmpty
    }

    var body: some View {
        @Bindable var chat = app.chat
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showsExtras {
                StylistChatBlockers()
            } else if !app.chatBlockers.isEmpty {
                // The full banner scrolls with the chat; this line keeps the reason next to Send.
                Label("Chat is paused", systemImage: "exclamationmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Chat is paused. " + app.chatBlockers.map(\.message).joined(separator: " "))
            }
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let look = chat.attachedOutfit {
                    HStack(spacing: Spacing.s) {
                        // A one-line chip at accessibility sizes, so the field keeps its room.
                        if !dynamicTypeSize.isAccessibilitySize {
                            OutfitFlatLayView(pieces: look.pieces, compact: true, animateIn: false)
                                .frame(width: 52, height: 52)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            if !dynamicTypeSize.isAccessibilitySize {
                                Text("About this look")
                                    .font(.caption2)
                                    .foregroundStyle(Palette.secondaryText)
                            }
                            Text(look.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 1 : 2)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("About this look: \(look.title)")
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(Motion.animation(reduceMotion: reduceMotion)) { chat.attachedOutfit = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Palette.secondaryText)
                                .minimumHitTarget()
                        }
                        .accessibilityLabel("Remove attached look")
                    }
                    .transition(.opacity)
                }
                TextField(chat.attachedOutfit == nil ? "Ask about an outfit…" : "Ask about this look…", text: $chat.draftText, axis: .vertical)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 1...2 : 1...5)
                    .font(.body)
                    .focused(focused)
                    .submitLabel(.send)
                    // A multi-line field turns Return into a line break and never calls onSubmit,
                    // so a single typed Return is taken back out and sends instead.
                    .onChange(of: chat.draftText) { old, new in
                        guard new.count == old.count + 1,
                              new.filter(\.isNewline).count > old.filter(\.isNewline).count else { return }
                        chat.draftText = old
                        if canSend { send() }
                    }
                    .accessibilityIdentifier("stylistChatField")
                HStack(spacing: Spacing.xs) {
                    Menu {
                        Picker("Answer mode", selection: $chat.mode) {
                            ForEach(StylistChatMode.allCases) { mode in
                                Label {
                                    Text(mode.title)
                                    Text(mode.detail)
                                } icon: {
                                    Image(systemName: mode.systemImage)
                                }
                                .tag(mode)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: chat.mode.systemImage)
                            Text(chat.mode.title)
                            Image(systemName: "chevron.down").font(.caption2)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .padding(.horizontal, Spacing.s)
                        .frame(minHeight: 34)
                        .background(Capsule().fill(Palette.imageWell))
                        .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
                        .frame(minHeight: HitTarget.minimum)
                        .contentShape(Rectangle())
                    }
                    .disabled(app.workingScope.isSuitcase || app.store.awaitingSourceChoice)
                    .accessibilityLabel("Answer mode: \(chat.mode.title)")
                    .accessibilityHint(app.workingScope.isSuitcase ? "Suitcase styling stays closet only" : chat.mode.detail)
                    .accessibilityIdentifier("stylistChatMode")
                    Spacer()
                    if chat.isResponding {
                        Button { app.stopChat() } label: {
                            Image(systemName: "stop.fill")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(Palette.onPrimaryAction)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Palette.primaryAction))
                                .minimumHitTarget()
                        }
                        .accessibilityLabel("Stop")
                    } else {
                        Button { send() } label: {
                            Image(systemName: "arrow.up")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(Palette.onPrimaryAction)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Palette.primaryAction.opacity(canSend ? 1 : 0.35)))
                                .symbolBounce(on: sendBounce)
                                .minimumHitTarget()
                        }
                        .disabled(!canSend)
                        .keyboardShortcut(.return, modifiers: .command)
                        .accessibilityLabel("Send")
                        .accessibilityIdentifier("stylistChatSend")
                    }
                }
            }
            .padding(Spacing.s)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.surface).shadow(color: .black.opacity(0.08), radius: 12, y: 4))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
            if showsExtras {
                StylistChatFooter()
            }
        }
    }

    private func send() {
        Haptics.lightImpact()
        sendBounce += 1
        onSend()
    }
}

#Preview("Ask your stylist") {
    StylistChatView()
        .previewEnvironment()
}
