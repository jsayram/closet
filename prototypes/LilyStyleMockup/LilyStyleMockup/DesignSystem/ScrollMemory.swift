import SwiftUI

extension View {
    /// Keeps the top-most visible row in shared UI state, so a list that is rebuilt by a
    /// section switch, resize or shell change comes back where Lily left it. The stack or
    /// grid holding the rows needs `.scrollTargetLayout()`.
    ///
    /// The first row is stored as nil, so a list at the top keeps the header above that
    /// row in view instead of scrolling it away. View state only; nothing is dispatched.
    func rememberedScrollPosition(_ anchor: Binding<String?>, firstID: String?) -> some View {
        scrollPosition(id: Binding(
            get: { anchor.wrappedValue },
            set: { anchor.wrappedValue = $0 == firstID ? nil : $0 }
        ), anchor: .top)
    }
}
