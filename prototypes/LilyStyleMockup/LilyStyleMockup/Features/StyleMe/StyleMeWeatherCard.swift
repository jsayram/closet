import SwiftUI

/// One-line weather summary under the title. Tapping it opens the details sheet; it never
/// calls the weather service itself.
struct StyleMeWeatherSummaryButton: View {
    @Environment(AppModel.self) private var app

    private enum Line {
        case loading
        case automatic(WeatherSnapshot, refreshFailed: Bool)
        case setByYou(WeatherSnapshot)
        case unavailable(Season)
    }

    var body: some View {
        let line = currentLine
        Button {
            app.styleMeUI.showWeatherSheet = true
        } label: {
            HStack(spacing: Spacing.xs) {
                icon(line)
                    .frame(minWidth: 24)
                Text(text(line))
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
            }
            .frame(minHeight: HitTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(spokenLabel(line))
        .accessibilityHint("Shows details, edit and refresh")
        .accessibilityIdentifier("weatherSummaryButton")
    }

    private var currentLine: Line {
        if let override = app.style.draft.weatherOverride { return .setByYou(override) }
        // Nothing loaded and nothing failed yet means the first automatic load is on its way.
        if app.isLoadingWeather || (app.weather == nil && app.weatherError == nil) { return .loading }
        let weather = app.effectiveWeather
        if weather.source == .seasonOnly { return .unavailable(weather.season) }
        return .automatic(weather, refreshFailed: app.weatherError != nil)
    }

    @ViewBuilder
    private func icon(_ line: Line) -> some View {
        switch line {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .tint(Palette.primaryAction)
        case let .automatic(weather, _), let .setByYou(weather):
            Image(systemName: weather.condition.systemImage)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryAction)
        case .unavailable:
            Image(systemName: "exclamationmark.circle")
                .font(.subheadline)
                .foregroundStyle(Palette.primaryAction)
        }
    }

    private func text(_ line: Line) -> String {
        switch line {
        case .loading:
            "Checking the weather…"
        case let .automatic(weather, refreshFailed):
            refreshFailed
                ? "\(weather.temperatureF)°F · \(weather.condition.label) · couldn't refresh"
                : "\(weather.temperatureF)°F · \(weather.condition.label) today"
        case let .setByYou(weather):
            "\(weather.temperatureF)°F · \(weather.condition.label) · set by you"
        case let .unavailable(season):
            "Weather unavailable · using \(season.label)"
        }
    }

    private func spokenLabel(_ line: Line) -> String {
        switch line {
        case .loading:
            return "Checking the weather"
        case let .automatic(weather, refreshFailed):
            return "Weather: \(spoken(weather)). Simulated." + (refreshFailed ? " The last refresh didn't work." : "")
        case let .setByYou(weather):
            return "Weather: \(spoken(weather)). Set by you."
        case let .unavailable(season):
            return "Weather unavailable. Using \(season.label.lowercased())."
        }
    }

    private func spoken(_ weather: WeatherSnapshot) -> String {
        "\(weather.temperatureF) degrees, \(weather.condition.label.lowercased()), \(weather.season.label.lowercased())"
    }
}

/// Sheet opened from the weather line: conditions, source, edit, reset and Refresh.
struct StyleMeWeatherSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                StyleMeWeatherDetails()
                    .padding(Spacing.m)
                    .readableWidth(640)
            }
            .themedScreenBackground()
            .navigationTitle("Weather & season")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
            .overlay(alignment: .bottom) { StyleMeSheetToast() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Weather & season: automatic (simulated) with an editable per-request override (FR-04, FR-16, FR-48).
/// Refresh is the only control here that calls the (simulated) weather service.
struct StyleMeWeatherDetails: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let weather = app.effectiveWeather
        let hasOverride = app.style.draft.weatherOverride != nil
        let isEditing = app.styleMeUI.isEditingWeather
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                Label {
                    Text(weather.summary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: weather.condition.systemImage)
                        .foregroundStyle(Palette.primaryAction)
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(weather.temperatureF) degrees Fahrenheit, \(weather.condition.label), \(weather.season.label)")
                Spacer(minLength: Spacing.xs)
                if app.isLoadingWeather {
                    ProgressView()
                        .tint(Palette.primaryAction)
                        .accessibilityLabel("Loading weather")
                }
            }

            BadgeRow(badges: sourceBadges(weather))

            CollapsibleText(sourceLine(weather), threshold: 1, topic: "where this weather comes from",
                            isExpanded: app.styleMeUI.disclosure("weatherSource"))

            if hasOverride, let automatic = app.weather {
                Text("Automatic: \(automatic.summary). Not used while you've set conditions.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = app.weatherError {
                InlineBanner(style: .caution, title: "Weather isn't available", message: error)
            }

            if isEditing {
                StyleMeWeatherEditor()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }

            // Two buttons at most. While she has set conditions herself, going back to automatic is the
            // likelier next step, so Refresh moves into More.
            if hasOverride {
                ActionGroup(moreIdentifier: "weatherMoreButton") {
                    editButton(isEditing: isEditing)
                    Button {
                        app.style.draft.weatherOverride = nil
                        app.styleMeUI.isEditingWeather = false
                    } label: {
                        Label("Use automatic", systemImage: "location")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("weatherUseAutomaticButton")
                } more: {
                    Button("Refresh", systemImage: "arrow.clockwise") { app.refreshWeather() }
                        .disabled(app.isLoadingWeather)
                        .accessibilityHint("Gets simulated current conditions")
                        .accessibilityIdentifier("weatherRefreshButton")
                }
            } else {
                ActionGroup {
                    editButton(isEditing: isEditing)
                    Button {
                        app.refreshWeather()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(app.isLoadingWeather)
                    .accessibilityHint("Gets simulated current conditions")
                    .accessibilityIdentifier("weatherRefreshButton")
                }
            }

            Label("Simulated weather (WeatherKit not connected)", systemImage: "flask")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weatherCard")
    }

    private func editButton(isEditing: Bool) -> some View {
        Button {
            Motion.perform(reduceMotion: reduceMotion) { app.styleMeUI.isEditingWeather.toggle() }
        } label: {
            Label(isEditing ? "Done" : "Edit", systemImage: isEditing ? "checkmark" : "slider.horizontal.3")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint(isEditing ? "Closes the weather editor" : "Set temperature, conditions or season for this request")
        .accessibilityIdentifier("weatherEditButton")
    }

    private func isStale(_ weather: WeatherSnapshot) -> Bool {
        weather.source == .simulatedForecast && Date.now.timeIntervalSince(weather.fetchedAt) > 1800
    }

    private func sourceBadges(_ weather: WeatherSnapshot) -> [BadgeKind] {
        var badges: [BadgeKind]
        switch weather.source {
        case .simulatedForecast: badges = [.simulated]
        case .manual: badges = [.custom("Set by you", "pencil")]
        case .seasonOnly: badges = [.custom("Season only", "leaf")]
        }
        if isStale(weather) { badges.append(.custom("Stale", "clock.badge.exclamationmark")) }
        return badges
    }

    private func sourceLine(_ weather: WeatherSnapshot) -> String {
        // Always lead with the canonical source label so the source is stated in words, not only badges.
        let source = weather.source.label
        switch weather.source {
        case .simulatedForecast:
            let updated = weather.fetchedAt.formatted(.relative(presentation: .named))
            let stale = isStale(weather) ? " Stale — tap Refresh for current conditions." : ""
            return "\(source) · \(weather.locationLabel) · updated \(updated).\(stale)"
        case .manual:
            return "\(source) for this request — handy for planning ahead or travel."
        case .seasonOnly:
            return "\(source). Set conditions yourself if you know them."
        }
    }
}

/// Inline editor. Every change writes a manual override for this request only.
struct StyleMeWeatherEditor: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let weather = app.effectiveWeather
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xxs) {
                Text("For this request only")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("editing the weather", title: "For this request only",
                           text: "Applies to this request only. Your automatic weather isn't changed.")
            }
            Stepper(value: binding(\.temperatureF), in: -10...110) {
                Text("Temperature: \(weather.temperatureF)°F")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
            }
            .accessibilityIdentifier("weatherTemperatureStepper")

            Text("Conditions")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            ChipCarousel(isExpanded: app.styleMeUI.disclosure("weatherConditionChips"), itemsLabel: "conditions") {
                ForEach(WeatherCondition.allCases) { condition in
                    CapsuleChip(title: condition.label, systemImage: condition.systemImage,
                                isSelected: weather.condition == condition) {
                        update { $0.condition = condition }
                    }
                }
            }

            StyleMeChoicePicker(title: "Season", selection: binding(\.season), options: Season.allCases,
                                label: { $0.label }, identifier: "weatherSeasonPicker")
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
    }

    private func binding<T>(_ keyPath: WritableKeyPath<WeatherSnapshot, T>) -> Binding<T> {
        Binding(
            get: { app.effectiveWeather[keyPath: keyPath] },
            set: { newValue in update { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func update(_ change: (inout WeatherSnapshot) -> Void) {
        var snapshot = app.effectiveWeather
        change(&snapshot)
        snapshot.source = .manual
        snapshot.fetchedAt = .now
        app.style.draft.weatherOverride = snapshot
    }
}
