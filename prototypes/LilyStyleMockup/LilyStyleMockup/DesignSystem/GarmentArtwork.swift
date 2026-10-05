import SwiftUI

/// App-owned representative garment illustration. Drawn in the garment's
/// confirmed color (unchanged in dark mode) on a neutral image well. These are
/// stand-ins, never claimed to be photos of her actual garments.
struct GarmentArtwork: View {
    var kind: GarmentKind
    var hex: String?
    var showsWell = true

    /// Neutral fill for a garment whose color isn't known yet.
    static let unknownHex = "C9C2C6"

    var body: some View {
        let fillHex = hex ?? Self.unknownHex
        let light = ColorMath.isLight(hex: fillHex)
        ZStack {
            if showsWell {
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell)
            }
            GeometryReader { geo in
                let inset = showsWell ? min(10, geo.size.width * 0.08) : geo.size.width * 0.02
                GarmentSilhouette(kind: kind)
                    .fill(Color(hex: fillHex))
                    .overlay(GarmentSilhouette(kind: kind).stroke(Color.black.opacity(light ? 0.28 : 0.45), lineWidth: geo.size.width < 60 ? 0.6 : 1.2))
                    .overlay(GarmentDetails(kind: kind).stroke(light ? Color.black.opacity(0.22) : Color.white.opacity(0.35), style: StrokeStyle(lineWidth: geo.size.width < 60 ? 0.5 : 1, lineCap: .round)))
                    .padding(inset)
            }
            if hex == nil {
                Text("?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Main silhouette in a 100×100 design space.
struct GarmentSilhouette: Shape {
    var kind: GarmentKind

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        let ox = rect.midX - 50 * s
        let oy = rect.midY - 50 * s
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()

        func top(longSleeve: Bool, hem: CGFloat = 88, neckDepth: CGFloat = 22, wide: Bool = false) {
            let sw: CGFloat = wide ? 2 : 0
            path.move(to: p(38, 12))
            path.addLine(to: p(20 - sw, 18))
            if longSleeve {
                path.addLine(to: p(8 - sw, 74))
                path.addLine(to: p(19 - sw, 76))
                path.addLine(to: p(25, 40))
            } else {
                path.addLine(to: p(8 - sw, 40))
                path.addLine(to: p(19, 46))
                path.addLine(to: p(25, 40))
            }
            path.addLine(to: p(25, hem))
            path.addLine(to: p(75, hem))
            path.addLine(to: p(75, 40))
            if longSleeve {
                path.addLine(to: p(81 + sw, 76))
                path.addLine(to: p(92 + sw, 74))
            } else {
                path.addLine(to: p(81, 46))
                path.addLine(to: p(92 + sw, 40))
            }
            path.addLine(to: p(80 + sw, 18))
            path.addLine(to: p(62, 12))
            path.addQuadCurve(to: p(38, 12), control: p(50, neckDepth))
            path.closeSubpath()
        }

        switch kind {
        case .tee, .blouse, .knitTop:
            top(longSleeve: false, hem: kind == .knitTop ? 84 : 88, neckDepth: kind == .blouse ? 30 : 20)
        case .lacyTop:
            top(longSleeve: false, hem: 80, neckDepth: 24)
        case .sweater:
            top(longSleeve: true, hem: 86, neckDepth: 20, wide: true)
        case .cardigan:
            top(longSleeve: true, hem: 90, neckDepth: 40)
        case .jacket, .blazer:
            top(longSleeve: true, hem: kind == .jacket ? 84 : 90, neckDepth: 36)
        case .coat:
            top(longSleeve: true, hem: 97, neckDepth: 36)
        case .trousers, .jeans:
            let flare: CGFloat = kind == .jeans ? 6 : 0
            path.move(to: p(28, 8))
            path.addLine(to: p(72, 8))
            path.addLine(to: p(76 + flare, 94))
            path.addLine(to: p(55 - flare / 2, 94))
            path.addLine(to: p(50, 36))
            path.addLine(to: p(45 + flare / 2, 94))
            path.addLine(to: p(24 - flare, 94))
            path.closeSubpath()
        case .skirt:
            path.move(to: p(32, 10))
            path.addLine(to: p(68, 10))
            path.addLine(to: p(82, 88))
            path.addQuadCurve(to: p(18, 88), control: p(50, 93))
            path.closeSubpath()
        case .dress:
            path.move(to: p(38, 6))
            path.addLine(to: p(42, 6))
            path.addQuadCurve(to: p(58, 6), control: p(50, 16))
            path.addLine(to: p(62, 6))
            path.addLine(to: p(66, 40))
            path.addLine(to: p(84, 94))
            path.addQuadCurve(to: p(16, 94), control: p(50, 99))
            path.addLine(to: p(34, 40))
            path.closeSubpath()
        case .flats, .loafers:
            path.move(to: p(10, 72))
            path.addLine(to: p(12, 56))
            path.addQuadCurve(to: p(40, 62), control: p(26, 64))
            path.addQuadCurve(to: p(90, 68), control: p(72, 56))
            path.addQuadCurve(to: p(90, 76), control: p(96, 72))
            path.addLine(to: p(10, 76))
            path.closeSubpath()
        case .heels:
            path.move(to: p(12, 64))
            path.addLine(to: p(14, 46))
            path.addQuadCurve(to: p(40, 54), control: p(26, 56))
            path.addQuadCurve(to: p(90, 70), control: p(70, 56))
            path.addQuadCurve(to: p(88, 78), control: p(96, 76))
            path.addQuadCurve(to: p(26, 66), control: p(50, 72))
            path.addLine(to: p(22, 86))
            path.addLine(to: p(15, 86))
            path.closeSubpath()
        case .sneakers:
            path.move(to: p(8, 78))
            path.addLine(to: p(10, 52))
            path.addQuadCurve(to: p(42, 52), control: p(26, 58))
            path.addQuadCurve(to: p(92, 66), control: p(76, 50))
            path.addQuadCurve(to: p(92, 82), control: p(98, 74))
            path.addLine(to: p(8, 82))
            path.closeSubpath()
        case .boots:
            path.move(to: p(14, 82))
            path.addLine(to: p(16, 14))
            path.addLine(to: p(44, 14))
            path.addLine(to: p(46, 56))
            path.addQuadCurve(to: p(90, 72), control: p(78, 58))
            path.addQuadCurve(to: p(88, 84), control: p(96, 80))
            path.addLine(to: p(14, 84))
            path.closeSubpath()
        case .bag:
            path.addRoundedRect(in: CGRect(origin: p(18, 40), size: CGSize(width: 64 * s, height: 46 * s)), cornerSize: CGSize(width: 10 * s, height: 10 * s))
            path.move(to: p(30, 40))
            path.addQuadCurve(to: p(70, 40), control: p(50, 4))
            path.addQuadCurve(to: p(64, 40), control: p(67, 40))
            path.addQuadCurve(to: p(36, 40), control: p(50, 14))
            path.closeSubpath()
        case .scarf:
            path.move(to: p(20, 20))
            path.addQuadCurve(to: p(80, 20), control: p(50, 40))
            path.addLine(to: p(70, 90))
            path.addLine(to: p(58, 90))
            path.addLine(to: p(62, 34))
            path.addQuadCurve(to: p(30, 34), control: p(46, 44))
            path.closeSubpath()
        case .unknown:
            path.addRoundedRect(in: CGRect(origin: p(20, 20), size: CGSize(width: 60 * s, height: 60 * s)), cornerSize: CGSize(width: 10 * s, height: 10 * s))
        }
        return path
    }
}

/// Detail strokes (seams, plackets, pockets, laces, lace scallops).
struct GarmentDetails: Shape {
    var kind: GarmentKind

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        let ox = rect.midX - 50 * s
        let oy = rect.midY - 50 * s
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        switch kind {
        case .blouse:
            path.move(to: p(50, 30)); path.addLine(to: p(50, 86))
            for y in stride(from: 40, through: 80, by: 10) { path.addEllipse(in: CGRect(origin: p(48.8, CGFloat(y)), size: CGSize(width: 2.4 * s, height: 2.4 * s))) }
            path.move(to: p(44, 22)); path.addQuadCurve(to: p(50, 28), control: p(44, 28)); path.addQuadCurve(to: p(56, 22), control: p(56, 28))
        case .lacyTop:
            for x in stride(from: 25, to: 75, by: 6) {
                path.move(to: p(CGFloat(x), 80)); path.addQuadCurve(to: p(CGFloat(x) + 6, 80), control: p(CGFloat(x) + 3, 86))
            }
            path.move(to: p(36, 16)); path.addQuadCurve(to: p(64, 16), control: p(50, 32))
            for (x, y) in [(36, 50), (50, 58), (64, 50), (42, 68), (58, 68)] {
                path.addEllipse(in: CGRect(origin: p(CGFloat(x), CGFloat(y)), size: CGSize(width: 3 * s, height: 3 * s)))
            }
        case .knitTop, .sweater:
            let hem: CGFloat = kind == .sweater ? 86 : 84
            for x in stride(from: 28, to: 74, by: 4) { path.move(to: p(CGFloat(x), hem - 7)); path.addLine(to: p(CGFloat(x), hem - 1)) }
        case .tee:
            path.move(to: p(40, 13)); path.addQuadCurve(to: p(60, 13), control: p(50, 22))
        case .cardigan:
            path.move(to: p(50, 40)); path.addLine(to: p(50, 90))
            for y in stride(from: 46, through: 82, by: 9) { path.addEllipse(in: CGRect(origin: p(52, CGFloat(y)), size: CGSize(width: 2.6 * s, height: 2.6 * s))) }
        case .jacket:
            path.move(to: p(50, 34)); path.addLine(to: p(50, 84))
            path.move(to: p(38, 13)); path.addLine(to: p(46, 34)); path.addLine(to: p(40, 40))
            path.move(to: p(62, 13)); path.addLine(to: p(54, 34)); path.addLine(to: p(60, 40))
            path.move(to: p(30, 66)); path.addLine(to: p(42, 66))
            path.move(to: p(58, 66)); path.addLine(to: p(70, 66))
        case .blazer, .coat:
            path.move(to: p(38, 13)); path.addLine(to: p(50, 52)); path.addLine(to: p(62, 13))
            path.addEllipse(in: CGRect(origin: p(48.5, 58), size: CGSize(width: 3 * s, height: 3 * s)))
            if kind == .coat { path.move(to: p(25, 60)); path.addLine(to: p(75, 60)) }
        case .trousers:
            path.move(to: p(28, 15)); path.addLine(to: p(72, 15))
            path.move(to: p(36, 18)); path.addLine(to: p(34, 92))
            path.move(to: p(64, 18)); path.addLine(to: p(66, 92))
        case .jeans:
            path.move(to: p(28, 15)); path.addLine(to: p(72, 15))
            path.move(to: p(30, 20)); path.addQuadCurve(to: p(42, 30), control: p(34, 30))
            path.move(to: p(70, 20)); path.addQuadCurve(to: p(58, 30), control: p(66, 30))
            path.addRect(CGRect(origin: p(32, 34), size: CGSize(width: 12 * s, height: 12 * s)))
        case .skirt:
            path.move(to: p(32, 17)); path.addLine(to: p(68, 17))
            path.move(to: p(50, 20)); path.addLine(to: p(50, 90))
        case .dress:
            path.move(to: p(34, 40)); path.addLine(to: p(66, 40))
            for (x, y) in [(40, 56), (58, 62), (46, 74), (64, 80), (30, 82), (52, 88)] {
                path.addEllipse(in: CGRect(origin: p(CGFloat(x), CGFloat(y)), size: CGSize(width: 4 * s, height: 4 * s)))
            }
        case .loafers:
            path.move(to: p(52, 62)); path.addLine(to: p(70, 62))
            path.move(to: p(10, 72)); path.addLine(to: p(90, 72))
        case .flats:
            path.move(to: p(10, 72)); path.addLine(to: p(90, 72))
        case .heels:
            path.move(to: p(26, 66)); path.addQuadCurve(to: p(88, 76), control: p(56, 70))
        case .sneakers:
            path.move(to: p(8, 72)); path.addLine(to: p(92, 72))
            for x in stride(from: 46, through: 66, by: 6) { path.move(to: p(CGFloat(x), 54)); path.addLine(to: p(CGFloat(x) + 4, 60)) }
        case .boots:
            path.move(to: p(14, 76)); path.addLine(to: p(90, 76))
            path.move(to: p(16, 22)); path.addLine(to: p(44, 22))
        case .bag:
            path.move(to: p(18, 56)); path.addLine(to: p(82, 56))
            path.addRoundedRect(in: CGRect(origin: p(46, 54), size: CGSize(width: 8 * s, height: 6 * s)), cornerSize: CGSize(width: 2 * s, height: 2 * s))
        case .scarf:
            path.move(to: p(60, 80)); path.addLine(to: p(70, 80))
        case .unknown:
            break
        }
        return path
    }
}

/// Garment thumbnail: user photo when available, otherwise labelled artwork.
struct GarmentThumbnail: View {
    var garment: Garment
    var size: CGFloat? = nil
    var showsImageKind = false
    var showsStatus = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            ZStack(alignment: .topLeading) {
                image
                if showsStatus, let first = BadgeKind.status(for: garment).first {
                    StatusBadge(kind: first, compact: true)
                        .padding(6)
                }
            }
            .frame(width: size, height: size)
            if showsImageKind {
                StatusBadge(kind: BadgeKind.image(for: garment.photoFilename != nil ? .actualPhoto : garment.imageKind), compact: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(garment.accessibilityDescription)
        .accessibilityValue(BadgeKind.status(for: garment).map(\.text).joined(separator: ", "))
    }

    @ViewBuilder private var image: some View {
        if let filename = garment.photoFilename, let ui = PhotoStore.image(named: filename) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        } else {
            GarmentArtwork(kind: garment.kind, hex: garment.color?.hex)
        }
    }
}

/// Thumbnail for a captured outfit piece (uses captured facts, never current metadata).
struct PieceThumbnail: View {
    var piece: OutfitPiece

    var body: some View {
        GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex)
            .overlay(alignment: .topTrailing) {
                if piece.isHypothetical {
                    Image(systemName: "bag.badge.plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.primaryAction)
                        .padding(5)
                        .background(Circle().fill(Palette.surface))
                        .padding(4)
                }
            }
            .accessibilityHidden(true)
    }
}
