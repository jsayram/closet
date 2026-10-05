import SwiftUI

// iPad helpers. An iPad is read from further away and has room to spare, so regular-width
// windows get slightly larger text and roomier sheets instead of a stretched iPhone layout.

extension View {
    /// A large page-style sheet on iPad (iOS 18+), so long content such as editors,
    /// pickers and the paywall isn't squeezed into the small default form sheet.
    /// On iPhone it stays a normal full-height sheet.
    @ViewBuilder
    func pageSheetOnPad() -> some View {
        if #available(iOS 18.0, *) {
            presentationSizing(.page)
        } else {
            self
        }
    }

    /// One text size up in regular-width windows on iPad. Accessibility sizes are
    /// left exactly as the person set them.
    func padComfortableText() -> some View {
        modifier(PadComfortableText())
    }
}

private struct PadComfortableText: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.environment(\.dynamicTypeSize, adjusted)
    }

    private var adjusted: DynamicTypeSize {
        guard UIDevice.current.userInterfaceIdiom == .pad, sizeClass == .regular,
              !dynamicTypeSize.isAccessibilitySize else { return dynamicTypeSize }
        let sizes = DynamicTypeSize.allCases
        guard let index = sizes.firstIndex(of: dynamicTypeSize), index + 1 < sizes.count,
              !sizes[index + 1].isAccessibilitySize else { return dynamicTypeSize }
        return sizes[index + 1]
    }
}
