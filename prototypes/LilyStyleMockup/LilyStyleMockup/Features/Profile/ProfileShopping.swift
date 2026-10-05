import SwiftUI

/// Profile → Shopping: editable preferred retailers (Prefer / Neutral / Avoid),
/// order, retailer-only mode and shipping country. Discovery preferences only;
/// fit evidence still decides a recommendation.
struct ProfileShoppingSection: View {
    @Environment(AppModel.self) private var app

    static let shippingCountries = ["United States", "Canada", "United Kingdom", "Australia", "Other"]

    var body: some View {
        @Bindable var ui = app.profileUI
        let profile = app.store.profile
        Section {
            ForEach(profile.retailers) { retailer in
                ProfileRetailerRow(retailer: retailer)
            }
            .onMove { offsets, destination in
                app.profileSave(message: "Store order saved on this device") {
                    $0.retailers.move(fromOffsets: offsets, toOffset: destination)
                }
            }
            .onDelete { offsets in
                let current = app.store.profile.retailers
                let removed = offsets.filter { current.indices.contains($0) }.map { current[$0] }
                app.profileDeleteRetailers(removed)
            }

            ProfileAddField(placeholder: "Add another store", text: $ui.newRetailer, identifier: "retailerAdd") {
                addRetailer()
            }
            .padding(.vertical, Spacing.xxs)

            Toggle(isOn: Binding(
                get: { app.store.profile.retailerOnlyMode },
                set: { on in app.profileSave { $0.retailerOnlyMode = on } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Only these retailers")
                        .foregroundStyle(Palette.primaryText)
                    Text(profile.retailerOnlyMode
                         ? "Find One looks only at stores on this list that aren't set to Avoid."
                         : "Off: other permitted stores can appear when they have stronger fit evidence.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("retailerOnlyToggle")

            HStack(spacing: Spacing.xxs) {
                ProfileInfoLabel(title: "Ships to", info: "Separate from your weather location.")
                Spacer(minLength: Spacing.xs)
                Picker("Ships to", selection: Binding(
                    get: { app.store.profile.shippingCountry },
                    set: { country in app.profileSave { $0.shippingCountry = country } }
                )) {
                    ForEach(countries(including: profile.shippingCountry), id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Ships to")
                .accessibilityIdentifier("profileShippingCountry")
            }
            .frame(minHeight: HitTarget.minimum)
        } header: {
            ProfileListHeader(
                "Shopping",
                subtitle: "For Find One. Fit still comes first.",
                info: "Preferences guide discovery; fit evidence still comes first. A preferred store never outranks a better-fitting option from another store. Changing these never starts a search.\n\nThese are for Find One, only when you ask. Order is a tie-break after fit. Use Edit to reorder or remove stores, or the row actions with VoiceOver.",
                systemImage: "bag"
            ) {
                EditButton()
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("Reorder or remove stores")
                    .accessibilityIdentifier("retailerReorder")
            }
        }
        .listRowBackground(Palette.surface)
    }

    private func countries(including current: String) -> [String] {
        Self.shippingCountries.contains(current) ? Self.shippingCountries : [current] + Self.shippingCountries
    }

    private func addRetailer() {
        let name = app.profileUI.newRetailer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        app.profileUI.newRetailer = ""
        if app.store.profile.retailers.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            app.showToast("\(name) is already on your list.", style: .info)
            return
        }
        app.profileSave { $0.retailers.append(RetailerPreference(name: name, isPreferred: false, isAvoided: false)) }
    }
}

extension AppModel {
    /// Removes stores from the list with a bounded Undo that re-adds only missing ones.
    func profileDeleteRetailers(_ removed: [RetailerPreference]) {
        guard !removed.isEmpty else { return }
        let positions = removed.compactMap { r in store.profile.retailers.firstIndex { $0.name == r.name } }
        store.updateProfile { profile in
            profile.retailers.removeAll { r in removed.contains { $0.name == r.name } }
        }
        store.pushUndo(UndoEntry(label: "Remove store") { store in
            let missing = zip(removed, positions).filter { pair in
                !store.profile.retailers.contains { $0.name.caseInsensitiveCompare(pair.0.name) == .orderedSame }
            }
            guard !missing.isEmpty else { return "Those stores are already on your list." }
            store.updateProfile { profile in
                for (retailer, position) in missing.sorted(by: { $0.1 < $1.1 }) {
                    profile.retailers.insert(retailer, at: min(position, profile.retailers.count))
                }
            }
            return "Store restored."
        })
        if store.lastSaveError != nil {
            profileConfirmSave("")
        } else {
            let names = removed.map(\.name).joined(separator: ", ")
            showUndoToast("Removed \(names). Saved on this device")
        }
    }
}

/// One store: name plus a Prefer / Neutral / Avoid menu, with VoiceOver move actions.
struct ProfileRetailerRow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var retailer: RetailerPreference

    var body: some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        layout {
            HStack(spacing: Spacing.xs) {
                Image(systemName: retailer.profileStance.systemImage)
                    .foregroundStyle(retailer.profileStance == .avoid ? Palette.error : Palette.primaryAction)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(retailer.name)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
            }
            .accessibilityHidden(true)
            if !stacked { Spacer(minLength: Spacing.xs) }
            Picker(selection: Binding(
                get: { retailer.profileStance },
                set: { stance in setStance(stance) }
            )) {
                ForEach(ProfileRetailerStance.allCases) { stance in
                    Label(stance.label, systemImage: stance.systemImage).tag(stance)
                }
            } label: {
                Text("Preference for \(retailer.name)")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(minHeight: HitTarget.minimum)
            .accessibilityLabel("\(retailer.name) preference")
            .accessibilityValue(retailer.profileStance.label)
            .accessibilityIdentifier("retailerToggle-\(retailer.name)")
            .accessibilityAction(named: "Move up") { move(by: -1) }
            .accessibilityAction(named: "Move down") { move(by: 1) }
        }
        .frame(minHeight: HitTarget.minimum)
    }

    private func setStance(_ stance: ProfileRetailerStance) {
        guard stance != retailer.profileStance else { return }
        let name = retailer.name
        app.profileSave(message: "\(name): \(stance.label). Saved on this device") { profile in
            if let i = profile.retailers.firstIndex(where: { $0.name == name }) {
                profile.retailers[i].profileSetStance(stance)
            }
        }
    }

    private func move(by delta: Int) {
        let name = retailer.name
        guard let i = app.store.profile.retailers.firstIndex(where: { $0.name == name }) else { return }
        let target = i + delta
        guard target >= 0, target < app.store.profile.retailers.count else { return }
        app.profileSave(message: "Store order saved on this device") { $0.retailers.swapAt(i, target) }
    }
}

#Preview("Shopping") {
    NavigationStack {
        List {
            ProfileShoppingSection()
        }
        .scrollContentBackground(.hidden)
        .themedScreenBackground()
    }
    .previewEnvironment()
}
