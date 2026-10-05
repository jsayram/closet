import SwiftUI
import UniformTypeIdentifiers

// MARK: - Contact sheet canvas

/// Fixed-width numbered contact sheet. The same view is shown on screen and
/// rendered by `ImageRenderer` for Share / Save / Copy, so the preview matches
/// the exported pixels. It contains garments only: no name, measurements,
/// location or links.
struct AskStylistCollageCanvas: View {
    static let width: CGFloat = 420

    var title: String
    var subtitle: String
    var items: [AskStylistItem]
    var pageIndex: Int
    var pageCount: Int

    private var rows: [[AskStylistItem]] {
        stride(from: 0, to: items.count, by: 2).map { Array(items[$0..<min($0 + 2, items.count)]) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            header
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(row) { item in
                        AskStylistCollageTile(item: item)
                    }
                    if row.count == 1 {
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
            footer
        }
        .padding(Spacing.m + 4)
        .frame(width: Self.width, alignment: .leading)
        .background(Palette.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Contact sheet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .textCase(.uppercase)
                Spacer(minLength: Spacing.xs)
                if pageCount > 1 {
                    Text("Page \(pageIndex + 1) of \(pageCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.primaryAction)
                }
            }
            Text(title)
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Rectangle().fill(Palette.divider).frame(height: 1)
            Text("Numbers are labels for this image only. “Representative” pictures are illustrations, not photos of the actual garment. In this demo, “Your photo” pictures are illustrated stand-ins too.")
                .font(.caption2)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("Prepared on device by My Petite Style (demo). No AI was used to make this sheet.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
        }
        .padding(.top, Spacing.xxs)
    }
}

/// One numbered garment tile on the contact sheet.
struct AskStylistCollageTile: View {
    var item: AskStylistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AskStylistItemArtwork(item: item)
                .overlay(alignment: .topLeading) {
                    AskStylistNumberBadge(number: item.number, prominent: true)
                        .padding(6)
                }
            // No line limit: the exported sheet grows rather than cutting off a name.
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.xxs) {
                AskStylistColorDot(hex: item.colorHex)
                Text(item.colorName ?? "Color unknown")
                    .italic(item.colorName == nil)
            }
            .font(.caption)
            .foregroundStyle(Palette.secondaryText)
            Text(item.typeLabel)
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: Spacing.xxs) {
                ForEach(Array(item.badges.enumerated()), id: \.offset) { _, badge in
                    StatusBadge(kind: badge, compact: true)
                }
            }
        }
        .padding(Spacing.xs + 2)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilitySummary)
    }
}

/// Her photo when one exists, otherwise the app-owned representative artwork.
struct AskStylistItemArtwork: View {
    var item: AskStylistItem

    var body: some View {
        if let filename = item.photoFilename, let image = PhotoStore.image(named: filename) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(Image(uiImage: image).resizable().scaledToFill())
                .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                .accessibilityHidden(true)
        } else {
            GarmentArtwork(kind: item.kind, hex: item.colorHex)
        }
    }
}

/// "#3" export label. Text on a filled capsule, never color alone.
struct AskStylistNumberBadge: View {
    var number: Int
    var prominent = false

    var body: some View {
        Text("#\(number)")
            .font((prominent ? Font.headline : Font.subheadline).weight(.bold).monospacedDigit())
            .foregroundStyle(Palette.onPrimaryAction)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, prominent ? 3 : 2)
            .background(Capsule().fill(Palette.primaryAction))
            .accessibilityLabel("Number \(number)")
    }
}

/// Swatch that stays honest about an Unknown color.
struct AskStylistColorDot: View {
    var hex: String?

    var body: some View {
        if let hex {
            ColorSwatch(hex: hex, size: 12)
        } else {
            Image(systemName: "questionmark.circle")
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Rendering and export payloads

/// One rendered contact-sheet page, exactly as it would be shared.
struct AskStylistRenderedPage: Identifiable {
    var index: Int
    var image: UIImage
    var pngData: Data

    var id: Int { index }
    var pixelWidth: Int { Int(image.size.width * image.scale) }
    var pixelHeight: Int { Int(image.size.height * image.scale) }
}

/// Renders the contact sheet locally with `ImageRenderer` (fixed width, scale 2,
/// light appearance, default text size). Rendering is on-device drawing only:
/// it never calls a stylist, image, search or fit service.
@MainActor
enum AskStylistRenderer {
    static let scale: CGFloat = 2

    static func render(_ content: AskStylistContent) -> [AskStylistRenderedPage] {
        content.pages.enumerated().compactMap { index, items in
            let canvas = AskStylistCollageCanvas(
                title: content.title,
                subtitle: content.pageSubtitle(index),
                items: items,
                pageIndex: index,
                pageCount: content.pageCount
            )
            .environment(\.colorScheme, .light)
            .dynamicTypeSize(.large)

            let renderer = ImageRenderer(content: canvas)
            renderer.scale = scale
            renderer.isOpaque = true
            renderer.proposedSize = ProposedViewSize(width: AskStylistCollageCanvas.width, height: nil)
            // A freshly drawn PNG carries no camera, time or location metadata.
            guard let image = renderer.uiImage, let data = image.pngData() else { return nil }
            return AskStylistRenderedPage(index: index, image: image, pngData: data)
        }
    }
}

/// PNG payload for ShareLink and the Files exporter.
struct AskStylistExportImage: Transferable, Identifiable {
    var pageIndex: Int
    var pngData: Data
    var filename: String

    var id: Int { pageIndex }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in item.pngData }
            .suggestedFileName { $0.filename }
    }

    static func from(_ pages: [AskStylistRenderedPage]) -> [AskStylistExportImage] {
        pages.map { page in
            let suffix = pages.count > 1 ? " \(page.index + 1) of \(pages.count)" : ""
            return AskStylistExportImage(pageIndex: page.index, pngData: page.pngData, filename: "Look contact sheet\(suffix).png")
        }
    }
}

// MARK: - Previews

#Preview("Contact sheet canvas") {
    let model = AppModel.preview
    let content = AskStylistContent.make(target: .outfit(model.store.outfit("o-interview")!), store: model.store)
    return ScrollView {
        AskStylistCollageCanvas(title: content.title, subtitle: content.pageSubtitle(0), items: content.pages.first ?? [],
                                pageIndex: 0, pageCount: content.pageCount)
    }
    .previewEnvironment(model)
}
