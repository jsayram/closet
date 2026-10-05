import SwiftUI

/// Honest placeholder for a simulated On Me preview: an abstract neutral figure
/// with the captured garments overlaid. Not a real person and not a fit preview.
struct OnMePreviewFigure: View {
    var pieces: [OutfitPiece]
    var label: String = "Simulated On Me preview"
    var isEarlier = false

    private func piece(_ slot: OutfitSlot) -> OutfitPiece? { pieces.first { $0.slot == slot } }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell)
                // Abstract mannequin.
                VStack(spacing: 0) {
                    Circle().fill(Palette.figure).frame(width: w * 0.16, height: w * 0.16)
                    Capsule().fill(Palette.figure).frame(width: w * 0.06, height: h * 0.03)
                    Spacer()
                }
                .padding(.top, h * 0.04)

                Group {
                    if let dress = piece(.dress) {
                        art(dress).frame(width: w * 0.62, height: h * 0.55).position(x: w / 2, y: h * 0.5)
                    } else {
                        if let bottom = piece(.bottom) {
                            art(bottom).frame(width: w * 0.56, height: h * 0.48).position(x: w / 2, y: h * 0.64)
                        }
                        if let top = piece(.top) {
                            art(top).frame(width: w * 0.62, height: h * 0.34).position(x: w / 2, y: h * 0.33)
                        }
                    }
                    if let layer = piece(.layer) {
                        art(layer).opacity(0.92).frame(width: w * 0.74, height: h * 0.38).position(x: w / 2, y: h * 0.34)
                    }
                    if let shoes = piece(.shoes) {
                        art(shoes).frame(width: w * 0.3, height: h * 0.12).position(x: w * 0.38, y: h * 0.91)
                        art(shoes).scaleEffect(x: -1).frame(width: w * 0.3, height: h * 0.12).position(x: w * 0.62, y: h * 0.91)
                    }
                    if let accessory = piece(.accessory) {
                        art(accessory).frame(width: w * 0.2, height: w * 0.2).position(x: w * 0.85, y: h * 0.55)
                    }
                }

                VStack {
                    HStack {
                        StatusBadge(kind: isEarlier ? .earlier : .simulated, compact: true)
                        Spacer()
                    }
                    Spacer()
                    Text("Placeholder figure · not a real person · not a fit preview")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(4)
                        .background(Capsule().fill(Palette.surface.opacity(0.9)))
                }
                .padding(6)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isEarlier ? "Earlier " : "")\(label): placeholder figure wearing \(pieces.map(\.capturedName).joined(separator: ", ")). Simulated; not a real person and not a fit preview.")
    }

    private func art(_ piece: OutfitPiece) -> some View {
        GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex, showsWell: false)
    }
}

/// Lane header with icon + text label (never color alone).
struct LaneLabel: View {
    var lane: LanePurpose

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: lane.systemImage)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(lane.title)
                    .font(.editorial(.headline))
                    .foregroundStyle(Palette.primaryText)
                Text(lane.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
