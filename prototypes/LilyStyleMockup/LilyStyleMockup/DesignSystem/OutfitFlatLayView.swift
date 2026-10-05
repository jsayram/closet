import SwiftUI

/// Flat-lay outfit composition: garments placed where they're worn on a soft
/// neutral canvas, the way leading wardrobe apps present a look (one image, not a
/// grid of captions). Each piece can be a tappable, labelled control; pieces
/// "settle" in with a short stagger, or simply fade in with Reduce Motion.
struct OutfitFlatLayView: View {
    var pieces: [OutfitPiece]
    var selectedSlot: OutfitSlot?
    /// Current-status badges per piece (resolved by the caller from canonical records).
    var statusFor: ((OutfitPiece) -> [BadgeKind])?
    var onTap: ((OutfitPiece) -> Void)?
    /// Compact thumbnails hide per-piece badges and use a tighter canvas.
    var compact = false
    var animateIn = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    private struct Placement {
        var center: CGPoint   // unit coordinates
        var size: CGSize      // unit size
        var z: Double
    }

    private var hasDress: Bool { pieces.contains { $0.slot == .dress } }
    private var hasLayer: Bool { pieces.contains { $0.slot == .layer } }

    /// Two-column flat-lay: clothes on the left (worn order, top to bottom),
    /// smaller pieces (bag, shoes) on the right, like a styled flat-lay photo.
    private func placement(for slot: OutfitSlot) -> Placement {
        switch slot {
        case .dress:
            return Placement(center: CGPoint(x: 0.33, y: 0.47), size: CGSize(width: 0.54, height: 0.84), z: 1)
        case .layer:
            return hasDress
                ? Placement(center: CGPoint(x: 0.75, y: 0.27), size: CGSize(width: 0.42, height: 0.42), z: 2)
                : Placement(center: CGPoint(x: 0.27, y: 0.25), size: CGSize(width: 0.46, height: 0.44), z: 1)
        case .top:
            return hasLayer
                ? Placement(center: CGPoint(x: 0.72, y: 0.24), size: CGSize(width: 0.42, height: 0.40), z: 2)
                : Placement(center: CGPoint(x: 0.30, y: 0.25), size: CGSize(width: 0.48, height: 0.44), z: 2)
        case .bottom:
            return Placement(center: CGPoint(x: 0.31, y: 0.71), size: CGSize(width: 0.46, height: 0.52), z: 0)
        case .accessory:
            return hasLayer || hasDress
                ? Placement(center: CGPoint(x: 0.76, y: 0.53), size: CGSize(width: 0.28, height: 0.22), z: 3)
                : Placement(center: CGPoint(x: 0.75, y: 0.27), size: CGSize(width: 0.34, height: 0.30), z: 3)
        case .shoes:
            return Placement(center: CGPoint(x: 0.73, y: 0.80), size: CGSize(width: 0.42, height: 0.24), z: 3)
        }
    }

    private var ordered: [OutfitPiece] {
        pieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.imageWell)
                ForEach(Array(ordered.enumerated()), id: \.element.id) { index, piece in
                    placedPiece(piece, index: index, canvas: CGSize(width: w, height: h))
                }
                if pieces.isEmpty {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "hanger")
                            .font(.title)
                            .foregroundStyle(Palette.secondaryText)
                        Text("No pieces yet")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
        }
        .aspectRatio(compact ? 1 : 0.86, contentMode: .fit)
        .animation(Motion.animation(Motion.standard, reduceMotion: reduceMotion), value: pieceKeys)
        .onChange(of: pieceKeys) { old, new in
            if isInteractive && old.count == new.count && old != new { Haptics.selection() }
        }
        .onAppear {
            guard !settled else { return }
            if reduceMotion || !animateIn {
                withAnimation(reduceMotion ? Motion.reducedFade : nil) { settled = true }
            } else {
                withAnimation(Motion.layout) { settled = true }
            }
        }
        .accessibilityElement(children: isInteractive ? .contain : .ignore)
        .accessibilityLabel(summaryLabel)
    }

    private var isInteractive: Bool { onTap != nil }

    /// Identity of each placed garment; changes when a piece is swapped.
    private var pieceKeys: [String] {
        pieces.map { $0.garmentID ?? $0.capturedName }
    }

    private var summaryLabel: String {
        guard !isInteractive else { return "Outfit pieces" }
        let names: [String] = ordered.map { piece in
            let color = piece.capturedColor?.name ?? "color unknown"
            return "\(piece.capturedName), \(color)"
        }
        return "Outfit: " + names.joined(separator: "; ")
    }

    /// Positions one piece on the canvas. A swapped garment gets a new identity,
    /// so it cross-fades/scales in (fade only with Reduce Motion).
    private func placedPiece(_ piece: OutfitPiece, index: Int, canvas: CGSize) -> some View {
        let p = placement(for: piece.slot)
        let key: String = piece.garmentID ?? piece.capturedName
        let transition: AnyTransition = Motion.swapTransition(reduceMotion: reduceMotion)
        return pieceView(piece, index: index)
            .id(key)
            .transition(transition)
            .frame(width: p.size.width * canvas.width, height: p.size.height * canvas.height)
            .position(x: p.center.x * canvas.width, y: p.center.y * canvas.height)
            .zIndex(p.z)
    }

    /// Shoes read better as a pair; everything else is a single garment.
    @ViewBuilder
    private func pieceArt(_ piece: OutfitPiece) -> some View {
        if piece.slot == .shoes {
            HStack(spacing: -6) {
                GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex, showsWell: false)
                    .scaleEffect(x: -1)
                GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex, showsWell: false)
                    .offset(y: 4)
            }
        } else {
            GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex, showsWell: false)
        }
    }

    @ViewBuilder
    private func pieceView(_ piece: OutfitPiece, index: Int) -> some View {
        let isSelected = piece.slot == selectedSlot
        let badges = (statusFor?(piece) ?? []) + (piece.isHypothetical ? [.unowned] : [])
        let art = pieceArt(piece)
            .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
            .padding(compact ? 1 : 4)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(isSelected ? Palette.primaryAction : .clear, lineWidth: 2.5)
            )
            .overlay(alignment: .topTrailing) {
                if !compact, let first = badges.first {
                    Image(systemName: first.systemImage)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(first.tone == .error ? Palette.error : Palette.primaryAction)
                        .padding(4)
                        .background(Circle().fill(Palette.surface))
                        .overlay(Circle().strokeBorder(Palette.controlBorder, lineWidth: 0.5))
                        .accessibilityHidden(true)
                }
            }
            .opacity(settled ? 1 : 0)
            .scaleEffect(settled || reduceMotion ? 1 : 0.88)
            .offset(y: settled || reduceMotion ? 0 : -10)
            .animation(reduceMotion ? Motion.reducedFade : Motion.layout.delay(animateIn ? Double(index) * 0.06 : 0), value: settled)
            .animation(Motion.animation(Motion.standard, reduceMotion: reduceMotion), value: isSelected)

        if let onTap {
            Button { onTap(piece) } label: { art.contentShape(Rectangle()) }
                .buttonStyle(.pressFeedback)
                .hoverEffect(.lift)
                .accessibilityLabel("\(piece.slot.label): \(piece.capturedName), \(piece.capturedColor?.name ?? "color unknown")")
                .accessibilityValue(((isSelected ? ["Selected"] : []) + badges.map(\.text)).joined(separator: ", "))
                .accessibilityHint("Opens swap options for this piece")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("pieceTile-\(piece.slot.rawValue)")
        } else {
            art.accessibilityHidden(true)
        }
    }
}

/// Compact, wrapping list of an outfit's pieces as labelled chips with status —
/// the accessible companion to the flat-lay (names, colors and badges in text).
/// Tappable chips always sit under a tappable flat-lay, so VoiceOver reads each
/// piece once, from the flat-lay; the chips stay for touch and large text.
struct OutfitPieceChips: View {
    var pieces: [OutfitPiece]
    var selectedSlot: OutfitSlot?
    var statusFor: ((OutfitPiece) -> [BadgeKind])?
    var onTap: ((OutfitPiece) -> Void)?
    /// Lays the chips out in one sideways-scrolling row that can be expanded,
    /// instead of wrapping.
    var scrolls = false

    var body: some View {
        if scrolls {
            ChipCarousel(itemsLabel: "pieces") { chips }
        } else {
            FlowLayout(spacing: Spacing.xs) { chips }
        }
    }

    private var chips: some View {
        ForEach(pieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }) { piece in
            chip(piece)
        }
    }

    @ViewBuilder
    private func chip(_ piece: OutfitPiece) -> some View {
        let badges = (statusFor?(piece) ?? []) + (piece.isHypothetical ? [.unowned] : [])
        let isSelected = piece.slot == selectedSlot
        let label = HStack(spacing: Spacing.xxs + 2) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.primaryAction)
            }
            ColorSwatch(hex: piece.capturedColor?.hex ?? GarmentArtwork.unknownHex, size: 12)
            Text(piece.capturedName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .lineLimit(2)
            if let badge = badges.first {
                Image(systemName: badge.systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(badge.tone == .error ? Palette.error : Palette.primaryAction)
            }
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, 6)
        .frame(minHeight: 36)
        .background(Capsule().fill(isSelected ? Palette.accentSurface : Palette.surface))
        .overlay(Capsule().strokeBorder(isSelected ? Palette.primaryAction : (onTap == nil ? Palette.controlBorder.opacity(0.6) : Palette.controlBorder),
                                         lineWidth: isSelected ? 2 : 1))

        if let onTap {
            Button { onTap(piece) } label: {
                label
                    .frame(minHeight: HitTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressFeedback)
            .accessibilityLabel("\(piece.slot.label): \(piece.capturedName), \(piece.capturedColor?.name ?? "color unknown")")
            .accessibilityValue(((isSelected ? ["Selected"] : []) + badges.map(\.text)).joined(separator: ", "))
            .accessibilityHint("Opens swap options for this piece")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("pieceChip-\(piece.slot.rawValue)")
            .accessibilityHidden(true)
        } else {
            label
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(piece.slot.label): \(piece.capturedName), \(piece.capturedColor?.name ?? "color unknown")")
                .accessibilityValue(badges.map(\.text).joined(separator: ", "))
        }
    }
}

#Preview("Flat-lay") {
    let store = DemoStore(snapshot: DemoFixtures.snapshot())
    let outfit = store.outfit("o-interview")!
    return ScrollView {
        VStack(spacing: Spacing.m) {
            OutfitFlatLayView(pieces: outfit.pieces, selectedSlot: .top, onTap: { _ in })
            OutfitPieceChips(pieces: outfit.pieces, onTap: { _ in })
            HStack {
                OutfitFlatLayView(pieces: store.outfit("o-weekend")!.pieces, compact: true)
                OutfitFlatLayView(pieces: store.outfit("o-lace-date")!.pieces, compact: true)
            }
        }
        .padding()
    }
    .themedScreenBackground()
}
