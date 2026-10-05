import SwiftUI

/// Shared motion vocabulary. Restrained, quick and always Reduce Motion aware:
/// with Reduce Motion on, movement is replaced by a short cross-fade or no animation.
enum Motion {
    /// Default for state changes inside a card (selection, badges, swaps).
    static let standard: Animation = .snappy(duration: 0.28, extraBounce: 0.02)
    /// Larger layout changes (cards appearing, panes opening).
    static let layout: Animation = .smooth(duration: 0.38)
    /// Tiny feedback (press, toggle).
    static let quick: Animation = .easeOut(duration: 0.16)
    /// Cross-fade used instead of movement when Reduce Motion is on.
    static let reducedFade: Animation = .easeInOut(duration: 0.18)

    /// The animation to use, honoring Reduce Motion.
    static func animation(_ base: Animation = standard, reduceMotion: Bool) -> Animation {
        reduceMotion ? reducedFade : base
    }

    /// Runs a state change with motion that honors Reduce Motion.
    static func perform(reduceMotion: Bool, _ base: Animation = standard, _ body: () -> Void) {
        withAnimation(animation(base, reduceMotion: reduceMotion), body)
    }

    /// Insertion/removal for cards and rows: rise + fade, or fade only.
    static func cardTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 12)).combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity
        )
    }

    /// Replacement of one garment by another in the same slot (swap).
    static func swapTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.92)),
            removal: .opacity.combined(with: .scale(scale: 1.04))
        )
    }
}

// MARK: - Reusable motion modifiers

private struct StaggeredAppear: ViewModifier {
    var index: Int
    var step: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 14)
            .onAppear {
                guard !visible else { return }
                if reduceMotion {
                    withAnimation(Motion.reducedFade) { visible = true }
                } else {
                    withAnimation(Motion.layout.delay(Double(index) * step)) { visible = true }
                }
            }
    }
}

private struct PressFeedbackStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressFeedbackButtonStyle {
    /// Plain button with a subtle press scale (disabled under Reduce Motion).
    static var pressFeedback: PressFeedbackButtonStyle { PressFeedbackButtonStyle() }
}

/// Plain button style with a subtle press response, for tappable cards and tiles.
struct PressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressFeedbackStyle().makeBody(configuration: configuration)
    }
}

extension View {
    /// Fades and rises content in on first appearance; position in a list sets the delay.
    /// With Reduce Motion, a plain short fade.
    func staggeredAppear(index: Int, step: Double = 0.06) -> some View {
        modifier(StaggeredAppear(index: index, step: step))
    }

    /// Bounces an SF Symbol when `value` changes (skipped with Reduce Motion).
    func symbolBounce<V: Equatable>(on value: V) -> some View {
        modifier(SymbolBounceModifier(value: value))
    }
}

private struct SymbolBounceModifier<V: Equatable>: ViewModifier {
    var value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.symbolEffect(.bounce, value: value)
        }
    }
}

// MARK: - Progress indicators

/// Calm "working" indicator for simulated stylist/search work: three dots that
/// breathe in sequence. Static (with text) under Reduce Motion.
struct WorkingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Palette.primaryAction)
                    .frame(width: 8, height: 8)
                    .modifier(DotPulse(index: i, animated: !reduceMotion))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DotPulse: ViewModifier {
    var index: Int
    var animated: Bool

    func body(content: Content) -> some View {
        if animated {
            content.phaseAnimator([0.35, 1.0]) { view, phase in
                view.opacity(phase).scaleEffect(0.8 + 0.2 * phase)
            } animation: { _ in
                .easeInOut(duration: 0.55).delay(Double(index) * 0.18)
            }
        } else {
            content.opacity(0.7)
        }
    }
}

/// Placeholder that gently pulses while a simulated picture is generating.
/// Uses an opacity pulse (no gradients); static under Reduce Motion.
struct PendingPulse: ViewModifier {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content.phaseAnimator([1.0, 0.55]) { view, phase in
                view.opacity(phase)
            } animation: { _ in .easeInOut(duration: 0.9) }
        } else {
            content
        }
    }
}

extension View {
    func pendingPulse(_ active: Bool) -> some View { modifier(PendingPulse(active: active)) }
}

/// Determinate progress ring for image jobs (0...1), with the percentage as text for VoiceOver.
struct ProgressRing: View {
    var progress: Double
    var size: CGFloat = 28
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Palette.divider, lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(0.02, min(progress, 1)))
                .stroke(Palette.primaryAction, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Motion.standard, value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
