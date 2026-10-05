import SwiftUI

/// Optional, simulated Sign in with Apple used only for posting and voting.
/// No real Apple ID request is made and nothing leaves the device.
struct FeedbackSignInSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let ui = app.feedbackUI
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.largeTitle)
                        .foregroundStyle(Palette.primaryAction)
                        .accessibilityHidden(true)
                    Text(purposeTitle)
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("Sign in with Apple (simulated) — only for posting and voting. Your closet never needs an account.")
                        .font(.body)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        // Asked here, so what others see stays in full; the rest opens in place.
                        Label {
                            Text("Others see only a generated alias, like \(ui.publicAlias ?? FeedbackUIState.makeAlias(avoiding: Set(app.store.ideas.map(\.publicAlias)))). Never your name, email or Apple ID.")
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "theatermasks")
                                .foregroundStyle(Palette.primaryAction)
                        }
                        .accessibilityElement(children: .combine)
                        DetailsDisclosure(
                            "Votes and deleting the account",
                            count: 2,
                            isExpanded: ui.detailsBinding("signInMore"),
                            identifier: "feedbackSignInDetails"
                        ) {
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                FeedbackFootnote(systemImage: "arrow.uturn.backward",
                                                 text: "One vote per idea, and you can take it back. Votes can't be bought.")
                                FeedbackFootnote(systemImage: "trash",
                                                 text: "Delete this feedback account any time. Your closet stays, and billing isn't affected.")
                            }
                        }
                    }
                    .cardStyle()

                    Button {
                        ui.signIn(store: app.store)
                        dismiss()
                    } label: {
                        Label("Sign in with Apple (simulated)", systemImage: "apple.logo")
                            .font(.headline)
                            .foregroundStyle(Palette.background)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.primaryText))
                            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("feedbackSignIn")
                    .accessibilityHint("Simulated. No Apple ID request is made.")

                    Button("Not now") {
                        ui.cancelSignIn()
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: true))

                    SimulationNotice(text: "Simulated: no Apple ID request is made and nothing leaves this device.", style: .full)
                }
                .padding(Spacing.m)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .themedScreenBackground()
            .navigationTitle("Feedback sign-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        ui.cancelSignIn()
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var purposeTitle: String {
        switch app.feedbackUI.pendingAction {
        case .vote?: "Sign in to vote"
        case .submitIdea?: "Sign in to post your idea"
        case nil: "Sign in to vote or post"
        }
    }
}

#Preview("Sign-in sheet") {
    let model = AppModel.preview
    model.feedbackUI.pendingAction = .vote("i-1")
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            FeedbackSignInSheet()
        }
        .previewEnvironment(model)
}
