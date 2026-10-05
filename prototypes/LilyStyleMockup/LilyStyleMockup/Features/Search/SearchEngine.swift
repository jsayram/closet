import Foundation

// Deterministic local search. Pure functions over value types: no AppModel, no
// services, no network, no persistence and no query log. The same input always
// produces the same ranked output.

// MARK: - Vocabulary (versioned and bounded)

enum SearchVocabulary {
    static let version = "search-vocabulary-1"

    /// Filler words ignored outside quoted phrases.
    static let stopwords: Set<String> = ["the", "a", "an", "my", "with", "that", "and", "for", "of", "in", "on"]

    /// Words that negate the next content word (also supported: a leading "-").
    static let negationWords: Set<String> = ["not", "without", "no"]

    /// Reviewed clothing synonym groups. Cardigan and sweater stay distinct on purpose.
    static let synonymGroups: [[String]] = [
        ["pants", "trousers", "slacks"],
        ["tee", "tshirt"],
        ["shirt", "top", "blouse"],
        ["sneakers", "trainers"],
        ["jacket", "coat"],
        ["jeans", "denim"],
    ]

    /// One-directional category words: searching "shoes" also finds flats, heels…,
    /// but searching "heels" never returns flats.
    static let categoryWords: [String: [String]] = [
        "shoes": ["flats", "heels", "loafers", "sneakers", "trainers", "boots"],
    ]

    /// Bounded spelling variants, mapped to one canonical form. Stored wording is never changed.
    static let spellingVariants: [String: String] = [
        "baggie": "baggy",
        "baggies": "baggy",
        "lacy": "lace",
        "ruffles": "ruffle",
        "ruffled": "ruffle",
        "ruffly": "ruffle",
        "colour": "color",
        "colours": "color",
        "grey": "gray",
        "favourite": "favorite",
        "favourites": "favorite",
    ]

    static let maxQueryLength = 120
    static let maxTerms = 12
    static let maxPhrases = 3
    static let maxNegations = 6
    static let maxPossibleMatches = 8

    /// Stem → synonym group index.
    static let synonymIndex: [String: Int] = {
        var map: [String: Int] = [:]
        for (i, group) in synonymGroups.enumerated() {
            for word in group { map[SearchText.stem(word)] = i }
        }
        return map
    }()

    static let categoryIndex: [String: Set<String>] = {
        var map: [String: Set<String>] = [:]
        for (word, members) in categoryWords {
            map[SearchText.stem(word)] = Set(members.map(SearchText.stem))
        }
        return map
    }()

    /// Normalized colour-family names → family, for the labelled related-shade expansion.
    static let colorFamilyIndex: [String: ColorFamily] = {
        var map: [String: ColorFamily] = [:]
        for family in ColorFamily.allCases {
            map[SearchText.stem(SearchText.normalize(family.label))] = family
        }
        return map
    }()
}

// MARK: - Normalization

enum SearchText {
    /// Lowercases, folds accents, drops apostrophes, turns other punctuation into
    /// spaces and collapses whitespace.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
        var scalars = String.UnicodeScalarView()
        var lastWasSpace = true
        for scalar in folded.unicodeScalars {
            if scalar == "'" || scalar == "\u{2019}" { continue }
            if CharacterSet.alphanumerics.contains(scalar) {
                scalars.append(scalar)
                lastWasSpace = false
            } else if !lastWasSpace {
                scalars.append(" ")
                lastWasSpace = true
            }
        }
        var result = String(scalars)
        if result.hasSuffix(" ") { result.removeLast() }
        return result
    }

    /// Splits normalized text into tokens, joining "t shirt" into "tshirt".
    static func tokens(_ normalized: String) -> [String] {
        let raw = normalized.split(separator: " ").map(String.init)
        var result: [String] = []
        var i = 0
        while i < raw.count {
            if raw[i] == "t", i + 1 < raw.count, raw[i + 1] == "shirt" || raw[i + 1] == "shirts" {
                result.append(raw[i + 1] == "shirt" ? "tshirt" : "tshirts")
                i += 2
            } else {
                result.append(raw[i])
                i += 1
            }
        }
        return result
    }

    /// Bounded stem: spelling variants plus simple plural tolerance.
    static func stem(_ token: String) -> String {
        if let variant = SearchVocabulary.spellingVariants[token] { return variant }
        guard token.count > 3, token.hasSuffix("s"), !token.hasSuffix("ss") else { return token }
        let base = token.hasSuffix("sses") ? String(token.dropLast(2)) : String(token.dropLast())
        return SearchVocabulary.spellingVariants[base] ?? base
    }

    /// Word-boundary containment within one field (never across fields).
    static func contains(_ field: String, phrase: String, openEnded: Bool) -> Bool {
        guard !phrase.isEmpty else { return false }
        let haystack = " \(field) "
        return haystack.contains(openEnded ? " \(phrase)" : " \(phrase) ")
    }
}

// MARK: - Query

struct SearchPhrase: Hashable {
    var text: String
    /// True while the closing quote hasn't been typed yet (last word may be partial).
    var isOpen: Bool
}

struct SearchParsedQuery: Hashable {
    var raw: String = ""
    /// Normalized content terms outside quotes (stopwords removed, deduplicated).
    var terms: [String] = []
    var phrases: [SearchPhrase] = []
    var negated: [String] = []
    var ignoredStopwords: [String] = []
    /// The last term may still be being typed, so it also matches word starts.
    var prefixTerm: String?
    var wasTruncated = false

    var hasContent: Bool { !terms.isEmpty || !phrases.isEmpty }

    /// Words from quoted phrases, used only for the separately labelled possible-match tier.
    var phraseWords: [String] {
        var words: [String] = []
        for phrase in phrases {
            for token in SearchText.tokens(phrase.text) where !SearchVocabulary.stopwords.contains(token) && !terms.contains(token) && !words.contains(token) {
                words.append(token)
            }
        }
        return words
    }

    /// Every content word considered for possible matches.
    var allWords: [String] { terms + phraseWords }

    /// Terms joined, compared with a name's content words for exact-name ranking.
    var contentKey: String { terms.joined(separator: " ") }

    /// Multi-word content query (for Remember this name).
    var isMultiWord: Bool { allWords.count >= 2 }
}

// MARK: - Matches and output

enum SearchMatchKind: Int, Comparable, Hashable {
    case phrase, exact, variant, synonym, prefix, relatedShade

    static func < (lhs: SearchMatchKind, rhs: SearchMatchKind) -> Bool { lhs.rawValue < rhs.rawValue }

    var multiplier: Double {
        switch self {
        case .phrase: 1.2
        case .exact: 1.0
        case .variant: 0.85
        case .synonym: 0.75
        case .prefix: 0.65
        case .relatedShade: 0.4
        }
    }

    /// Short explanation shown beside non-exact matches.
    var explanation: String? {
        switch self {
        case .phrase: "exact phrase"
        case .exact: nil
        case .variant: "spelling or plural variant"
        case .synonym: "clothing synonym"
        case .prefix: "start of a word"
        case .relatedShade: "related shade — confirmed color unchanged"
        }
    }
}

struct SearchTermMatch: Hashable {
    /// The query word (or quoted phrase).
    let term: String
    let kind: SearchMatchKind
    let field: SearchField
    /// The indexed word that matched.
    let matchedWord: String

    var score: Double { field.role.weight * kind.multiplier }
}

enum SearchTier: Hashable {
    /// Every content word and quoted phrase matched directly.
    case primary
    /// Every word matched, but at least one only through a related colour family.
    case relatedShade
    /// Some words matched; shown only when nothing else did.
    case possible
    /// No query text, only explicit filters.
    case browse
}

struct SearchHit: Identifiable, Hashable {
    let document: SearchDocument
    let tier: SearchTier
    /// One best match per matched word/phrase.
    let matches: [SearchTermMatch]
    let unmatchedWords: [String]
    /// 0 exact name/alias/phrase · 1 direct exact · 2 synonym/variant/prefix · 3 linked piece · 4 related shade.
    let rank: Int
    let score: Double

    var id: String { document.id }

    var matchedWords: [String] { matches.filter { $0.kind != .phrase }.map(\.term) }

    /// Unique matched fields, strongest first: "Matched other name “Baggie jeans”".
    var provenanceLines: [String] {
        var seen = Set<String>()
        var lines: [String] = []
        for match in matches.sorted(by: { ($0.field.role, $0.kind) < ($1.field.role, $1.kind) }) {
            let line = "Matched \(match.field.provenance)"
            if seen.insert(line).inserted { lines.append(line) }
        }
        return lines
    }
}

struct SearchOutput {
    var query = SearchParsedQuery()
    var primary: [SearchHit] = []
    var relatedShade: [SearchHit] = []
    var possible: [SearchHit] = []
    /// Full matches excluded by explicit facets (never removed silently).
    var hiddenByFilters = 0
    var hiddenReasons: [SearchFacetKind] = []
    /// Full garment matches outside the selected suitcase source.
    var hiddenBySource = 0
    /// Full matches per type with every facet except Type applied.
    var typeCounts: [SearchResultType: Int] = [:]
    /// Quoted phrases no single indexed field contains.
    var phrasesNotFound: [String] = []
    var isBrowsing = false

    var isIdle: Bool { !query.hasContent && !isBrowsing }
    var hasDirectResults: Bool { !primary.isEmpty || !relatedShade.isEmpty }
    var allHits: [SearchHit] { primary + relatedShade + possible }
}

// MARK: - Engine

enum SearchEngine {
    /// Parses raw input into bounded terms, quoted phrases and negations.
    static func parse(_ input: String) -> SearchParsedQuery {
        var query = SearchParsedQuery(raw: input)
        var text = input
        if text.count > SearchVocabulary.maxQueryLength {
            text = String(text.prefix(SearchVocabulary.maxQueryLength))
            query.wasTruncated = true
        }

        // Separate quoted phrases from the rest. Quote marks become spaces outside.
        var outside = ""
        var current = ""
        var inQuote = false
        for ch in text {
            if ch == "\"" || ch == "\u{201C}" || ch == "\u{201D}" {
                if inQuote {
                    let normalized = SearchText.normalize(current)
                    if !normalized.isEmpty { query.phrases.append(SearchPhrase(text: normalized, isOpen: false)) }
                    current = ""
                }
                inQuote.toggle()
                outside.append(" ")
            } else if inQuote {
                current.append(ch)
            } else {
                outside.append(ch)
            }
        }
        if inQuote {
            let normalized = SearchText.normalize(current)
            if !normalized.isEmpty { query.phrases.append(SearchPhrase(text: normalized, isOpen: true)) }
        }
        if query.phrases.count > SearchVocabulary.maxPhrases {
            query.phrases = Array(query.phrases.prefix(SearchVocabulary.maxPhrases))
            query.wasTruncated = true
        }

        let rawTokens = outside.split(whereSeparator: \.isWhitespace).map(String.init)
        var pendingNegation = false
        for rawToken in rawTokens {
            if rawToken.hasPrefix("-"), rawToken.count > 1 {
                for token in SearchText.tokens(SearchText.normalize(String(rawToken.dropFirst()))) where !query.negated.contains(token) {
                    query.negated.append(token)
                }
                pendingNegation = false
                continue
            }
            for token in SearchText.tokens(SearchText.normalize(rawToken)) {
                if pendingNegation {
                    if SearchVocabulary.stopwords.contains(token) { continue }
                    if !query.negated.contains(token) { query.negated.append(token) }
                    pendingNegation = false
                } else if SearchVocabulary.negationWords.contains(token) {
                    pendingNegation = true
                } else if SearchVocabulary.stopwords.contains(token) {
                    if !query.ignoredStopwords.contains(token) { query.ignoredStopwords.append(token) }
                } else if !query.terms.contains(token) {
                    query.terms.append(token)
                }
            }
        }
        if query.terms.count > SearchVocabulary.maxTerms {
            query.terms = Array(query.terms.prefix(SearchVocabulary.maxTerms))
            query.wasTruncated = true
        }
        if query.negated.count > SearchVocabulary.maxNegations {
            query.negated = Array(query.negated.prefix(SearchVocabulary.maxNegations))
            query.wasTruncated = true
        }

        // The final word is a prefix while it's still being typed (no trailing space/quote).
        if let last = outside.last, !last.isWhitespace, let lastRaw = rawTokens.last, !lastRaw.hasPrefix("-"),
           let lastToken = SearchText.tokens(SearchText.normalize(lastRaw)).last,
           query.terms.contains(lastToken), !query.negated.contains(lastToken), lastToken.count >= 2 {
            query.prefixTerm = lastToken
        }
        return query
    }

    // MARK: Matching

    static func areSynonyms(_ a: String, _ b: String) -> Bool {
        guard let ga = SearchVocabulary.synonymIndex[a], let gb = SearchVocabulary.synonymIndex[b] else { return false }
        return ga == gb
    }

    /// Best way one query word matches one field, if at all.
    static func match(word: String, allowPrefix: Bool, in field: SearchField) -> (kind: SearchMatchKind, matched: String)? {
        let wordStem = SearchText.stem(word)
        var best: (kind: SearchMatchKind, matched: String)?
        for (i, token) in field.tokens.enumerated() {
            let tokenStem = field.stems[i]
            let kind: SearchMatchKind?
            if token == word {
                kind = .exact
            } else if tokenStem == wordStem {
                kind = .variant
            } else if areSynonyms(wordStem, tokenStem) || (SearchVocabulary.categoryIndex[wordStem]?.contains(tokenStem) ?? false) {
                kind = .synonym
            } else if allowPrefix, token.hasPrefix(word) {
                kind = .prefix
            } else {
                kind = nil
            }
            if let kind, best == nil || kind < best!.kind {
                best = (kind, token)
                if kind == .exact { break }
            }
        }
        if best == nil, let family = field.colorFamily, let searched = SearchVocabulary.colorFamilyIndex[wordStem],
           searched != family, searched.relatedFamilies.contains(family) {
            best = (.relatedShade, family.label)
        }
        return best
    }

    /// Preference order for choosing a word's best match, mirroring the ranking rules:
    /// direct colour before related shade, the record's own fields before linked pieces,
    /// exact before synonym/variant/prefix, then field weight.
    private static func preferenceKey(_ m: SearchTermMatch) -> (Int, Int, Int, Double, Int) {
        let kindClass: Int = switch m.kind {
        case .phrase, .exact: 0
        case .variant, .synonym, .prefix: 1
        case .relatedShade: 2
        }
        return (m.kind == .relatedShade ? 1 : 0, m.field.role.isLinked ? 1 : 0, kindClass, -m.score, m.kind.rawValue)
    }

    /// Strongest match of a word across a document's fields (first field wins exact ties).
    static func bestMatch(word: String, allowPrefix: Bool, in doc: SearchDocument) -> SearchTermMatch? {
        var best: SearchTermMatch?
        for field in doc.fields {
            guard let m = match(word: word, allowPrefix: allowPrefix, in: field) else { continue }
            let candidate = SearchTermMatch(term: word, kind: m.kind, field: field, matchedWord: m.matched)
            if let current = best {
                if preferenceKey(candidate) < preferenceKey(current) { best = candidate }
            } else {
                best = candidate
            }
        }
        return best
    }

    /// A quoted phrase must appear inside one indexed field. Fields are never concatenated.
    static func phraseMatch(_ phrase: SearchPhrase, in doc: SearchDocument) -> SearchTermMatch? {
        let ordered = doc.fields.sorted { $0.role < $1.role }
        for field in ordered where SearchText.contains(field.normalized, phrase: phrase.text, openEnded: phrase.isOpen) {
            return SearchTermMatch(term: "“\(phrase.text)”", kind: .phrase, field: field, matchedWord: phrase.text)
        }
        return nil
    }

    /// Negated words exclude a record when they match directly, as a variant or synonym.
    static func isExcluded(_ doc: SearchDocument, negated: [String]) -> Bool {
        guard !negated.isEmpty else { return false }
        for word in negated {
            for field in doc.fields {
                if let m = match(word: word, allowPrefix: false, in: field), m.kind <= .synonym { return true }
            }
        }
        return false
    }

    /// Facets that exclude this document. Facets are applied identically in every tier.
    static func facetFailures(_ doc: SearchDocument, filters: SearchFilters) -> [SearchFacetKind] {
        var failures: [SearchFacetKind] = []
        let f = doc.facets
        if !filters.types.isEmpty, !filters.types.contains(doc.type) { failures.append(.type) }
        if !filters.categories.isEmpty, f.categories.isDisjoint(with: filters.categories) { failures.append(.category) }
        if !filters.colors.isEmpty, f.colorFamilies.isDisjoint(with: filters.colors) { failures.append(.color) }
        if let ownership = f.ownership, !ownership.passes(filters.ownership) { failures.append(.ownership) }
        if filters.availableOnly, !f.isAvailableNow { failures.append(.availability) }
        if filters.favoritesOnly, !f.isFavorite { failures.append(.favorites) }
        if !filters.collectionIDs.isEmpty, f.collectionIDs.isDisjoint(with: filters.collectionIDs) { failures.append(.collection) }
        if !filters.imageSources.isEmpty, f.imageSources.isDisjoint(with: filters.imageSources) { failures.append(.imageSource) }
        return failures
    }

    // MARK: Ranking

    /// Deterministic order: rank, then score, then title, then type, then ID.
    static func ordered(_ a: SearchHit, _ b: SearchHit) -> Bool {
        if a.rank != b.rank { return a.rank < b.rank }
        if a.score != b.score { return a.score > b.score }
        let byTitle = a.document.title.localizedCaseInsensitiveCompare(b.document.title)
        if byTitle != .orderedSame { return byTitle == .orderedAscending }
        if a.document.type != b.document.type { return a.document.type.sortOrder < b.document.type.sortOrder }
        return a.document.sourceID < b.document.sourceID
    }

    private static func rank(for matches: [SearchTermMatch], query: SearchParsedQuery, doc: SearchDocument) -> Int {
        if matches.contains(where: { $0.kind == .relatedShade }) { return 4 }
        let exactName = !query.terms.isEmpty && query.phrases.isEmpty
            && doc.fields.contains { $0.role.isNameOrAlias && $0.contentKey == query.contentKey }
        let phraseInName = matches.contains { $0.kind == .phrase && $0.field.role.isNameOrAlias }
        if exactName || phraseInName { return 0 }
        if matches.contains(where: { $0.field.role.isLinked }) { return 3 }
        if matches.allSatisfy({ $0.kind <= .exact }) { return 1 }
        return 2
    }

    // MARK: Run

    /// Runs one query over prebuilt documents. Bounded and side-effect free.
    static func run(_ input: String, filters: SearchFilters, scope: SearchScopeHint, documents: [SearchDocument]) -> SearchOutput {
        let query = parse(input)
        var output = SearchOutput(query: query)
        let scopeTypes = Set(scope.searchResultTypes)
        let candidates = documents.filter { scopeTypes.contains($0.type) }

        // Filter-only browsing (no words, explicit filters or negations).
        guard query.hasContent else {
            guard !filters.isDefault || !query.negated.isEmpty else { return output }
            output.isBrowsing = true
            var hits: [SearchHit] = []
            for doc in candidates where doc.facets.inWorkingSource && !isExcluded(doc, negated: query.negated) {
                let failures = facetFailures(doc, filters: filters)
                if failures.filter({ $0 != .type }).isEmpty { output.typeCounts[doc.type, default: 0] += 1 }
                guard failures.isEmpty else { continue }
                hits.append(SearchHit(document: doc, tier: .browse, matches: [], unmatchedWords: [], rank: doc.type.sortOrder, score: 0))
            }
            output.primary = hits.sorted(by: ordered)
            return output
        }

        let words = query.allWords
        var possibleCandidates: [SearchHit] = []
        var hiddenReasons = Set<SearchFacetKind>()
        var phraseFoundAnywhere = Set<String>()

        for doc in candidates {
            if isExcluded(doc, negated: query.negated) { continue }

            var matches: [SearchTermMatch] = []
            for word in words {
                if let m = bestMatch(word: word, allowPrefix: word == query.prefixTerm, in: doc) {
                    matches.append(m)
                }
            }
            var phraseMatches: [SearchTermMatch] = []
            for phrase in query.phrases {
                if let m = phraseMatch(phrase, in: doc) {
                    phraseMatches.append(m)
                    phraseFoundAnywhere.insert(phrase.text)
                }
            }
            let termsAllMatched = query.terms.allSatisfy { term in matches.contains { $0.term == term } }
            let isFull = termsAllMatched && phraseMatches.count == query.phrases.count
            let failures = facetFailures(doc, filters: filters)
            let sourceOK = doc.facets.inWorkingSource

            if isFull {
                // Phrase matches replace the separately matched phrase words.
                let phraseWordSet = Set(query.phraseWords)
                let used = phraseMatches + matches.filter { !phraseWordSet.contains($0.term) }
                if failures.filter({ $0 != .type }).isEmpty, sourceOK { output.typeCounts[doc.type, default: 0] += 1 }
                if !failures.isEmpty {
                    if sourceOK {
                        output.hiddenByFilters += 1
                        hiddenReasons.formUnion(failures)
                    }
                    continue
                }
                guard sourceOK else {
                    output.hiddenBySource += 1
                    continue
                }
                let r = rank(for: used, query: query, doc: doc)
                let hit = SearchHit(document: doc, tier: r == 4 ? .relatedShade : .primary, matches: used, unmatchedWords: [],
                                    rank: r, score: used.reduce(0) { $0 + $1.score })
                if r == 4 { output.relatedShade.append(hit) } else { output.primary.append(hit) }
            } else if failures.isEmpty, sourceOK {
                // Related shades stay a separately labelled expansion: in this tier a word
                // reached only through a related colour family counts as not recorded, so a
                // Burgundy bag is never described as having "matched: pink".
                let direct = matches.filter { $0.kind != .relatedShade }
                guard !direct.isEmpty, direct.count * 2 >= words.count else { continue }
                let directTerms = Set(direct.map(\.term))
                let notRecorded = words.filter { !directTerms.contains($0) }
                possibleCandidates.append(SearchHit(document: doc, tier: .possible, matches: direct, unmatchedWords: notRecorded,
                                                    rank: words.count - direct.count, score: direct.reduce(0) { $0 + $1.score }))
            }
        }

        output.primary.sort(by: ordered)
        output.relatedShade.sort(by: ordered)
        output.hiddenReasons = SearchFacetKind.allCases.filter { hiddenReasons.contains($0) }
        output.phrasesNotFound = query.phrases.map(\.text).filter { !phraseFoundAnywhere.contains($0) }
        if !output.hasDirectResults {
            output.possible = Array(possibleCandidates.sorted(by: ordered).prefix(SearchVocabulary.maxPossibleMatches))
        }
        return output
    }

    // MARK: Remember this name

    /// Suggested phrase from the typed query: quotes and negated words removed, spacing tidied.
    static func rememberSuggestion(from raw: String) -> String {
        var words: [String] = []
        var skipNext = false
        let cleaned = raw.replacingOccurrences(of: "\"", with: " ")
            .replacingOccurrences(of: "\u{201C}", with: " ")
            .replacingOccurrences(of: "\u{201D}", with: " ")
        for word in cleaned.split(whereSeparator: \.isWhitespace).map(String.init) {
            let lower = word.lowercased()
            if skipNext {
                if SearchVocabulary.stopwords.contains(lower) { continue }
                skipNext = false
                continue
            }
            if word.hasPrefix("-") { continue }
            if SearchVocabulary.negationWords.contains(lower) { skipNext = true; continue }
            words.append(word)
        }
        return String(words.joined(separator: " ").prefix(60))
    }

    /// The same phrase without filler words.
    static func withoutStopwords(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace)
            .filter { !SearchVocabulary.stopwords.contains(SearchText.normalize(String($0))) }
            .joined(separator: " ")
    }

    /// True when the phrase is already the item's name or one of its other names.
    static func isExistingName(_ phrase: String, of garment: Garment) -> Bool {
        let key = SearchText.normalize(phrase)
        guard !key.isEmpty else { return true }
        if SearchText.normalize(garment.displayName) == key { return true }
        return garment.aliases.contains { SearchText.normalize($0.text) == key }
    }

    /// Offer Remember this name only for a multi-word query that the item's own
    /// name or a single other name doesn't already cover word-for-word.
    static func shouldOfferRemember(query: SearchParsedQuery, hit: SearchHit, garment: Garment) -> Bool {
        guard query.isMultiWord, hit.document.type == .garment, hit.document.sourceID == garment.id else { return false }
        if isExistingName(rememberSuggestion(from: query.raw), of: garment) { return false }
        if hit.tier == .possible { return true }
        let coveredByOneName = hit.matches.allSatisfy { $0.kind <= .exact && $0.field.role.isNameOrAlias }
            && Set(hit.matches.map(\.field)).count == 1
        return !coveredByOneName
    }
}
