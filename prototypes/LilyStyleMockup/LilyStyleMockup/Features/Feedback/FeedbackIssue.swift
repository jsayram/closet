import SwiftUI

/// Private issue form: category, message, optional ticket-only reply email and
/// an explicit diagnostics choice with an exact preview. Never public.
struct FeedbackIssueSection: View {
    var width: WidthClass

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let ui = app.feedbackUI
        let twoColumns = width != .compact && !dynamicTypeSize.isAccessibilitySize
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Private issue", subtitle: "Private to support. No account needed.",
                          info: "Goes privately to support — never to the public board. No account needed.")
            if let id = ui.lastSubmittedIssueID, let report = app.store.issueReports.first(where: { $0.id == id }) {
                FeedbackIssueConfirmation(report: report)
            } else if twoColumns {
                HStack(alignment: .top, spacing: Spacing.m) {
                    FeedbackIssueForm()
                        .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        FeedbackDiagnosticsPreview()
                        FeedbackIssueRecipient()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                FeedbackIssueForm()
                FeedbackDiagnosticsPreview()
                FeedbackIssueRecipient()
            }
            if ui.lastSubmittedIssueID == nil {
                FeedbackIssueSubmit()
            }
            FeedbackPastReports()
            FeedbackFootnote(systemImage: "envelope",
                             text: "Urgent billing, privacy or security problem? Write to support@example.com (sample address). No account needed.",
                             summary: "Urgent? Write to support@example.com (sample address).")
        }
    }
}

// MARK: - Form

private struct FeedbackIssueForm: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var focus: Field?

    private enum Field { case message, email }

    var body: some View {
        @Bindable var ui = app.feedbackUI
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Category")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Picker("Category", selection: $ui.issueCategory) {
                    ForEach(IssueCategory.allCases) { category in
                        Label(category.label, systemImage: category.feedbackSymbol).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight: HitTarget.minimum)
                .padding(.horizontal, Spacing.xs)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                .accessibilityIdentifier("issueCategory")
                CollapsibleText(ui.issueCategory.feedbackHint, topic: ui.issueCategory.label)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("What happened?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Spacer()
                    Text("\(ui.issueMessage.count) / \(FeedbackUIState.issueLimit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(ui.issueMessage.count > FeedbackUIState.issueLimit - 50 ? Palette.error : Palette.secondaryText)
                        .accessibilityLabel("\(ui.issueMessage.count) of \(FeedbackUIState.issueLimit) characters used")
                }
                TextEditor(text: $ui.issueMessage)
                    .focused($focus, equals: .message)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.xs)
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 240 : 140)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(border(focused: focus == .message))
                    .accessibilityLabel("Describe the issue")
                    .accessibilityHint("Private. Only support sees it.")
                    .accessibilityIdentifier("issueMessage")
                    .onChange(of: ui.issueMessage) { _, newValue in
                        if newValue.count > FeedbackUIState.issueLimit {
                            ui.issueMessage = String(newValue.prefix(FeedbackUIState.issueLimit))
                        }
                    }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Reply email (optional)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                TextField("name@example.com", text: $ui.issueReplyEmail)
                    .focused($focus, equals: .email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: HitTarget.minimum)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(border(focused: focus == .email))
                    .accessibilityLabel("Reply email, optional")
                if ui.issueEmailIsValid {
                    // What the address is used for stays beside the field she types it in.
                    CollapsibleText(
                        "Used only to reply to this report. It isn't added to any list or linked to a feedback account.",
                        summary: "Used only to reply to this report.",
                        threshold: 1,
                        topic: "your reply email"
                    )
                } else {
                    Text("That doesn't look like an email address. Fix it or leave it blank.")
                        .font(.footnote)
                        .foregroundStyle(Palette.error)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: $ui.issueIncludeDiagnostics) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include diagnostics")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Text("Off unless you turn it on. See exactly what's added.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .tint(Palette.primaryAction)
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("issueDiagnosticsToggle")
        }
        .cardStyle()
    }

    private func border(focused: Bool) -> some View {
        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .strokeBorder(focused ? Palette.primaryAction : Palette.controlBorder, lineWidth: focused ? 2 : 1)
    }
}

// MARK: - Diagnostics preview

/// Exact diagnostics lines, shown whether or not they're included.
private struct FeedbackDiagnosticsPreview: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        let lines = FeedbackDiagnostics.lines(category: ui.issueCategory, reference: ui.issueReference, store: app.store)
        VStack(alignment: .leading, spacing: Spacing.s) {
            let badge = StatusBadge(kind: ui.issueIncludeDiagnostics ? .custom("Included", "checkmark.circle") : .custom("Not included", "minus.circle"),
                                    compact: true)
            let title = Text("Diagnostics")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer(minLength: Spacing.xs)
                    badge
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    title
                    badge
                }
            }
            if ui.issueIncludeDiagnostics {
                // Turned on: the exact lines stay in view until she sends.
                Text("Exactly these lines are added:")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                diagnosticLines(lines)
            } else {
                DetailsDisclosure(
                    "What would be added",
                    count: lines.count,
                    isExpanded: ui.detailsBinding("issueDiagnostics"),
                    identifier: "issueDiagnosticsDetails"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("If you turn diagnostics on, exactly these lines are added:")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        diagnosticLines(lines)
                            .opacity(0.7)
                    }
                }
            }
            Label("Never included: your closet, photos, measurements, outfits, prompts, product links or name.",
                  systemImage: "eye.slash")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}

private extension FeedbackDiagnosticsPreview {
    func diagnosticLines(_ lines: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            ForEach(lines, id: \.0) { line in
                InfoRow(title: line.0, value: line.1)
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
    }
}

/// Who receives the report and what's in it.
private struct FeedbackIssueRecipient: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        let email = ui.issueReplyEmail.trimmingCharacters(in: .whitespaces)
        var fields = ["Category", "Your message"]
        if !email.isEmpty { fields.append("Reply email") }
        if ui.issueIncludeDiagnostics { fields.append("Diagnostics") }
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            InfoRow(title: "Goes to", value: "My Petite Style support (private queue, simulated)")
            InfoRow(title: "Includes", value: fields.joined(separator: ", "))
            InfoRow(title: "Public?", value: "Never — not on the board, in search or notifications")
        }
        .cardStyle()
    }
}

// MARK: - Submit and confirmation

private struct FeedbackIssueSubmit: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        let todayCount = ui.issuesSubmittedToday(app.store)
        let limitReached = todayCount >= FeedbackUIState.dailyIssueLimit
        VStack(alignment: .leading, spacing: Spacing.s) {
            if limitReached {
                InlineBanner(
                    style: .caution,
                    title: "Daily limit reached",
                    message: "You've sent \(todayCount) private reports in the last day (sample limit \(FeedbackUIState.dailyIssueLimit)). Your draft is kept. For an urgent billing, privacy or security problem, use the support address below."
                )
            }
            Button {
                ui.submitIssue(store: app.store)
            } label: {
                Label("Send privately (simulated)", systemImage: "lock")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!ui.canSubmitIssue || limitReached)
            .accessibilityIdentifier("issueSubmit")
            .accessibilityHint("Saves the report on this device. Nothing is sent in the demo.")
            if !ui.canSubmitIssue {
                Text(ui.issueMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "Describe what happened to send the report."
                     : "Fix the reply email, or leave it blank, to send the report.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SimulationNotice(text: "Simulated: the report is saved on this device only. In the real app it goes privately to support.",
                             summary: "Saved on this device only.")
        }
    }
}

private struct FeedbackIssueConfirmation: View {
    var report: PrivateIssueReport

    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            InlineBanner(
                style: .success,
                title: "Saved locally — in the real app this goes privately to support (simulated)",
                message: "Nothing was sent. \(report.replyEmail == nil ? "No reply email was given." : "A reply would go only to the email you gave, for this report.") \(report.includeDiagnostics ? "Diagnostics were included." : "No diagnostics were included.")"
            )
            InfoRow(title: "Category", value: report.category.label)
            InfoRow(title: "Saved", value: report.submittedAt.formatted(date: .abbreviated, time: .shortened))
            Button {
                app.feedbackUI.lastSubmittedIssueID = nil
            } label: {
                Label("Write another report", systemImage: "square.and.pencil")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: "Report saved locally. Simulated, nothing was sent.")
        }
    }
}

/// Reports saved on this device (private; never shown publicly).
private struct FeedbackPastReports: View {
    @Environment(AppModel.self) private var app
    @State private var expanded = false

    var body: some View {
        let reports = app.store.issueReports.sorted { $0.submittedAt > $1.submittedAt }
        if !reports.isEmpty {
            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(reports) { report in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(report.category.label, systemImage: report.category.feedbackSymbol)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                            Text(report.message)
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .lineLimit(2)
                            Text(report.submittedAt, format: .relative(presentation: .named))
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.top, Spacing.xs)
            } label: {
                Label(reports.count == 1 ? "1 private report on this device" : "\(reports.count) private reports on this device",
                      systemImage: "lock.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .frame(minHeight: HitTarget.minimum)
            }
            .tint(Palette.primaryAction)
            .cardStyle()
        }
    }
}

// MARK: - Diagnostics content

/// Content-free diagnostics: app/OS version, device family, error category and
/// an opaque reference. Built only for the preview and an explicit submit.
@MainActor
enum FeedbackDiagnostics {
    static func lines(category: IssueCategory, reference: String, store: DemoStore) -> [(String, String)] {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1"
        let device = UIDevice.current
        let family = device.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let errorCategory = store.lastSaveError == nil ? "None recorded" : "Local save failed"
        return [
            ("App version", "\(version) (prototype)"),
            ("System", "\(device.systemName) \(device.systemVersion)"),
            ("Device type", family),
            ("Report type", category.label),
            ("Error category", errorCategory),
            ("Error reference", reference),
        ]
    }
}
