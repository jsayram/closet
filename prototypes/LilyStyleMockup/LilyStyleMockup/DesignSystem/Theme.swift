import SwiftUI

/// Semantic color tokens backed by the asset catalog (light/dark appearances).
/// Values follow PRD §7.1. `imageWell`, `controlBorder` and `figure` are documented
/// derived additions: a neutral garment surface, a ≥3:1 outline for
/// meaningful control boundaries (the Divider token is decorative only), and the
/// quiet placeholder mannequin drawn on the image well.
enum Palette {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let primaryAction = Color("PrimaryAction")
    static let onPrimaryAction = Color("OnPrimaryAction")
    static let accentSurface = Color("AccentSurface")
    static let success = Color("Success")
    static let successSurface = Color("SuccessSurface")
    static let divider = Color("Divider")
    static let error = Color("Error")
    static let imageWell = Color("ImageWell")
    static let controlBorder = Color("ControlBorder")
    static let figure = Color("Figure")
}

/// 8-point spacing rhythm.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let card: CGFloat = 16
    static let tile: CGFloat = 12
    static let small: CGFloat = 8
}

/// Minimum interactive size (44×44 pt).
enum HitTarget {
    static let minimum: CGFloat = 44
}

extension Font {
    /// System serif, reserved for the app title and occasional editorial headings.
    static func editorial(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

extension Color {
    /// Creates a color from a 6-digit hex string such as "1F2A44". Used for garment colors,
    /// which stay identical in light and dark appearance.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum ColorMath {
    /// Relative luminance (WCAG) for a hex color.
    static func luminance(hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        func channel(_ v: UInt64) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((value >> 16) & 0xFF) + 0.7152 * channel((value >> 8) & 0xFF) + 0.0722 * channel(value & 0xFF)
    }

    static func isLight(hex: String) -> Bool { luminance(hex: hex) > 0.45 }
}

/// Available-width classes used for adaptive layout decisions. Layout is based
/// on the actual space a view receives, not on device names or orientation.
enum WidthClass: Comparable {
    case compact      // < 600 pt: single column, sheets/pushes
    case intermediate // 600–979 pt: two panes where readable
    case wide         // ≥ 980 pt: multi-pane comparison/inspection

    init(width: CGFloat) {
        switch width {
        case ..<600: self = .compact
        case ..<980: self = .intermediate
        default: self = .wide
        }
    }
}

extension View {
    /// Applies the warm ivory/charcoal background to a full screen.
    func themedScreenBackground() -> some View {
        background(Palette.background.ignoresSafeArea())
    }

    /// Ensures a minimum 44×44 pt hit area.
    func minimumHitTarget() -> some View {
        frame(minWidth: HitTarget.minimum, minHeight: HitTarget.minimum)
            .contentShape(Rectangle())
    }

    /// Bounds readable width on large displays while centering content.
    func readableWidth(_ maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}
