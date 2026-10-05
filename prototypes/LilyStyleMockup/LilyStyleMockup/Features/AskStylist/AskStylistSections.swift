import SwiftUI

// MARK: - Intro

/// What this sheet is, and the promise that nothing leaves without a tap.
struct AskStylistIntroCard: View {
    var content: AskStylistContent

    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    heading
                    Spacer(minLength: Spacing.xs)
                    StatusBadge(kind: .demo, compact: true)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    heading
                    StatusBadge(kind: .demo, compact: true)
                }
            }
            CollapsibleText(content.kind == .look
                            ? "Share “\(content.title)” as a numbered picture plus a prompt you can edit, with any AI or stylist you choose."
                            : "Share the pieces you picked as a numbered picture plus a prompt you can edit, with any AI or stylist you choose.",
                            summary: "A numbered picture plus a prompt you can edit.",
                            font: .subheadline, color: Palette.primaryText, topic: "sharing with another stylist",
                            isExpanded: app.askStylistUI.detailsBinding("intro"))
            // The promise stays on screen; how it works is one tap away.
            HStack(alignment: .center, spacing: Spacing.xxs) {
                AskStylistNoteRow(systemImage: "iphone", text: "Nothing leaves until you tap Share, Copy or Save.")
                InfoButton("how this works", title: "How this works") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        InfoText(text: "Prepared on this device. No AI is called by this app, and nothing leaves until you tap Share, Copy or Save.")
                        InfoText(text: app.store.access.plan.hasStylingAccess
                                 ? "Works offline, and keeps working if styling access ends. It doesn't use your styling allowance."
                                 : "Works offline and without styling access. It doesn't use any allowance.")
                    }
                }
            }
            if content.missingSelectionCount > 0 {
                InlineBanner(
                    style: .caution,
                    title: content.missingSelectionCount == 1 ? "1 selected piece was left out" : "\(content.missingSelectionCount) selected pieces were left out",
                    message: "They were deleted after you selected them, so they can't be shared."
                )
            }
        }
        .cardStyle()
    }

    private var heading: some View {
        Text("Take this to another stylist")
            .font(.editorial(.title3))
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Contact sheet

/// The rendered contact sheet exactly as it will be shared, with page controls.
struct AskStylistCollageSection: View {
    var content: AskStylistContent

    @Environment(AppModel.self) private var app
    @State private var viewerPage: AskStylistRenderedPage?

    var body: some View {
        let ui = app.askStylistUI
        let pages = ui.renderedPages
        let index = min(ui.pageIndex, max(0, pages.count - 1))
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Numbered contact sheet",
                          subtitle: content.pageCount > 1
                            ? "\(content.items.count) pieces in \(content.pageCount) readable pages of up to \(AskStylistContent.pageSize)."
                            : "This is the exact image that will be shared.")
            if pages.indices.contains(index) {
                Image(uiImage: pages[index].image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .strokeBorder(Palette.divider, lineWidth: 1)
                    )
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(imageDescription(pageIndex: index))
                    .accessibilityAddTraits(.isImage)
            } else {
                HStack(spacing: Spacing.s) {
                    ProgressView()
                    Text("Drawing the contact sheet on this device…")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            }
            if pages.count > 1 {
                AskStylistPager(pageIndex: index, pageCount: pages.count, rangeLabel: content.pageSubtitle(index))
            }
            if pages.indices.contains(index) {
                Button {
                    viewerPage = pages[index]
                } label: {
                    Label("View larger", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityHint("Opens the contact sheet with zoom")
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("askCollage")
        .sheet(item: $viewerPage) { page in
            AskStylistImageViewer(page: page, pageCount: pages.count)
                .tint(Palette.primaryAction)
        }
    }

    private func imageDescription(pageIndex: Int) -> String {
        let page = content.pages.indices.contains(pageIndex) ? content.pages[pageIndex] : []
        let prefix = content.pageCount > 1 ? "Contact sheet page \(pageIndex + 1) of \(content.pageCount)" : "Contact sheet"
        return prefix + ": " + page.map(\.accessibilitySummary).joined(separator: ". ")
    }
}

/// Zoomable full-size view of one rendered page (pinch or the +/− buttons).
private struct AskStylistImageViewer: View {
    var page: AskStylistRenderedPage
    var pageCount: Int

    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1.5
    @State private var gestureZoom: CGFloat = 1

    private static let zoomRange: ClosedRange<CGFloat> = 1...3

    var body: some View {
        let effective = min(Self.zoomRange.upperBound, max(Self.zoomRange.lowerBound, zoom * gestureZoom))
        let size = CGSize(width: AskStylistCollageCanvas.width * effective,
                          height: AskStylistCollageCanvas.width * effective * page.image.size.height / max(1, page.image.size.width))
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: page.image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .padding(Spacing.m)
                    .accessibilityLabel("Contact sheet\(pageCount > 1 ? ", page \(page.index + 1) of \(pageCount)" : ""), zoomed")
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { gestureZoom = $0.magnification }
                    .onEnded { value in
                        zoom = min(Self.zoomRange.upperBound, max(Self.zoomRange.lowerBound, zoom * value.magnification))
                        gestureZoom = 1
                    }
            )
            .themedScreenBackground()
            .navigationTitle(pageCount > 1 ? "Page \(page.index + 1) of \(pageCount)" : "Contact sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        zoom = max(Self.zoomRange.lowerBound, zoom - 0.5)
                    } label: {
                        Label("Zoom out", systemImage: "minus.magnifyingglass")
                    }
                    .disabled(zoom <= Self.zoomRange.lowerBound)
                    .keyboardShortcut("-", modifiers: .command)
                    Spacer()
                    Text("\(Int((effective * 100).rounded()))%")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityLabel("Zoom \(Int((effective * 100).rounded())) percent")
                    Spacer()
                    Button {
                        zoom = min(Self.zoomRange.upperBound, zoom + 0.5)
                    } label: {
                        Label("Zoom in", systemImage: "plus.magnifyingglass")
                    }
                    .disabled(zoom >= Self.zoomRange.upperBound)
                    .keyboardShortcut("=", modifiers: .command)
                }
            }
        }
    }
}

/// Previous / next page controls for larger selections.
private struct AskStylistPager: View {
    var pageIndex: Int
    var pageCount: Int
    var rangeLabel: String

    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: Spacing.s) {
            Button {
                app.askStylistUI.pageIndex = max(0, pageIndex - 1)
            } label: {
                Label("Previous page", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(pageIndex == 0)
            .keyboardShortcut(.leftArrow, modifiers: [.command])

            VStack(spacing: 2) {
                Text("Page \(pageIndex + 1) of \(pageCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text(rangeLabel)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Button {
                app.askStylistUI.pageIndex = min(pageCount - 1, pageIndex + 1)
            } label: {
                Label("Next page", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(pageIndex >= pageCount - 1)
            .keyboardShortcut(.rightArrow, modifiers: [.command])
        }
    }
}

// MARK: - Prompt

/// Editable prompt prepared locally from a template, with template choices.
struct AskStylistPromptSection: View {
    var content: AskStylistContent

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var confirmRegenerate = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        @Bindable var ui = app.askStylistUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Prompt", info: "Prepared here from a template. Edit it however you like.")
            FlowLayout(spacing: Spacing.xs) {
                occasionMenu
                keepMenu
            }
            if ui.promptWasEdited {
                CollapsibleText("You've edited the prompt, so occasion and kept-piece changes apply when you regenerate.",
                                summary: "Edited, so menu changes wait for Regenerate.",
                                threshold: 1, topic: "your edited prompt", isExpanded: ui.detailsBinding("promptEdited"))
            }
            TextEditor(text: $ui.prompt)
                .focused($editorFocused)
                .font(.body)
                .foregroundStyle(Palette.primaryText)
                .scrollContentBackground(.hidden)
                .padding(Spacing.xs)
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 280 : 168)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                        .strokeBorder(editorFocused ? Palette.primaryAction : Palette.controlBorder, lineWidth: editorFocused ? 2 : 1)
                )
                .accessibilityLabel("Prompt")
                .accessibilityHint("Editable. It's shared with the image only when you tap Share or Copy Prompt.")
                .accessibilityIdentifier("askPromptEditor")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    status
                    Spacer(minLength: Spacing.xs)
                    regenerateButton
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    status
                    regenerateButton
                }
            }
        }
        .cardStyle()
        .confirmationDialog("Replace your edited prompt?", isPresented: $confirmRegenerate, titleVisibility: .visible) {
            Button("Replace with template", role: .destructive) { ui.regenerate(content) }
            Button("Keep my text", role: .cancel) {}
        } message: {
            Text("The template is rebuilt on this device. Your edits will be replaced.")
        }
    }

    private var status: some View {
        let ui = app.askStylistUI
        return Label(ui.promptWasEdited ? "Edited by you · \(ui.prompt.count) characters" : "From template · \(ui.prompt.count) characters",
                     systemImage: ui.promptWasEdited ? "pencil" : "doc.plaintext")
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
    }

    private var regenerateButton: some View {
        Button {
            if app.askStylistUI.promptWasEdited {
                confirmRegenerate = true
            } else {
                app.askStylistUI.regenerate(content)
            }
        } label: {
            Label("Regenerate from template", systemImage: "arrow.clockwise")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint("Rebuilds the prompt locally. No AI is used.")
    }

    private var occasionMenu: some View {
        let ui = app.askStylistUI
        return Menu {
            Picker("Occasion", selection: Binding(
                get: { ui.occasion },
                set: { ui.occasion = $0; ui.templateInputsChanged(content) }
            )) {
                Label("Everyday", systemImage: "sun.max").tag(Occasion?.none)
                ForEach(Occasion.allCases) { occasion in
                    Label(occasion.label, systemImage: occasion.systemImage).tag(Occasion?.some(occasion))
                }
            }
        } label: {
            AskStylistMenuChip(title: "Occasion", value: ui.occasion?.label ?? "Everyday", systemImage: ui.occasion?.systemImage ?? "sun.max")
        }
        .accessibilityLabel("Occasion for the prompt: \(ui.occasion?.label ?? "Everyday")")
    }

    private var keepMenu: some View {
        let ui = app.askStylistUI
        return Menu {
            Picker("Keep a piece", selection: Binding(
                get: { ui.keepNumber },
                set: { ui.keepNumber = $0; ui.templateInputsChanged(content) }
            )) {
                Text("No piece to keep").tag(Int?.none)
                ForEach(content.items) { item in
                    Text("#\(item.number) \(item.name)").tag(Int?.some(item.number))
                }
            }
        } label: {
            AskStylistMenuChip(title: "Keep", value: ui.keepNumber.map { "#\($0)" } ?? "None", systemImage: "pin")
        }
        .accessibilityLabel("Piece to keep: \(ui.keepNumber.map { "number \($0)" } ?? "none")")
    }
}

/// Capsule menu label in the style of the app's source selector.
private struct AskStylistMenuChip: View {
    var title: String
    var value: String
    var systemImage: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the label wraps, so a rounded rectangle replaces the capsule.
        let shape = RoundedRectangle(cornerRadius: dynamicTypeSize.isAccessibilitySize ? Radius.tile : 999, style: .continuous)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
            (Text(title + " ").foregroundStyle(Palette.secondaryText)
                + Text(value).fontWeight(.semibold).foregroundStyle(Palette.primaryText))
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .font(.subheadline)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: HitTarget.minimum)
        .background(shape.fill(Palette.surface))
        .overlay(shape.strokeBorder(Palette.controlBorder, lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.highlight)
    }
}

// MARK: - Personal details

/// Optional personal fields, each off by default and added only when chosen.
struct AskStylistPersonalSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.askStylistUI
        let profile = app.store.profile
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Add personal details?", subtitle: "All off unless you turn one on.",
                          info: "All off unless you turn one on. Each one you choose is added at the end of the prompt.")
            ForEach(AskStylistPersonalField.allCases) { field in
                let value = field.value(in: profile)
                Toggle(isOn: Binding(get: { ui.isIncluded(field) }, set: { ui.setIncluded(field, $0) })) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(field.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                            Text(value ?? field.emptyText(in: profile))
                                .font(.footnote)
                                .italic(value == nil)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } icon: {
                        Image(systemName: field.systemImage)
                            .foregroundStyle(Palette.primaryAction)
                    }
                }
                .tint(Palette.primaryAction)
                .disabled(value == nil)
                .frame(minHeight: HitTarget.minimum)
                .accessibilityIdentifier("askPersonalToggle-\(field.rawValue)")
                .accessibilityHint(value == nil ? field.emptyText(in: profile) : "Adds this line to the shared prompt")
                if field != AskStylistPersonalField.allCases.last {
                    Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)
                }
            }
            DetailsDisclosure("Never added", summary: "name, location and more", systemImage: "hand.raised",
                              isExpanded: ui.detailsBinding("neverAdded")) {
                Text("Your name, location, your weight, measurement numbers other than height (including your inseam), product links, and the rest of your closet.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Spacing.xs)
            }
            .padding(.horizontal, Spacing.s)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell))
        }
        .cardStyle()
    }
}

// MARK: - Exact-content preview

/// Exact preview of the image summary and the final prompt text that would be shared.
struct AskStylistLeavesDeviceSection: View {
    var content: AskStylistContent

    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.askStylistUI
        let pages = ui.renderedPages
        let text = ui.finalText(profile: app.store.profile)
        let included = AskStylistPersonalField.allCases.filter { ui.isIncluded($0) }
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("What will leave your device",
                          subtitle: "Only after you tap Share, Copy or Save.",
                          info: "Exactly this, and only after you tap Share, Copy or Save. You choose where it goes.")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(pages.count > 1 ? "\(pages.count) images (PNG)" : "1 image (PNG)", systemImage: "photo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                if !pages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(pages) { page in
                                Image(uiImage: page.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 132)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    DetailsDisclosure("The image shows",
                                      summary: content.items.count == 1 ? "1 piece" : "\(content.items.count) pieces",
                                      isExpanded: ui.detailsBinding("imageShows"), identifier: "askImageShows") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if !pages.isEmpty {
                                Text(pixelSummary(pages))
                                    .font(.footnote)
                                    .foregroundStyle(Palette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            ForEach(content.items) { item in
                                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                                    AskStylistNumberBadge(number: item.number)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Palette.primaryText)
                                        Text(item.summaryLine)
                                            .font(.footnote)
                                            .foregroundStyle(Palette.secondaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(item.accessibilitySummary)
                            }
                        }
                    }
                    DetailsDisclosure("Also handed over by Share", summary: pages.count > 1 ? "subject, file names" : "subject, file name",
                                      isExpanded: ui.detailsBinding("alsoShared"), identifier: "askAlsoShared") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            InfoRow(title: "Subject (apps that use one)", value: content.title)
                            InfoRow(title: pages.count > 1 ? "File names" : "File name",
                                    value: AskStylistExportImage.from(pages).map(\.filename).joined(separator: "\n"))
                        }
                    }
                }
            }

            Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Prompt text", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                // The exact text that would leave the device shows in full; only an unusually long prompt folds.
                CollapsibleText(text.isEmpty ? "No prompt — only the image would be shared." : text,
                                collapsedLines: 8, threshold: 10, font: text.isEmpty ? .callout.italic() : .callout,
                                color: Palette.primaryText, topic: "the prompt text that will be shared",
                                isExpanded: ui.detailsBinding("promptPreview"))
                    .textSelection(.enabled)
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Prompt text that will be shared")
                Text(included.isEmpty
                     ? "No personal details included."
                     : "Personal details you chose: \(included.map(\.title).joined(separator: ", ")).")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }

            Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                // Where it goes stays on screen at the moment she decides.
                HStack(alignment: .center, spacing: Spacing.xxs) {
                    AskStylistNoteRow(systemImage: "arrow.up.forward.app", text: "Goes to the app or place you pick.")
                    InfoButton("where it goes", title: "Where it goes",
                               text: "Goes to: the app or place you pick in the share sheet or Files, or your clipboard when you tap Copy.")
                }
                DetailsDisclosure("What's not included", summary: "name, location and more", systemImage: "eye.slash",
                                  isExpanded: ui.detailsBinding("notIncluded"), identifier: "askNotIncluded") {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        AskStylistNoteRow(systemImage: "checkmark.shield", text: rightsSummary)
                        AskStylistNoteRow(systemImage: "eye.slash",
                                          text: "Not included: your name, location, your weight, other measurement numbers, product links, the rest of your closet, photo location data.")
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("askLeavesDevicePreview")
    }

    private func pixelSummary(_ pages: [AskStylistRenderedPage]) -> String {
        let sizes = pages.map { "\($0.pixelWidth) × \($0.pixelHeight)" }
        let unique = Array(Set(sizes))
        let sizeText = unique.count == 1 ? "\(unique[0]) pixels" : "\(pages.first?.pixelWidth ?? 0) pixels wide"
        return "\(sizeText) · drawn fresh on this device, so there's no camera, time or location data in it."
    }

    private var rightsSummary: String {
        let photos = content.items.filter(\.isPhoto).count
        let drawn = content.items.count - photos
        var parts: [String] = []
        if drawn > 0 { parts.append(drawn == 1 ? "1 app-made illustration" : "\(drawn) app-made illustrations") }
        if photos > 0 { parts.append(photos == 1 ? "1 of your photos (a demo stand-in)" : "\(photos) of your photos (demo stand-ins)") }
        return "Pictures: \(parts.joined(separator: " and ")). No store or catalog photos are included."
    }
}

// MARK: - Actions

/// Explicit Share / Copy / Save controls plus the manual fallback.
struct AskStylistActionsSection: View {
    var content: AskStylistContent
    var onSaveImage: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.askStylistUI
        let pages = ui.renderedPages
        let text = ui.finalText(profile: app.store.profile)
        let exports = AskStylistExportImage.from(pages)
        let index = min(ui.pageIndex, max(0, pages.count - 1))
        let ready = !pages.isEmpty
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Share, save or copy", info: "Nothing happens until you tap. This app never reads or fills your clipboard on its own.")

            ShareLink(
                items: exports,
                subject: Text(content.title),
                message: Text(text),
                preview: { item in
                    SharePreview(item.filename, image: Image(uiImage: pages.first { $0.index == item.pageIndex }?.image ?? UIImage()))
                },
                label: {
                    Label(pages.count > 1 ? "Share \(pages.count) images + prompt" : "Share image + prompt", systemImage: "square.and.arrow.up")
                }
            )
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!ready)
            .accessibilityIdentifier("askShare")
            .accessibilityHint("Opens the share sheet. Nothing is sent until you pick an app there.")

            // Share, then one more button and a menu: the group never takes more than two rows.
            ActionGroup(moreIdentifier: "askMoreActions") {
                Button {
                    UIPasteboard.general.string = text
                    app.showToast("Prompt copied. Paste it into the app you choose — nothing was sent.")
                } label: {
                    Label("Copy Prompt", systemImage: "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .disabled(text.isEmpty)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .accessibilityIdentifier("askCopyPrompt")
            } more: {
                Button {
                    guard pages.indices.contains(index) else { return }
                    UIPasteboard.general.image = pages[index].image
                    app.showToast(pages.count > 1
                                  ? "Page \(index + 1) image copied. Paste it where you like — nothing was sent."
                                  : "Image copied. Paste it where you like — nothing was sent.")
                } label: {
                    Label(pages.count > 1 ? "Copy Image (page \(index + 1))" : "Copy Image", systemImage: "photo.on.rectangle")
                }
                .disabled(!ready)
                .accessibilityIdentifier("askCopyImage")

                Button(action: onSaveImage) {
                    Label(pages.count > 1 ? "Save \(pages.count) Images to Files" : "Save Image to Files", systemImage: "square.and.arrow.down")
                }
                .disabled(!ready)
                .accessibilityIdentifier("askSaveImage")
                .accessibilityHint("Choose a folder in Files. Share also offers Save Image.")
            }
            // Keeps Command-S working now that Save lives in the More menu.
            .background {
                Button("Save Image to Files", action: onSaveImage)
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!ready)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }

            DetailsDisclosure("If the app doesn't take both", systemImage: "info.circle",
                              isExpanded: ui.detailsBinding("fallbackSteps"), identifier: "askFallbackSteps") {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("If the app you pick doesn't accept both, save the image, upload it there, then paste the prompt.")
                        .font(.footnote)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    AskStylistStep(number: 1, text: "Tap More, then Save Image to Files (or Copy Image).")
                    AskStylistStep(number: 2, text: "Upload the image in the other app.")
                    AskStylistStep(number: 3, text: "Tap Copy Prompt here, then paste it there.")
                }
                .padding(.bottom, Spacing.xs)
            }
            .padding(.horizontal, Spacing.s)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
        }
        .cardStyle()
    }
}

private struct AskStylistStep: View {
    var number: Int
    var text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text("\(number).")
                .font(.footnote.weight(.bold).monospacedDigit())
                .foregroundStyle(Palette.primaryAction)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Notes

/// Honest notes about the receiving service and what this app can't do.
struct AskStylistNotesSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        DetailsDisclosure("Good to know", summary: "can't be recalled", systemImage: "lightbulb",
                          isExpanded: app.askStylistUI.detailsBinding("goodToKnow"), identifier: "askGoodToKnow") {
            VStack(alignment: .leading, spacing: Spacing.s) {
                AskStylistNoteRow(systemImage: "doc.text.magnifyingglass",
                                  text: "The receiving service's terms and plan apply. Its answer can't change your closet automatically.")
                AskStylistNoteRow(systemImage: "arrow.uturn.backward.circle",
                                  text: "Once you pick an app, it may already have the content even if you cancel there. Copies you share or save can't be recalled from this app.")
                AskStylistNoteRow(systemImage: "square.and.pencil",
                                  text: "Like a suggestion? Rebuild it yourself in Saved Looks with your real pieces. The other stylist doesn't know what's clean, packed or still yours.")
            }
            .padding(.bottom, Spacing.xs)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xxs)
        .cardStyle(padding: 0)
    }
}

/// Icon + footnote row used for short notes.
struct AskStylistNoteRow: View {
    var systemImage: String
    var text: String

    var body: some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
        }
        .accessibilityElement(children: .combine)
    }
}
