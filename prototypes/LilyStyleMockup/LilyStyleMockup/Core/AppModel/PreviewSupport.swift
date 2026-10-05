import SwiftUI

/// Drag-and-drop payloads (iPad). Garments drag as a plain string "garment:<id>".
enum DragPayload {
    static func garment(_ id: String) -> String { "garment:\(id)" }

    static func garmentID(from string: String) -> String? {
        guard string.hasPrefix("garment:") else { return nil }
        return String(string.dropFirst("garment:".count))
    }
}

extension AppModel {
    /// Fixture-backed model for `#Preview` blocks. Uses fictional demo data only.
    static var preview: AppModel {
        let model = AppModel(store: DemoStore(snapshot: DemoFixtures.snapshot()), fastMocks: true)
        model.weather = WeatherSnapshot(temperatureF: 58, condition: .rain, season: .fall, source: .simulatedForecast)
        return model
    }
}

extension View {
    /// Injects a preview `AppModel` for `#Preview` blocks.
    func previewEnvironment(_ model: AppModel = .preview) -> some View {
        environment(model).tint(Palette.primaryAction)
    }
}
