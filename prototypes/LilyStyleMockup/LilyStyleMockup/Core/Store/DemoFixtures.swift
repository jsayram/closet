import Foundation

/// Fictional, resettable demo data. No real person, photo, account or retailer is used.
/// Lily's context: 4'11" height confirmed; inseam pre-filled at 26 in but not confirmed, so it
/// doesn't guide fit until she confirms it; waist, hip and bust Unknown. Her approximate weight
/// (about 120 lb) only feeds the rough height-and-weight size estimate until she adds measurements.
enum DemoFixtures {
    static let jose = "s-jose"
    static let weekend = "s-weekend"
    static let empty = "s-spring"

    private static func day(_ offset: Int) -> Date { Date.now.addingTimeInterval(Double(offset) * 86_400) }

    private static func c(_ name: String, _ hex: String, _ family: ColorFamily) -> GarmentColor {
        GarmentColor(name: name, hex: hex, family: family)
    }

    static func garments() -> [Garment] {
        var list: [Garment] = []

        var navy = Garment(id: "g-navy-trousers", displayName: "Navy dress pants", category: .bottom, kind: .trousers,
                           color: c("Navy", "1F2A44", .navy))
        navy.formality = .dressy
        navy.annotations = [
            .init(kind: .alias, text: "Navy trousers", provenance: .importedFixture),
            .init(kind: .detail, text: "Ankle length with flats", provenance: .importedFixture),
            .init(kind: .detail, text: "Waist sits near the navel", provenance: .importedFixture),
        ]
        navy.brand = "Demo Brand A"
        navy.sizeLabel = "2P (brand label)"
        navy.imageKind = .actualPhoto
        navy.addedAt = day(-120)
        list.append(navy)

        var olive = Garment(id: "g-olive-trousers", displayName: "Olive trousers", category: .bottom, kind: .trousers,
                            color: c("Olive", "5B6236", .olive))
        olive.formality = .smart
        olive.annotations = [.init(kind: .detail, text: "Slightly cropped", provenance: .importedFixture)]
        olive.imageKind = .actualPhoto
        olive.addedAt = day(-90)
        list.append(olive)

        var pink = Garment(id: "g-pink-blouse", displayName: "Cute pink shirt", category: .top, kind: .blouse,
                           color: c("Light pink", "F2C4CE", .pink))
        pink.formality = .dressy
        pink.annotations = [
            .init(kind: .alias, text: "Date-night top", provenance: .importedFixture),
            .init(kind: .detail, text: "Bow at the neck", provenance: .importedFixture),
        ]
        pink.imageKind = .actualPhoto
        pink.addedAt = day(-60)
        list.append(pink)

        var lace = Garment(id: "g-lace-top", displayName: "White lace top", category: .top, kind: .lacyTop,
                           color: c("Soft white", "F7F5F0", .white))
        lace.formality = .dressy
        lace.annotations = [.init(kind: .detail, text: "Ruffled neckline", provenance: .importedFixture)]
        lace.availability = .dirty
        lace.imageKind = .actualPhoto
        lace.fabric = nil
        list.append(lace)

        var cardigan = Garment(id: "g-navy-cardigan", displayName: "Navy cardigan", category: .layer, kind: .cardigan,
                               color: c("Navy", "22304A", .navy))
        cardigan.formality = .smart
        cardigan.warmth = 2
        cardigan.imageKind = .actualPhoto
        list.append(cardigan)

        var jacket = Garment(id: "g-brown-jacket", displayName: "Brown leather jacket", category: .layer, kind: .jacket,
                             color: c("Chocolate brown", "6B4226", .brown))
        jacket.formality = .smart
        jacket.warmth = 2
        jacket.annotations = [.init(kind: .detail, text: "Hits at the hip — not oversized", provenance: .importedFixture)]
        jacket.imageKind = .actualPhoto
        list.append(jacket)

        var sweater = Garment(id: "g-cream-sweater", displayName: "Cream knit sweater", category: .top, kind: .sweater,
                              color: c("Cream", "EFE6D2", .cream))
        sweater.formality = .smart
        sweater.warmth = 2
        sweater.imageKind = .actualPhoto
        list.append(sweater)

        var brick = Garment(id: "g-brick-top", displayName: "Brick knit top", category: .top, kind: .knitTop,
                            color: c("Brick", "A4492F", .brick))
        brick.formality = .smart
        brick.imageKind = .actualPhoto
        list.append(brick)

        var tee = Garment(id: "g-black-tee", displayName: "Black tee", category: .top, kind: .tee,
                          color: c("Black", "1E1E1E", .black))
        tee.formality = .casual
        tee.availability = .dirty
        tee.imageKind = .actualPhoto
        list.append(tee)

        var jeans = Garment(id: "g-wide-jeans", displayName: "Wide-leg jeans", category: .bottom, kind: .jeans,
                            color: c("Mid-wash denim", "4A6A8F", .denim))
        jeans.formality = .casual
        jeans.annotations = [
            .init(kind: .alias, text: "Baggie jeans", provenance: .importedFixture),
            .init(kind: .detail, text: "Big patch pocket on the front", provenance: .importedFixture),
        ]
        jeans.imageKind = .actualPhoto
        list.append(jeans)

        var skirt = Garment(id: "g-black-skirt", displayName: "Black midi skirt", category: .bottom, kind: .skirt,
                            color: c("Black", "1E1E1E", .black))
        skirt.formality = .dressy
        skirt.availability = .archived
        skirt.statusBeforeArchive = .available
        skirt.imageKind = .actualPhoto
        list.append(skirt)

        var dress = Garment(id: "g-blue-dress", displayName: "Blue floral dress", category: .dress, kind: .dress,
                            color: c("Cornflower blue floral", "6E8FC4", .blue))
        dress.formality = .dressy
        dress.availability = .unavailable
        dress.unavailableUntil = day(9)
        dress.notes = "At the tailor for hemming"
        dress.imageKind = .actualPhoto
        list.append(dress)

        var flats = Garment(id: "g-nude-flats", displayName: "Nude pointed flats", category: .shoes, kind: .flats,
                            color: c("Nude", "D8B79A", .beige))
        flats.formality = .dressy
        flats.imageKind = .actualPhoto
        list.append(flats)

        var heels = Garment(id: "g-black-heels", displayName: "Black block heels", category: .shoes, kind: .heels,
                            color: c("Black", "1E1E1E", .black))
        heels.formality = .dressy
        heels.annotations = [.init(kind: .detail, text: "Low 2-inch block heel", provenance: .importedFixture)]
        heels.imageKind = .actualPhoto
        list.append(heels)

        var sneakers = Garment(id: "g-white-sneakers", displayName: "White sneakers", category: .shoes, kind: .sneakers,
                               color: c("White", "F4F4F2", .white))
        sneakers.formality = .casual
        sneakers.imageKind = .actualPhoto
        list.append(sneakers)

        var loafers = Garment(id: "g-tan-loafers", displayName: "Tan loafers", category: .shoes, kind: .loafers,
                              color: c("Tan", "B08155", .tan))
        loafers.formality = .smart
        loafers.imageKind = .textOnly
        loafers.notes = "Added by text only — add a photo for actual details"
        list.append(loafers)

        var bag = Garment(id: "g-burgundy-bag", displayName: "Burgundy crossbody bag", category: .accessory, kind: .bag,
                          color: c("Burgundy", "6D2433", .burgundy))
        bag.formality = .smart
        bag.imageKind = .actualPhoto
        list.append(bag)

        var blazer = Garment(id: "g-gray-blazer", displayName: "Gray blazer", category: .layer, kind: .blazer,
                             color: c("Heather gray", "8A8D91", .gray))
        blazer.formality = .dressy
        blazer.ownership = .noLongerOwned
        blazer.notes = "Donated — sleeves were too long"
        blazer.imageKind = .actualPhoto
        list.append(blazer)

        var crop = Garment(id: "g-cream-crop", displayName: "Cream lace crop top", category: .top, kind: .lacyTop,
                           color: c("Cream", "EFE6D2", .cream))
        crop.formality = .smart
        crop.ownership = .purchasedConfirmed
        crop.arrival = .notArrived
        crop.sizeLabel = "XS (as ordered)"
        crop.sourceRetailer = "Demo Store (fictional)"
        crop.sourceURL = "https://shop.demo-store.example/lace-crop-top"
        crop.purchaseDate = day(-2)
        crop.imageKind = .textOnly
        list.append(crop)

        var trench = Garment(id: "g-camel-trench", displayName: "Camel trench coat", category: .layer, kind: .coat,
                             color: c("Camel", "B48A5A", .tan))
        trench.ownership = .wishlisted
        trench.imageKind = .representative
        list.append(trench)

        var leggings = Garment(id: "g-gray-leggings", displayName: "Old gray leggings", category: .bottom, kind: .trousers,
                               color: c("Charcoal", "4A4A4F", .gray))
        leggings.formality = .casual
        leggings.trashedAt = day(-3)
        leggings.imageKind = .textOnly
        list.append(leggings)

        return list
    }

    static func suitcases() -> [Suitcase] {
        [
            Suitcase(id: jose, name: "Jose's house", createdAt: day(-30)),
            Suitcase(id: weekend, name: "Weekend", createdAt: day(-20)),
            Suitcase(id: empty, name: "Spring trip", createdAt: day(-5)),
        ]
    }

    static func memberships() -> [SuitcaseMembership] {
        let jose: [String] = ["g-navy-trousers", "g-pink-blouse", "g-navy-cardigan", "g-nude-flats", "g-lace-top"]
        let weekend: [String] = ["g-navy-trousers", "g-olive-trousers", "g-wide-jeans", "g-brick-top", "g-cream-sweater",
                                 "g-brown-jacket", "g-white-sneakers", "g-black-tee"]
        return jose.map { SuitcaseMembership(suitcaseID: Self.jose, garmentID: $0) }
            + weekend.map { SuitcaseMembership(suitcaseID: Self.weekend, garmentID: $0) }
    }

    private static func piece(_ g: Garment, _ slot: OutfitSlot? = nil) -> OutfitPiece { OutfitPiece.from(g, slot: slot) }

    static func snapshot() -> StoreSnapshot {
        let gs = garments()
        func g(_ id: String) -> Garment { gs.first { $0.id == id }! }

        var interview = Outfit(id: "o-interview", title: "Interview navy & pink", lane: .elevated, pieces: [
            piece(g("g-navy-cardigan")), piece(g("g-pink-blouse")), piece(g("g-navy-trousers")), piece(g("g-nude-flats")),
        ])
        interview.rationale = "Navy and light pink keep it polished but soft; the cardigan handles a cool office."
        interview.colorNote = "Blue + light pink"
        interview.occasion = .office
        interview.isSaved = true
        interview.isFavorite = true
        interview.capturedScope = .mainCloset
        interview.capturedScopeName = "Main Closet"
        interview.keywords = ["interview", "work"]
        interview.createdAt = day(-40)
        interview.updatedAt = day(-40)

        var weekendLook = Outfit(id: "o-weekend", title: "Weekend olive & brick", lane: .elevatedAlternate, pieces: [
            piece(g("g-brown-jacket")), piece(g("g-brick-top")), piece(g("g-olive-trousers")), piece(g("g-white-sneakers")),
        ])
        weekendLook.rationale = "Muted olive with brick feels warm and intentional without being loud."
        weekendLook.colorNote = "Olive + brick"
        weekendLook.occasion = .casual
        weekendLook.isSaved = true
        weekendLook.capturedScope = .suitcase(weekend)
        weekendLook.capturedScopeName = "Weekend"
        weekendLook.createdAt = day(-15)
        weekendLook.updatedAt = day(-15)

        var lace = Outfit(id: "o-lace-date", title: "Lace date night", lane: .manual, pieces: [
            piece(g("g-lace-top")), piece(g("g-black-skirt")), piece(g("g-black-heels")), piece(g("g-burgundy-bag")),
        ])
        lace.rationale = "Saved by you."
        lace.occasion = .dateNight
        lace.isSaved = true
        lace.capturedScope = .mainCloset
        lace.capturedScopeName = "Main Closet"
        lace.createdAt = day(-70)
        lace.updatedAt = day(-70)

        var blazerLook = Outfit(id: "o-blazer", title: "Gray blazer office", lane: .safeSimple, pieces: [
            piece(g("g-gray-blazer")), piece(g("g-cream-sweater")), piece(g("g-navy-trousers")), piece(g("g-black-heels")),
        ])
        blazerLook.rationale = "A classic neutral office look."
        blazerLook.occasion = .office
        blazerLook.isSaved = true
        blazerLook.capturedScope = nil
        blazerLook.capturedScopeName = nil
        blazerLook.createdAt = day(-200)
        blazerLook.updatedAt = day(-200)

        let outfits = [interview, weekendLook, lace, blazerLook]

        func key(_ o: Outfit, ref: Int = 1) -> String {
            o.renderKey(referenceVersion: ref, appearanceRevisions: Dictionary(uniqueKeysWithValues: gs.map { ($0.id, $0.appearanceRevision) }))
        }

        var earlierInterview = interview
        earlierInterview.pieces = [piece(g("g-pink-blouse")), piece(g("g-navy-trousers")), piece(g("g-black-heels"))]
        let previews: [PreviewEntry] = [
            PreviewEntry(id: "p-interview-current", outfitID: interview.id, outfitRevision: 2, title: interview.title, lane: .elevated,
                         snapshotPieces: interview.pieces, referenceVersion: 1, renderKey: key(interview), isFavorite: true,
                         keywords: ["navy", "pink", "office"], capturedScope: .mainCloset, capturedScopeName: "Main Closet",
                         occasion: .office, createdAt: day(-40)),
            PreviewEntry(id: "p-interview-earlier", outfitID: interview.id, outfitRevision: 1, title: interview.title + " (earlier)", lane: .elevated,
                         snapshotPieces: earlierInterview.pieces, referenceVersion: 1, renderKey: key(earlierInterview),
                         keywords: ["navy", "pink", "heels"], capturedScope: .mainCloset, capturedScopeName: "Main Closet",
                         occasion: .office, createdAt: day(-41)),
            PreviewEntry(id: "p-weekend-disliked", outfitID: weekendLook.id, outfitRevision: 1, title: weekendLook.title, lane: .elevatedAlternate,
                         snapshotPieces: weekendLook.pieces, referenceVersion: 1, renderKey: key(weekendLook), isDisliked: true,
                         keywords: ["olive", "brick", "weekend"], capturedScope: .suitcase(weekend), capturedScopeName: "Weekend",
                         occasion: .casual, createdAt: day(-15)),
            PreviewEntry(id: "p-lace-mismatch", outfitID: lace.id, outfitRevision: 1, title: lace.title, lane: .manual,
                         snapshotPieces: lace.pieces, referenceVersion: 1, renderKey: key(lace), quality: .appearanceMismatch,
                         keywords: ["lace", "black", "date night"], capturedScope: .mainCloset, capturedScopeName: "Main Closet",
                         occasion: .dateNight, createdAt: day(-70)),
        ]

        let collections = [
            OutfitCollection(id: "c-work", name: "Work", outfitIDs: [interview.id, blazerLook.id], previewIDs: ["p-interview-current"], createdAt: day(-50)),
            OutfitCollection(id: "c-gym", name: "Gym", createdAt: day(-50)),
            OutfitCollection(id: "c-going-out", name: "Going Out", outfitIDs: [weekendLook.id, lace.id], previewIDs: ["p-lace-mismatch"], createdAt: day(-50)),
        ]

        // Six-month-old structured history for Date Night (no raw prompt text retained).
        var dateLook = Outfit(id: "o-history-date", title: "Pink & black date night", lane: .elevated, pieces: [
            piece(g("g-pink-blouse")), piece(g("g-navy-trousers")), piece(g("g-black-heels")), piece(g("g-burgundy-bag")),
        ])
        dateLook.rationale = "Light pink against navy with a burgundy bag: soft, cohesive and a little unexpected."
        dateLook.colorNote = "Navy + light pink + burgundy"
        dateLook.occasion = .dateNight
        dateLook.capturedScope = .mainCloset
        dateLook.capturedScopeName = "Main Closet"
        let history = [
            StylingHistoryEntry(outfitSnapshot: dateLook, occasion: .dateNight, scope: .mainCloset, mode: .suggestions,
                                startingItemID: nil, requiredColor: nil, capturedAt: day(-183), feedback: .liked),
        ]

        var profile = UserProfile()
        profile.measurements = [
            MeasurementFact(dimension: .height, value: 59, unit: .inches, basis: .body, provenance: "Confirmed by Lily", confirmed: true),
            MeasurementFact(dimension: .inseam, value: 26, unit: .inches, basis: .preferredGarment, provenance: "Pre-filled from earlier notes", confirmed: false),
        ]
        profile.weight = BodyWeight(value: 120, unit: .pounds, approximate: true, updatedAt: day(-30))
        profile.fitReferences = [
            FitReference(brand: "Demo Brand A", category: .bottom, sizeLabel: "2P", result: .fitsWell, areas: [.waist], note: "Waist fits; length fine with flats", garmentID: "g-navy-trousers"),
            FitReference(brand: "Demo Brand B", category: .layer, sizeLabel: "S", result: .tooLong, areas: [.jacketLength, .sleeve], note: "Looked oversized", garmentID: "g-gray-blazer"),
        ]

        let ideas: [FeedbackIdea] = [
            FeedbackIdea(id: "i-1", title: "Plan outfits for a whole trip", body: "Pick looks for each day of a trip from one suitcase.", topic: "Suitcases", status: .planned, votes: 42, publicAlias: "plum-sparrow", createdAt: day(-20)),
            FeedbackIdea(id: "i-2", title: "Show which shoes work with each pant length", body: "A quick hint about hem and shoe height.", topic: "Fit", status: .underReview, votes: 31, publicAlias: "quiet-fern", createdAt: day(-12)),
            FeedbackIdea(id: "i-3", title: "Weekly outfit worksheet", body: "Printable plan for the week.", topic: "Planning", status: .inProgress, votes: 18, publicAlias: "linen-owl", createdAt: day(-9)),
            FeedbackIdea(id: "i-4", title: "Dark mode garment backgrounds", body: "Keep garment colors true in dark mode.", topic: "Design", status: .released, votes: 27, publicAlias: "navy-heron", createdAt: day(-40)),
            FeedbackIdea(id: "i-5", title: "Public outfit feed", body: "Share looks with followers.", topic: "Social", status: .notPlanned, votes: 6, publicAlias: "amber-wren", createdAt: day(-33)),
        ]

        // One saved-for-later product reference (fictional .example source, not owned).
        let savedIntent = PublicShoppingIntent(garment: "blouse", color: "Light pink", budgetMax: 80, shipsTo: "United States",
                                               preferredRetailers: profile.retailers.map(\.name), retailerOnly: false)
        let savedProducts = MockWebSearch.leads(for: savedIntent).prefix(1).map { lead in
            SavedProductReference(candidate: MockShoppingRanker.classify(lead, profile: profile), savedAt: day(-4),
                                  context: FindOneContext(outfitID: nil, slot: .top, description: "blouse", kind: .blouse, colorFamily: .pink, scope: .mainCloset))
        }

        var snapshot = StoreSnapshot()
        snapshot.savedProducts = Array(savedProducts)
        snapshot.garments = gs
        snapshot.suitcases = suitcases()
        snapshot.memberships = memberships()
        snapshot.outfits = outfits
        snapshot.collections = collections
        snapshot.previews = previews
        snapshot.history = history
        snapshot.profile = profile
        snapshot.ideas = ideas
        snapshot.submissions = [MySubmission(title: "Remember my favorite flats per suitcase", body: "…", state: .pendingModeration, submittedAt: day(-1))]
        snapshot.reminders = [PurchaseReminder(garmentID: "g-cream-crop", kind: .arrival), PurchaseReminder(garmentID: "g-cream-crop", kind: .photo)]
        snapshot.rememberedScope = .mainCloset
        snapshot.access = AccessState()
        snapshot.sync = SyncState()
        return snapshot
    }

    static let releaseNotes: [ReleaseNote] = [
        ReleaseNote(version: "0.1 (prototype)", date: .now, changes: [
            "Interactive iPhone and iPad prototype with fictional data.",
            "Style Me with Safe / Simple and Elevated owned looks, swaps, saving and retained preview history.",
            "Closet, Suitcases, laundry, unified search, Find One and Ask another stylist simulations.",
        ], knownLimitations: [
            "All AI, image, search, weather, sync and billing behavior is simulated.",
            "Garment pictures are illustrated stand-ins, not photos.",
            "On Me previews are placeholder figures — not a real person and not a fit preview.",
        ]),
    ]
}
