import Testing
import Foundation
import Models
@testable import Services

@Suite("GlobalMicrobiomeTourService (Phase 4 scaffold)")
@MainActor
struct GlobalMicrobiomeTourServiceTests {

    @Test("canonical catalog ships all four stops in wonder-forward → familiar → expansion order")
    func canonicalCatalogOrder() {
        let service = GlobalMicrobiomeTourService()
        let stops = service.catalog.map(\.stop)
        #expect(stops == [
            .yellowstoneHotSpring,
            .deepSeaVent,
            .humanGut,
            .soilUnderground
        ])
    }

    @Test("canonical catalog ships every stop as `.placeholder` (reviewer-blocked)")
    func canonicalCatalogAuthoringDefaultsToPlaceholder() {
        let service = GlobalMicrobiomeTourService()
        for record in service.catalog {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test("every stop in the catalog is unique by case")
    func catalogUniqueStops() {
        let service = GlobalMicrobiomeTourService()
        let uniqueStops = Set(service.catalog.map(\.stop))
        #expect(uniqueStops.count == service.catalog.count)
    }

    @Test("every stop rides the global-microbiome-tour gate (single gate per Phase 4 design)")
    func allStopsRideTheSingleGate() {
        for stop in GlobalMicrobiomeTourStop.allCases {
            #expect(stop.gateID == "global-microbiome-tour")
        }
    }

    @Test("presentation: gate locked — surfaces gatedBehindProgression regardless of authoring")
    func presentationGateLocked() {
        let service = GlobalMicrobiomeTourService()
        let record = GlobalMicrobiomeTourStopRecord(
            stop: .yellowstoneHotSpring,
            authoring: .reviewerSignedOff
        )
        let p = service.presentation(for: record, gateOpen: false)
        guard case .gatedBehindProgression = p else {
            Issue.record("expected gatedBehindProgression, got \(p)")
            return
        }
    }

    @Test("presentation: gate open + authoring placeholder — surfaces authoringPending")
    func presentationAuthoringPending() {
        let service = GlobalMicrobiomeTourService()
        let record = GlobalMicrobiomeTourStopRecord(
            stop: .humanGut,
            authoring: .placeholder
        )
        let p = service.presentation(for: record, gateOpen: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .placeholder authoring, got \(p)")
            return
        }
    }

    @Test("presentation: draftAwaitingReview is treated the same as placeholder — kids never see un-signed-off prose")
    func draftAwaitingReviewBehavesAsPlaceholder() {
        let service = GlobalMicrobiomeTourService()
        let record = GlobalMicrobiomeTourStopRecord(
            stop: .deepSeaVent,
            authoring: .draftAwaitingReview
        )
        let p = service.presentation(for: record, gateOpen: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .draftAwaitingReview authoring, got \(p)")
            return
        }
    }

    @Test("presentation: reviewerSignedOff + gate open — surfaces ready")
    func presentationReady() {
        let service = GlobalMicrobiomeTourService()
        let record = GlobalMicrobiomeTourStopRecord(
            stop: .humanGut,
            authoring: .reviewerSignedOff
        )
        let p = service.presentation(for: record, gateOpen: true)
        guard case .ready(let r) = p else {
            Issue.record("expected ready, got \(p)")
            return
        }
        #expect(r.stop == .humanGut)
    }

    @Test("record(for:) returns the catalog entry for a known stop")
    func recordForKnownStop() {
        let service = GlobalMicrobiomeTourService()
        let record = service.record(for: .yellowstoneHotSpring)
        #expect(record?.stop == .yellowstoneHotSpring)
    }

    @Test("trauma-informed register: display titles avoid warfare / fear / appropriative vocabulary")
    func displayTitlesTraumaSafeRegister() {
        let stoplist = [
            // Warfare
            "fight", "attack", "war", "battle", "weapon", "kill", "destroy", "enemy",
            // Threat
            "scary", "deadly", "danger", "horror", "doom",
            // Appropriative dirt / animality framing
            "filthy", "gross", "primitive"
        ]
        for stop in GlobalMicrobiomeTourStop.allCases {
            let title = stop.displayTitle.lowercased()
            for token in stoplist {
                #expect(!title.contains(token),
                        "Display title for \(stop) contains stoplist token \(token): \"\(title)\"")
            }
        }
    }

    @Test("featured cast cohorts reference the canonical microbe catalog slug shape")
    func featuredCastCohortsHaveReasonableSize() {
        // Each stop ships 2-3 cast slugs (chips render comfortably in the
        // view). Catalog is the 24-microbe set across Phases 1-4 (PR #119 +
        // PR #151) — slugs are short kebab-case identifiers.
        for stop in GlobalMicrobiomeTourStop.allCases {
            let slugs = stop.featuredMicrobeSlugs
            #expect(slugs.count >= 2,
                    "Stop \(stop) ships at least 2 featured microbes for cohort framing")
            #expect(slugs.count <= 4,
                    "Stop \(stop) ships at most 4 featured microbes so the chip strip stays compact")
            for slug in slugs {
                #expect(!slug.isEmpty,
                        "Empty featured slug on stop \(stop)")
                #expect(slug.lowercased() == slug,
                        "Featured slug '\(slug)' on \(stop) must be lowercase to match catalog convention")
            }
        }
    }

    @Test("yellowstoneHotSpring primitive surfaces Indigenous TEK credit")
    func yellowstonePrimitiveSurfacesTECCredit() {
        // Load-bearing per .claude/rules/distributed-narrative.md
        // § cultural-sensitivity gates. The primitive descriptor is the
        // structural hint to view consumers + reviewer that TEK credit is
        // required when authoring prose for this stop.
        let primitive = GlobalMicrobiomeTourStop.yellowstoneHotSpring.primitive.lowercased()
        #expect(primitive.contains("tek") || primitive.contains("indigenous"),
                "Yellowstone primitive must surface Indigenous TEK credit for the cultural-respect register: '\(primitive)'")
    }

    @Test("codable roundtrip preserves stop + authoring on the record")
    func codableRoundtripPreservesRecord() throws {
        let original = GlobalMicrobiomeTourStopRecord(
            stop: .soilUnderground,
            authoring: .draftAwaitingReview
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            GlobalMicrobiomeTourStopRecord.self,
            from: data
        )
        #expect(decoded == original)
    }
}
