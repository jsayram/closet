import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Text fields

/// Themed input surface with a ≥3:1 control outline.
struct GarmentEditorFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs + 2)
            .frame(minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
    }
}

extension View {
    func garmentEditorField() -> some View { modifier(GarmentEditorFieldStyle()) }
}

/// Small field caption shown above an input. The hint sits behind an info button
/// beside the title, so the form stays one line per field.
struct GarmentEditorFieldLabel: View {
    var title: String
    var hint: String?
    /// Headings over lists (Other names, Details) stay visible to VoiceOver even without a hint.
    var isListHeading = false

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                // Fields carry their own labels; only list headings are read out.
                .accessibilityAddTraits(isListHeading ? .isHeader : [])
                .accessibilityHidden(!isListHeading)
            if let hint {
                InfoButton(title, text: hint)
            }
        }
    }
}

/// Text field + Add button that stacks vertically at accessibility sizes.
struct GarmentEditorAddRow: View {
    var placeholder: String
    @Binding var text: String
    var fieldIdentifier: String
    var buttonTitle = "Add"
    var accessibilityLabel: String
    var onAdd: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.xs))
        layout {
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit { if !isEmpty { onAdd() } }
                .garmentEditorField()
                .accessibilityLabel(accessibilityLabel)
                .accessibilityIdentifier(fieldIdentifier)
            Button(action: onAdd) {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isEmpty)
            .accessibilityLabel("\(buttonTitle): \(accessibilityLabel)")
        }
    }
}

// MARK: - Annotation rows

/// An Other name / detail row with provenance and a remove control.
struct GarmentEditorNoteRow: View {
    var text: String
    var provenance: String?
    var kindLabel: String
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let provenance {
                    Text(provenance)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.xs)
            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .font(.title3)
                    .foregroundStyle(Palette.error)
                    .minimumHitTarget()
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel("Remove \(kindLabel) \(text)")
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Chips

/// Single-choice chips (category, kind) on one row that scrolls sideways, with an
/// expand control when they don't fit. They wrap at accessibility text sizes.
struct GarmentEditorChoiceChips<Item: Hashable>: View {
    var items: [Item]
    var selection: Item
    var title: (Item) -> String
    var systemImage: (Item) -> String?
    var identifier: (Item) -> String
    var onSelect: (Item) -> Void
    /// Plural noun for the expand control's VoiceOver label ("Show all categories").
    var itemsLabel = "choices"

    var body: some View {
        ChipCarousel(itemsLabel: itemsLabel) {
            ForEach(items, id: \.self) { item in
                CapsuleChip(title: title(item), systemImage: systemImage(item), isSelected: item == selection) {
                    onSelect(item)
                }
                .accessibilityIdentifier(identifier(item))
            }
        }
    }
}

// MARK: - Color picker

/// ColorFamily swatches plus Unknown. Selection is shown with a ring, checkmark and trait.
struct GarmentEditorColorPicker: View {
    @Binding var family: ColorFamily?
    @ScaledMetric(relativeTo: .caption) private var cellWidth: CGFloat = 74
    @ScaledMetric(relativeTo: .caption) private var swatchSize: CGFloat = 30

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cellWidth), spacing: Spacing.xs)], alignment: .leading, spacing: Spacing.xs) {
            cell(title: "Unknown", isSelected: family == nil, identifier: "colorPicker-unknown") {
                ZStack {
                    Circle()
                        .strokeBorder(Palette.controlBorder, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    Text("?")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(Palette.secondaryText)
                }
            } action: {
                family = nil
            }
            ForEach(ColorFamily.allCases) { option in
                cell(title: option.label, isSelected: family == option, identifier: "colorPicker-\(option.rawValue)") {
                    ColorSwatch(hex: option.swatchHex, size: swatchSize)
                } action: {
                    family = option
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color family")
    }

    private func cell<Swatch: View>(title: String, isSelected: Bool, identifier: String, @ViewBuilder swatch: () -> Swatch, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                swatch()
                    .frame(width: swatchSize, height: swatchSize)
                    .overlay(alignment: .bottomTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Palette.primaryAction)
                                .background(Circle().fill(Palette.surface))
                                .offset(x: 4, y: 4)
                        }
                    }
                Text(title)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Palette.primaryAction : Palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xxs)
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(isSelected ? Palette.accentSurface : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(isSelected ? Palette.primaryAction : Color.clear, lineWidth: 1.5))
            .contentShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(title == "Unknown" ? "Color unknown" : title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Photos

/// A stored photo, downsampled for display. Shows an honest placeholder if the file is gone.
struct GarmentEditorStoredPhoto: View {
    var filename: String
    var maxPixel: CGFloat = 1400

    var body: some View {
        if let image = GarmentEditorImageCache.image(filename, maxPixel: maxPixel) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(Palette.secondaryText)
                Text("Photo file not found on this device")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.s)
        }
    }
}

/// Photo or artwork on the neutral image well, square.
struct GarmentEditorImageWell<Content: View>: View {
    var highlighted = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell)
            content()
                .padding(Spacing.xs)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(highlighted ? Palette.primaryAction : Palette.divider, lineWidth: highlighted ? 2 : 1)
        )
    }
}

/// One side of an Original / Processed (or Current / New) comparison.
struct GarmentEditorComparisonTile<Content: View>: View {
    var title: String
    var inUse: Bool
    var inUseText = "In use"
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GarmentEditorImageWell(highlighted: inUse, content: content)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xxs) { titleText; badge }
                VStack(alignment: .leading, spacing: Spacing.xxs) { titleText; badge }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(inUse ? "\(title), \(inUseText)" : title)
        .accessibilityAddTraits(.isImage)
    }

    private var titleText: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryText)
    }

    @ViewBuilder private var badge: some View {
        if inUse {
            StatusBadge(kind: .custom(inUseText, "checkmark.circle"), compact: true)
        }
    }
}

/// Two comparison tiles side by side, stacked at accessibility sizes.
struct GarmentEditorComparison<Left: View, Right: View>: View {
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Spacing.m) { left(); right() }
        } else {
            HStack(alignment: .top, spacing: Spacing.s) { left(); right() }
        }
    }
}

/// "Original saved on this device" confirmation (original-first). The detail sits
/// behind an info button beside it.
struct GarmentEditorOriginalSavedLabel: View {
    var detail: String?

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Label {
                Text("Original saved on this device")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.success)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Palette.success)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("originalSavedLabel")
            if let detail {
                InfoButton("the saved original", title: "Original saved on this device", text: detail)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Processing review (shared by Add Item and the photo section)

/// Optional simulated on-device cleanup with Original / Processing / Ready / Failed
/// states. Never blocks saving; the original is always kept.
struct GarmentEditorProcessingPanel: View {
    enum Phase: Equatable {
        case idle
        case keptOriginal
        case processing
        case ready(processed: String, usingProcessed: Bool)
        case failed(String)
    }

    var phase: Phase
    var originalFilename: String
    var onProcess: () -> Void
    var onCancel: () -> Void
    var onUseProcessed: () -> Void
    var onKeepOriginal: () -> Void
    var onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            switch phase {
            case .idle, .keptOriginal:
                Button(action: onProcess) {
                    Label("Clean up background", systemImage: "wand.and.stars")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityLabel("Clean up background, on-device, simulated")
                .accessibilityIdentifier("processPhotoButton")
                .accessibilityHint("Optional. Makes a separate processed copy; your original stays saved.")
                SimulationNotice(
                    text: phase == .keptOriginal
                        ? "Clean up background — on-device, simulated. Original kept. You can try the cleanup again any time."
                        : "Clean up background — on-device, simulated. Optional. Your original is already saved, and saving never waits for this.",
                    summary: phase == .keptOriginal ? "Original kept" : "Optional, on this device"
                )

            case .processing:
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(alignment: .top, spacing: Spacing.s) {
                        ProgressView()
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Processing on this device (simulated)…")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                            Text("You can keep editing or save now — the original is used if this isn't done.")
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Button("Cancel processing", action: onCancel)
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("cancelProcessingButton")
                }

            case let .ready(processed, usingProcessed):
                GarmentEditorComparison {
                    GarmentEditorComparisonTile(title: "Original", inUse: !usingProcessed) {
                        GarmentEditorStoredPhoto(filename: originalFilename, maxPixel: 600)
                    }
                } right: {
                    GarmentEditorComparisonTile(title: "Processed", inUse: usingProcessed) {
                        GarmentEditorStoredPhoto(filename: processed, maxPixel: 600)
                    }
                }
                SimulationNotice(text: "Simulated cleanup: the demo centers the photo on a plain backdrop. Real background removal isn't connected, and colors aren't changed.")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) { readyButtons(usingProcessed: usingProcessed) }
                    VStack(alignment: .leading, spacing: Spacing.xs) { readyButtons(usingProcessed: usingProcessed) }
                }

            case let .failed(reason):
                InlineBanner(style: .error, title: "Processing failed — original kept",
                             message: "\(reason) Your original photo is unchanged and the item can still be saved.",
                             actionTitle: "Try again", action: onProcess)
            }
        }
    }

    @ViewBuilder private func readyButtons(usingProcessed: Bool) -> some View {
        if usingProcessed {
            Button(action: onReset) {
                Label("Reset to original", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("resetToOriginalButton")
        } else {
            Button(action: onUseProcessed) {
                Label("Use processed", systemImage: "checkmark")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("useProcessedButton")
            Button(action: onKeepOriginal) {
                Label("Keep original", systemImage: "photo")
            }
            .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
            .accessibilityIdentifier("keepOriginalButton")
        }
    }
}

// MARK: - Intake buttons

extension View {
    /// Shared look for Camera / Photos / Paste / Text-only so the system PasteButton matches.
    func garmentEditorIntakeStyle() -> some View {
        self
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Palette.primaryAction)
            .labelStyle(.titleAndIcon)
            .hoverEffect(.highlight)
    }
}

/// Camera capture for one garment photo (only where a camera exists).
struct GarmentEditorCameraPicker: UIViewControllerRepresentable {
    var onImage: (Data) -> Void
    var onCancel: () -> Void

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: GarmentEditorCameraPicker

        init(parent: GarmentEditorCameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.95) {
                parent.onImage(data)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
