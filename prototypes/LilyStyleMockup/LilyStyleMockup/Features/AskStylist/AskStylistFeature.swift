import SwiftUI

/// Ask another stylist UI state, owned by `AppModel` (`app.askStylistUI`).
///
/// The draft prompt, template choices, selected page and rendered pages live
/// here so rotation, Split View resizing or a compact ↔ regular change keeps
/// what she typed. Nothing here calls a service: the prompt comes from a local
/// template and the image is drawn on device.
@Observable
final class AskStylistUIState {
    /// Identifies the look or selection this draft belongs to.
    var targetKey: String?
    /// The editable prompt (without optional personal lines).
    var prompt = ""
    /// The last template output, used to tell whether she edited the prompt.
    var generatedPrompt = ""
    var occasion: Occasion?
    var keepNumber: Int?
    /// Optional personal context. Always starts empty (off).
    var personalFields: Set<AskStylistPersonalField> = []
    var pageIndex = 0
    /// Open details rows and "More" texts, by key, so rotation or a column change keeps them.
    var openDetails: Set<String> = []

    // Rendered contact-sheet pages for the current content.
    var renderedKey: String?
    var renderedPages: [AskStylistRenderedPage] = []

    init() {}

    var promptWasEdited: Bool { prompt != generatedPrompt }

    /// Starts (or resumes) a draft for this content. A different look or
    /// selection gets a fresh template prompt with every personal field off.
    func begin(_ content: AskStylistContent) {
        guard targetKey != content.targetKey else {
            pageIndex = min(pageIndex, content.pageCount - 1)
            return
        }
        targetKey = content.targetKey
        occasion = content.defaultOccasion
        keepNumber = nil
        personalFields = []
        openDetails = []
        pageIndex = 0
        renderedKey = nil
        renderedPages = []
        regenerate(content)
    }

    /// Rebuilds the prompt from the local template, replacing the current text.
    func regenerate(_ content: AskStylistContent) {
        generatedPrompt = AskStylistPromptTemplate.prompt(for: content, occasion: occasion, keep: keepNumber)
        prompt = generatedPrompt
    }

    /// Template inputs changed: refresh the text only if she hasn't edited it.
    func templateInputsChanged(_ content: AskStylistContent) {
        if !promptWasEdited { regenerate(content) }
    }

    /// Draws the contact sheet locally if the content changed.
    @MainActor
    func renderIfNeeded(_ content: AskStylistContent) {
        guard renderedKey != content.renderKey else { return }
        renderedPages = AskStylistRenderer.render(content)
        renderedKey = content.renderKey
        pageIndex = min(pageIndex, max(0, renderedPages.count - 1))
    }

    /// Personal details never carry over to the next time the sheet opens.
    func end() {
        personalFields = []
    }

    /// Open state for one disclosure on the sheet.
    func detailsBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDetails.contains(key) },
            set: { open in
                if open { self.openDetails.insert(key) } else { self.openDetails.remove(key) }
            }
        )
    }

    func isIncluded(_ field: AskStylistPersonalField) -> Bool { personalFields.contains(field) }

    func setIncluded(_ field: AskStylistPersonalField, _ included: Bool) {
        if included { personalFields.insert(field) } else { personalFields.remove(field) }
    }

    func finalText(profile: UserProfile) -> String {
        AskStylistPromptTemplate.finalText(prompt: prompt,
                                           personalLines: AskStylistPromptTemplate.personalLines(personalFields, profile: profile))
    }
}

/// Ask another stylist: a local, optional export of a look or selected pieces
/// as a numbered contact sheet plus an editable prompt. No AI is called by
/// this app; Share, Save and Copy happen only when she taps them.
struct AskStylistView: View {
    var target: AskStylistTarget

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showFileExporter = false

    var body: some View {
        let content = AskStylistContent.make(target: target, store: app.store)
        NavigationStack {
            GeometryReader { geo in
                let twoColumns = geo.size.width >= 760 && !dynamicTypeSize.isAccessibilitySize
                ScrollView {
                    if content.items.isEmpty {
                        EmptyStateView(
                            title: "Nothing to share",
                            message: "These pieces are no longer in your closet. Close this and choose a look or items again.",
                            systemImage: "square.dashed"
                        )
                        .padding(.top, Spacing.xl)
                    } else if twoColumns {
                        HStack(alignment: .top, spacing: Spacing.l) {
                            VStack(spacing: Spacing.m) {
                                AskStylistIntroCard(content: content)
                                AskStylistCollageSection(content: content)
                                AskStylistLeavesDeviceSection(content: content)
                            }
                            .frame(maxWidth: .infinity)
                            VStack(spacing: Spacing.m) {
                                AskStylistPromptSection(content: content)
                                AskStylistPersonalSection()
                                AskStylistActionsSection(content: content, onSaveImage: { showFileExporter = true })
                                AskStylistNotesSection()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(Spacing.m)
                        .frame(maxWidth: 1200)
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: Spacing.m) {
                            AskStylistIntroCard(content: content)
                            AskStylistCollageSection(content: content)
                            AskStylistPromptSection(content: content)
                            AskStylistPersonalSection()
                            AskStylistLeavesDeviceSection(content: content)
                            AskStylistActionsSection(content: content, onSaveImage: { showFileExporter = true })
                            AskStylistNotesSection()
                        }
                        .padding(Spacing.m)
                        .readableWidth(680)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .themedScreenBackground()
            .navigationTitle("Ask another stylist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { app.sheet = nil }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityHint("Closes without sharing anything")
                }
            }

            .fileExporter(
                isPresented: $showFileExporter,
                items: AskStylistExportImage.from(app.askStylistUI.renderedPages),
                contentTypes: [.png],
                onCompletion: { result in
                    switch result {
                    case let .success(urls):
                        let count = urls.count == 1 ? "the image" : "\(urls.count) images"
                        app.showToast("Saved \(count) where you chose. That copy is yours — this app can't remove it later.")
                    case let .failure(error):
                        app.showToast("Couldn't save the image: \(error.localizedDescription)", style: .error)
                    }
                },
                onCancellation: {}
            )
        }
        .onAppear {
            app.askStylistUI.begin(content)
            app.askStylistUI.renderIfNeeded(content)
        }
        .onChange(of: content.renderKey) { _, _ in
            app.askStylistUI.renderIfNeeded(content)
        }
        .onDisappear { app.askStylistUI.end() }
        .modifier(AskStylistSheetSizing())
    }
}

/// Larger page-style sheet on iPad (iOS 18+); full-height sheet on iPhone.
private struct AskStylistSheetSizing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.presentationSizing(.page)
        } else {
            content
        }
    }
}

// MARK: - Previews

#Preview("Saved look") {
    let model = AppModel.preview
    return AskStylistView(target: .outfit(model.store.outfit("o-interview")!))
        .previewEnvironment(model)
}

#Preview("Nine selected pieces — two pages") {
    let model = AppModel.preview
    return AskStylistView(target: .garments(Array(model.store.garments.prefix(9).map(\.id))))
        .previewEnvironment(model)
}
