import SwiftUI
import Observation
import UIKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Feature UI state (owned by AppModel as `app.garmentEditorUI`)

/// State for Add Item and the garment naming/photo/facts editors. It lives on
/// `AppModel`, so drafts, review sessions and simulated processing survive
/// rotation, resizing and compact ↔ sidebar changes. Nothing here dispatches a
/// service on its own.
@Observable
final class GarmentEditorUIState {
    /// The Add Item draft. Keyed by the prefill that opened it.
    var draft: GarmentEditorDraft?

    /// Garments whose photo is being cleaned up (simulated, on-device).
    var processingIDs: Set<String> = []
    /// Last processing failure reason per garment, shown with "original kept".
    var processingFailures: [String: String] = [:]
    /// Replacement photos awaiting review before they are linked, keyed by garment ID.
    var pendingReplacements: [String: GarmentEditorPendingPhoto] = [:]
    /// What the photo looked like before the last replace/remove, for Revert.
    var revertablePhotos: [String: GarmentEditorPhotoRevert] = [:]

    /// Unsent "Add another name" / "Add details" text per garment.
    var aliasInput: [String: String] = [:]
    var detailInput: [String: String] = [:]

    /// Rename sheet target and its unsent text.
    var renameTarget: String?
    var renameText: String = ""
    var renameKeepsOldName: Bool = true

    /// Facts editor drafts per garment.
    var factsDrafts: [String: GarmentEditorFactsDraft] = [:]

    @ObservationIgnored var processingTasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored var suggestionTask: Task<Void, Never>?

    init() {}
}

// MARK: - Add Item draft

enum GarmentEditorPhotoOrigin: String, Hashable {
    case camera, photos, paste, drop

    var label: String {
        switch self {
        case .camera: "Taken with Camera"
        case .photos: "Chosen from Photos"
        case .paste: "Pasted"
        case .drop: "Dropped in"
        }
    }
}

/// A photo attached to the Add Item draft. The original is already written to
/// this device before anything else happens (original-first).
struct GarmentEditorDraftPhoto: Hashable {
    var originalFilename: String
    var processedFilename: String?
    var usingProcessed = false
    var origin: GarmentEditorPhotoOrigin
    var state: PhotoProcessingState = .originalOnly
    var failureReason: String?

    var activeFilename: String {
        usingProcessed ? (processedFilename ?? originalFilename) : originalFilename
    }
}

/// An Other name or Add details entry in the draft, with provenance.
struct GarmentEditorDraftNote: Identifiable, Hashable {
    var id = UUID().uuidString
    var text: String
    var provenance: AnnotationProvenance
}

enum GarmentEditorProposalStatus: Hashable {
    case pending, accepted, edited, skipped
}

struct GarmentEditorProposalItem: Identifiable, Hashable {
    var id: UUID { proposal.id }
    var proposal: MetadataProposal
    var status: GarmentEditorProposalStatus = .pending
    var resultNote: String?

    /// Stable identifier fragment such as "name", "color", "detail".
    var fieldKey: String {
        proposal.field.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    /// A photo can't confirm fabric/brand/size, so those rows only confirm Unknown.
    var isUnknownOnly: Bool {
        let field = proposal.field.lowercased()
        return ["fabric", "brand", "size"].contains(field) || proposal.value.lowercased() == "unknown"
    }
}

enum GarmentEditorSuggestionPhase: Equatable {
    case idle
    case working
    case ready
    case failed(String)
    case cancelled
    case discarded
}

/// Optional photo-understanding review for the draft.
struct GarmentEditorSuggestionSession: Equatable {
    var phase: GarmentEditorSuggestionPhase = .idle
    var items: [GarmentEditorProposalItem] = []
    var requestedPhoto: String?
    var showConsent = false
    /// Set after "Not now" so the card collapses without nagging.
    var consentDismissed = false
}

/// The unsaved Add Item form. Nothing becomes canonical until an explicit save
/// with an explicit ownership choice.
struct GarmentEditorDraft {
    var key: String
    var name = ""
    var otherNames: [GarmentEditorDraftNote] = []
    var details: [GarmentEditorDraftNote] = []
    var aliasInput = ""
    var detailInput = ""
    var category: GarmentCategory = .unknown
    var kind: GarmentKind = .unknown
    /// `nil` = color Unknown.
    var colorFamily: ColorFamily?
    var shadeName = ""
    var brand = ""
    var size = ""
    var fabric = ""
    var notes = ""
    var sourceURL = ""
    var textOnlyChosen = false
    var photo: GarmentEditorDraftPhoto?
    var intoSuitcaseID: String?
    var alsoAddToSuitcase = false
    /// Whether the optional "More details" fields are open. Layout only; kept with
    /// the draft so it survives the form switching between one and two columns.
    var showsMoreDetails = false
    var suggestion = GarmentEditorSuggestionSession()
    var createdAt = Date.now

    init(key: String) {
        self.key = key
    }

    init(key: String, prefill: AddGarmentPrefill?) {
        self.key = key
        guard let prefill else { return }
        name = prefill.name
        if prefill.kind != .unknown {
            kind = prefill.kind
            category = prefill.kind.defaultCategory
        }
        colorFamily = prefill.colorFamily
        if let link = prefill.linkText?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty {
            sourceURL = link
        }
        intoSuitcaseID = prefill.intoSuitcaseID
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var color: GarmentColor? {
        guard let colorFamily else { return nil }
        let shade = shadeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return GarmentColor(name: shade.isEmpty ? colorFamily.label : shade, hex: colorFamily.swatchHex, family: colorFamily)
    }

    /// Whether leaving would lose anything she entered.
    var hasContent: Bool {
        !trimmedName.isEmpty || !otherNames.isEmpty || !details.isEmpty || photo != nil
            || category != .unknown || kind != .unknown || colorFamily != nil
            || ![brand, size, fabric, notes, sourceURL, aliasInput, detailInput, shadeName]
                .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// The neutral label used when she leaves Name empty.
    var fallbackName: String {
        GarmentEditorNaming.fallbackName(kind: kind, category: category, color: color)
    }

    var finalName: String { trimmedName.isEmpty ? fallbackName : trimmedName }

    /// Builds the canonical record for an explicit save.
    func makeGarment(ownership: OwnershipStatus, id: String = "g-\(UUID().uuidString.prefix(8))") -> Garment {
        var g = Garment(id: id, displayName: finalName, category: category == .unknown ? kind.defaultCategory : category, kind: kind, color: color)
        var annotations: [GarmentAnnotation] = []
        var seen = Set<String>()
        func add(_ kind: AnnotationKind, _ text: String, _ provenance: AnnotationProvenance) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let norm = "\(kind.rawValue):\(trimmed.lowercased())"
            guard !trimmed.isEmpty, !seen.contains(norm) else { return }
            if kind == .alias, trimmed.lowercased() == finalName.lowercased() { return }
            seen.insert(norm)
            annotations.append(GarmentAnnotation(kind: kind, text: trimmed, provenance: provenance))
        }
        for note in otherNames { add(.alias, note.text, note.provenance) }
        add(.alias, aliasInput, .userEntered)
        for note in details { add(.detail, note.text, note.provenance) }
        add(.detail, detailInput, .userEntered)
        g.annotations = annotations
        g.brand = Self.nonEmpty(brand)
        g.sizeLabel = Self.nonEmpty(size)
        g.fabric = Self.nonEmpty(fabric)
        g.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        g.sourceURL = Self.nonEmpty(sourceURL)
        g.ownership = ownership
        g.availability = .available
        g.addedAt = .now
        if let photo {
            g.imageKind = .actualPhoto
            g.photoFilename = photo.activeFilename
            switch photo.state {
            case .processing: g.processing = .originalOnly
            case .ready: g.processing = photo.processedFilename == nil ? .originalOnly : .ready
            default: g.processing = photo.state
            }
        } else {
            g.imageKind = .textOnly
            g.photoFilename = nil
            g.processing = .originalOnly
        }
        return g
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Garment detail support types

struct GarmentEditorPendingPhoto: Hashable {
    var filename: String
    var origin: GarmentEditorPhotoOrigin
}

struct GarmentEditorPhotoRevert: Hashable {
    var filename: String?
    var imageKind: ImageSourceKind
    var processing: PhotoProcessingState
    /// The photo that replaced it (deleted again on revert), if any.
    var replacedBy: String?
    var actionLabel: String
}

/// Editable copy of a garment's facts for the facts editor sheet.
struct GarmentEditorFactsDraft: Hashable {
    var baseRevision: Int
    var category: GarmentCategory
    var kind: GarmentKind
    var colorFamily: ColorFamily?
    var shadeName: String
    var brand: String
    var size: String
    var fabric: String
    var notes: String
    var formality: Formality
    var seasons: Set<Season>
    var warmth: Int

    init(_ g: Garment) {
        baseRevision = g.revision
        category = g.category
        kind = g.kind
        colorFamily = g.color?.family
        if let color = g.color, color.name.lowercased() != color.family.label.lowercased() {
            shadeName = color.name
        } else {
            shadeName = ""
        }
        brand = g.brand ?? ""
        size = g.sizeLabel ?? ""
        fabric = g.fabric ?? ""
        notes = g.notes
        formality = g.formality
        seasons = g.seasons
        warmth = g.warmth
    }

    /// The confirmed color, keeping her exact recorded shade/hex when the family is unchanged.
    func color(original: GarmentColor?) -> GarmentColor? {
        guard let colorFamily else { return nil }
        let shade = shadeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = shade.isEmpty ? colorFamily.label : shade
        if let original, original.family == colorFamily {
            return GarmentColor(name: name, hex: original.hex, family: colorFamily)
        }
        return GarmentColor(name: name, hex: colorFamily.swatchHex, family: colorFamily)
    }

    func differs(from g: Garment) -> Bool {
        let trimmed: (String) -> String? = { let t = $0.trimmingCharacters(in: .whitespacesAndNewlines); return t.isEmpty ? nil : t }
        return category != g.category || kind != g.kind || color(original: g.color) != g.color
            || trimmed(brand) != g.brand || trimmed(size) != g.sizeLabel || trimmed(fabric) != g.fabric
            || notes.trimmingCharacters(in: .whitespacesAndNewlines) != g.notes
            || formality != g.formality || seasons != g.seasons || warmth != g.warmth
    }
}

// MARK: - Local naming help (no AI)

enum GarmentEditorNaming {
    static func categoryNoun(_ category: GarmentCategory) -> String? {
        switch category {
        case .top: "top"
        case .bottom: "bottoms"
        case .dress: "dress"
        case .layer: "layer"
        case .shoes: "shoes"
        case .accessory: "accessory"
        case .unknown: nil
        }
    }

    /// A simple name from confirmed facts only, e.g. "Light pink blouse". `nil` when nothing is known.
    static func suggestedName(kind: GarmentKind, category: GarmentCategory, color: GarmentColor?) -> String? {
        let noun = kind != .unknown ? kind.label.lowercased() : categoryNoun(category)
        let colorWord = color?.name
        guard noun != nil || colorWord != nil else { return nil }
        let words = [colorWord, noun ?? "item"].compactMap { $0 }.joined(separator: " ")
        return capitalizedFirst(words)
    }

    /// Neutral fallback when Name is left empty: "Pink top", "Blouse" or "New item".
    static func fallbackName(kind: GarmentKind, category: GarmentCategory, color: GarmentColor?) -> String {
        let noun = kind != .unknown ? kind.label.lowercased() : categoryNoun(category)
        switch (color?.family.label, noun) {
        case let (c?, n?): return capitalizedFirst("\(c) \(n)")
        case let (nil, n?): return capitalizedFirst(n)
        case let (c?, nil): return "\(c) item"
        default: return "New item"
        }
    }

    static func suggestedName(for g: Garment) -> String? {
        guard let suggestion = suggestedName(kind: g.kind, category: g.category, color: g.color) else { return nil }
        let lower = suggestion.lowercased()
        if g.displayName.lowercased() == lower { return nil }
        if g.aliases.contains(where: { $0.text.lowercased() == lower }) { return nil }
        return suggestion
    }

    static func capitalizedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    /// Maps reviewed free text (e.g. "Off-white (could be cream)") to a color family.
    static func colorFamily(matching text: String) -> ColorFamily? {
        var lower = text.lowercased()
        if let paren = lower.firstIndex(of: "(") { lower = String(lower[..<paren]) }
        let synonyms: [(String, ColorFamily)] = [
            ("off-white", .white), ("off white", .white), ("ivory", .cream), ("khaki", .tan), ("camel", .tan),
            ("grey", .gray), ("charcoal", .gray), ("maroon", .burgundy), ("wine", .burgundy), ("blush", .pink),
            ("rose", .pink), ("rust", .brick), ("sage", .green), ("chocolate", .brown), ("jean", .denim),
        ]
        for (word, family) in synonyms where lower.contains(word) { return family }
        let candidates = ColorFamily.allCases.sorted { $0.label.count > $1.label.count }
        return candidates.first { lower.contains($0.label.lowercased()) }
    }

    /// The shade wording before any parenthetical uncertainty, e.g. "Off-white".
    static func shadeName(from text: String) -> String {
        var value = text
        if let paren = value.firstIndex(of: "(") { value = String(value[..<paren]) }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Maps reviewed category text to a kind and/or category.
    static func kindOrCategory(matching text: String) -> (GarmentKind?, GarmentCategory?) {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let kind = GarmentKind.allCases.first(where: { $0 != .unknown && $0.label.lowercased() == lower }) {
            return (kind, kind.defaultCategory)
        }
        if let category = GarmentCategory.allCases.first(where: { $0 != .unknown && ($0.label.lowercased() == lower || $0.pluralLabel.lowercased() == lower) }) {
            return (nil, category)
        }
        if let kind = GarmentKind.allCases.first(where: { $0 != .unknown && lower.contains($0.label.lowercased()) }) {
            return (kind, kind.defaultCategory)
        }
        return (nil, nil)
    }
}

// MARK: - Photo files (original-first; derivatives kept separately)

enum GarmentEditorPhotoFiles {
    static let processedSuffix = "-processed"
    /// Demo safety bound, disclosed in the intake copy.
    static let maxImportBytes = 50 * 1024 * 1024

    static func isProcessed(_ filename: String) -> Bool { filename.hasSuffix(processedSuffix) }

    static func originalName(for filename: String) -> String {
        isProcessed(filename) ? String(filename.dropLast(processedSuffix.count)) : filename
    }

    static func processedName(for original: String) -> String { original + processedSuffix }

    static func url(_ filename: String) -> URL { PhotoStore.directory.appendingPathComponent(filename) }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: url(filename).path)
    }

    static func delete(_ filename: String?) {
        guard let filename else { return }
        GarmentEditorImageCache.forget(filename)
        PhotoStore.delete(filename)
    }

    /// Validates imported bytes before they are kept. Returns a user-facing problem, if any.
    static func problem(with data: Data) -> String? {
        if data.isEmpty { return "That image was empty. Nothing was saved — try another photo." }
        if data.count > maxImportBytes { return "That image is larger than the demo's 50 MB limit. Nothing was saved — try a smaller photo or a screenshot." }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0,
              CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 64] as CFDictionary) != nil else {
            return "Couldn't read that image. Nothing was saved — try another photo."
        }
        return nil
    }

    /// Writes the untouched original bytes off the main thread. Returns the filename.
    static func saveOriginal(_ data: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try PhotoStore.saveOriginal(data)
        }.value
    }
}

/// Downsampled display images for the editor (originals stay untouched on disk).
enum GarmentEditorImageCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(_ filename: String, maxPixel: CGFloat = 1400) -> UIImage? {
        let key = "\(filename)#\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let url = GarmentEditorPhotoFiles.url(filename)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: key)
        return image
    }

    static func forget(_ filename: String) {
        for size in [1400, 600] { cache.removeObject(forKey: "\(filename)#\(size)" as NSString) }
    }
}

// MARK: - Simulated on-device processing

/// Simulated "clean up background". It does not remove backgrounds: it squares
/// and centers the photo on a plain backdrop so the review flow (Original /
/// Processing / Ready / Failed, Use processed, Reset) can be tried. Garment
/// colors are not altered. It is local work, not a service dispatch.
enum GarmentEditorPhotoProcessor {
    enum Outcome: Equatable {
        case success(String)
        case failed(String)
        case cancelled
    }

    struct Backdrop: Sendable {
        var red: Double, green: Double, blue: Double
    }

    static func backdrop() -> Backdrop {
        let resolved = UIColor(Palette.imageWell).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Backdrop(red: Double(r), green: Double(g), blue: Double(b))
    }

    static func run(original: String, fast: Bool, simulateFailure: Bool, backdrop: Backdrop) async -> Outcome {
        do {
            try await Task.sleep(nanoseconds: fast ? 300_000_000 : 1_600_000_000)
            if simulateFailure {
                return .failed("Couldn't store the processed copy (simulated low storage).")
            }
            let name = try await Task.detached(priority: .userInitiated) {
                try render(original: original, backdrop: backdrop)
            }.value
            if Task.isCancelled {
                GarmentEditorPhotoFiles.delete(name)
                return .cancelled
            }
            return .success(name)
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failed("This photo couldn't be processed.")
        }
    }

    private enum RenderError: Error { case unreadable, encoding }

    private static func render(original: String, backdrop: Backdrop) throws -> String {
        let url = GarmentEditorPhotoFiles.url(original)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw RenderError.unreadable }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1600,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { throw RenderError.unreadable }
        let image = UIImage(cgImage: cgImage)
        let longest = max(image.size.width, image.size.height)
        let side = (longest * 1.12).rounded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor(red: backdrop.red, green: backdrop.green, blue: backdrop.blue, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            let origin = CGPoint(x: (side - image.size.width) / 2, y: (side - image.size.height) / 2)
            image.draw(in: CGRect(origin: origin, size: image.size))
        }
        guard let data = rendered.jpegData(compressionQuality: 0.92) else { throw RenderError.encoding }
        let name = GarmentEditorPhotoFiles.processedName(for: original)
        try data.write(to: GarmentEditorPhotoFiles.url(name), options: [.atomic])
        return name
    }
}

// MARK: - Intake (paste / drop parsing)

enum GarmentEditorIncoming {
    case image(Data)
    case link(String)
    case text(String)
    case unreadable

    static func classify(text: String) -> GarmentEditorIncoming {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unreadable }
        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil {
            return .link(trimmed)
        }
        if !trimmed.contains(" "), trimmed.contains("."), let url = URL(string: "https://\(trimmed)"), url.host?.contains(".") == true {
            return .link(trimmed)
        }
        return .text(trimmed)
    }

    /// Loads the first usable item from pasted providers: an image first, then a link, then text.
    static func load(_ providers: [NSItemProvider], completion: @escaping (GarmentEditorIncoming) -> Void) {
        let finish: (GarmentEditorIncoming) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                finish(data.map { .image($0) } ?? .unreadable)
            }
            return
        }
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return finish(.unreadable) }
                if url.isFileURL, let data = try? Data(contentsOf: url) {
                    finish(.image(data))
                } else {
                    finish(.link(url.absoluteString))
                }
            }
            return
        }
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: String.self) }) {
            _ = provider.loadObject(ofClass: String.self) { text, _ in
                finish(text.map { classify(text: $0) } ?? .unreadable)
            }
            return
        }
        finish(.unreadable)
    }
}

/// iPad drag-and-drop payload for the Add Item photo area: an image, a link, or text.
enum GarmentEditorDropItem: Transferable {
    case image(Data)
    case link(URL)
    case text(String)

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in GarmentEditorDropItem.image(data) }
        ProxyRepresentation(importing: { (url: URL) in GarmentEditorDropItem.link(url) })
        ProxyRepresentation(importing: { (text: String) in GarmentEditorDropItem.text(text) })
    }

    var incoming: GarmentEditorIncoming {
        switch self {
        case let .image(data): return .image(data)
        case let .link(url):
            if url.isFileURL, let data = try? Data(contentsOf: url) { return .image(data) }
            return .link(url.absoluteString)
        case let .text(text): return GarmentEditorIncoming.classify(text: text)
        }
    }
}

// MARK: - Processing control (draft + saved garments)

extension GarmentEditorUIState {
    static let draftProcessingKey = "draft"

    /// Starts simulated cleanup for the draft photo. Explicit button only.
    func startDraftProcessing(fast: Bool, simulateFailure: Bool) {
        guard var d = draft, let photo = d.photo else { return }
        let key = d.key
        let original = photo.originalFilename
        d.photo?.state = .processing
        d.photo?.failureReason = nil
        draft = d
        let backdrop = GarmentEditorPhotoProcessor.backdrop()
        processingTasks[Self.draftProcessingKey]?.cancel()
        processingTasks[Self.draftProcessingKey] = Task { @MainActor [weak self] in
            let outcome = await GarmentEditorPhotoProcessor.run(original: original, fast: fast, simulateFailure: simulateFailure, backdrop: backdrop)
            guard let self else { return }
            guard var current = self.draft, current.key == key, current.photo?.originalFilename == original,
                  current.photo?.state == .processing else {
                if case let .success(name) = outcome { GarmentEditorPhotoFiles.delete(name) }
                return
            }
            switch outcome {
            case let .success(name):
                GarmentEditorImageCache.forget(name)
                current.photo?.processedFilename = name
                current.photo?.usingProcessed = false
                current.photo?.state = .ready
            case let .failed(reason):
                current.photo?.state = .failed
                current.photo?.failureReason = reason
            case .cancelled:
                current.photo?.state = .originalOnly
            }
            self.draft = current
            UIAccessibility.post(notification: .announcement, argument: current.photo?.state.label ?? "")
        }
    }

    func cancelDraftProcessing() {
        processingTasks[Self.draftProcessingKey]?.cancel()
        processingTasks[Self.draftProcessingKey] = nil
        if draft?.photo?.state == .processing {
            draft?.photo?.state = .originalOnly
        }
    }

    /// Removes unsaved draft photo files and cancels draft work.
    func discardDraft() {
        cancelDraftProcessing()
        suggestionTask?.cancel()
        suggestionTask = nil
        if let photo = draft?.photo {
            GarmentEditorPhotoFiles.delete(photo.originalFilename)
            GarmentEditorPhotoFiles.delete(photo.processedFilename)
        }
        draft = nil
    }

    /// Starts simulated cleanup for a saved garment's current photo. Explicit button only.
    func startGarmentProcessing(_ id: String, store: DemoStore, fast: Bool, simulateFailure: Bool) {
        guard let g = store.garment(id), let active = g.photoFilename else { return }
        let original = GarmentEditorPhotoFiles.originalName(for: active)
        processingIDs.insert(id)
        processingFailures[id] = nil
        let backdrop = GarmentEditorPhotoProcessor.backdrop()
        processingTasks[id]?.cancel()
        processingTasks[id] = Task { @MainActor [weak self] in
            let outcome = await GarmentEditorPhotoProcessor.run(original: original, fast: fast, simulateFailure: simulateFailure, backdrop: backdrop)
            guard let self else { return }
            let stillWanted = self.processingIDs.contains(id)
            self.processingIDs.remove(id)
            self.processingTasks[id] = nil
            guard stillWanted, let current = store.garment(id), let currentActive = current.photoFilename,
                  GarmentEditorPhotoFiles.originalName(for: currentActive) == original else {
                if case let .success(name) = outcome, store.garment(id)?.photoFilename != name { GarmentEditorPhotoFiles.delete(name) }
                return
            }
            switch outcome {
            case let .success(name):
                GarmentEditorImageCache.forget(name)
                store.updateGarment(id) { $0.processing = .ready }
                UIAccessibility.post(notification: .announcement, argument: "Processed version ready. Your original is unchanged.")
            case let .failed(reason):
                self.processingFailures[id] = reason
                store.updateGarment(id) { $0.processing = .failed }
                UIAccessibility.post(notification: .announcement, argument: "Processing failed. Original kept.")
            case .cancelled:
                break
            }
        }
    }

    func cancelGarmentProcessing(_ id: String) {
        processingTasks[id]?.cancel()
        processingTasks[id] = nil
        processingIDs.remove(id)
    }
}
