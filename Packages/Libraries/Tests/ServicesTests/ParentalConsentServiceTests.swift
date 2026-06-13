import Foundation
import Testing
@testable import Services

@Suite("ParentalConsentService")
@MainActor
struct ParentalConsentServiceTests {
    /// Per `.claude/rules/testing.md` § Crash-Resilience Defaults — every
    /// UserDefaults-using test isolates to a per-suite name + wipes it on
    /// init so cross-test pollution can't leak.
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let name = "ParentalConsentServiceTests-\(suite)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func freshServiceHasNoRecords() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        #expect(service.records.isEmpty)
        for kind in ParentalConsentKind.allCases {
            #expect(!service.hasValidConsent(for: kind))
        }
    }

    @Test func recordGrantPersistsAndAnswersValid() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        service.recordGrant(for: .diseaseStoryArcs)
        #expect(service.hasValidConsent(for: .diseaseStoryArcs))
        #expect(service.records.count == 1)
        #expect(service.records.first?.kind == .diseaseStoryArcs)
    }

    @Test func recordGrantReplacesPriorRecord() {
        let defaults = Self.makeIsolatedDefaults()
        let service = ParentalConsentService(defaults: defaults)
        let earlier = Date(timeIntervalSinceReferenceDate: 0)
        service.recordGrant(for: .weeklySummaryNotifications, now: earlier)
        let later = earlier.addingTimeInterval(60 * 60 * 24 * 30)
        service.recordGrant(for: .weeklySummaryNotifications, now: later)
        #expect(service.records.count == 1)
        let onlyRecord = try? #require(service.records.first)
        #expect(onlyRecord?.grantedAt == later)
    }

    @Test func revokeDropsRecord() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        service.recordGrant(for: .externalLinks)
        #expect(service.hasValidConsent(for: .externalLinks))
        service.revoke(.externalLinks)
        #expect(!service.hasValidConsent(for: .externalLinks))
        #expect(service.records.isEmpty)
    }

    @Test func revokeUnknownKindIsNoOp() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        service.revoke(.classroomMode)
        #expect(service.records.isEmpty)
    }

    @Test func expiredRecordIsNotValid() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        let grantTime = Date(timeIntervalSinceReferenceDate: 0)
        service.recordGrant(for: .classroomMode, now: grantTime)
        // 366 days later — past the 365-day re-consent window.
        let future = grantTime.addingTimeInterval(TimeInterval(366) * 86_400)
        #expect(!service.hasValidConsent(for: .classroomMode, at: future))
        #expect(service.expiredRecords(at: future).count == 1)
        #expect(service.activeRecords(at: future).isEmpty)
    }

    @Test func withinWindowIsActive() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        let grantTime = Date(timeIntervalSinceReferenceDate: 0)
        service.recordGrant(for: .diseaseStoryArcs, now: grantTime)
        let within = grantTime.addingTimeInterval(TimeInterval(180) * 86_400)
        #expect(service.hasValidConsent(for: .diseaseStoryArcs, at: within))
        #expect(service.activeRecords(at: within).count == 1)
        #expect(service.expiredRecords(at: within).isEmpty)
    }

    @Test func recordsPersistAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        let first = ParentalConsentService(defaults: defaults)
        first.recordGrant(for: .diseaseStoryArcs)
        first.recordGrant(for: .externalLinks)
        let second = ParentalConsentService(defaults: defaults)
        #expect(second.records.count == 2)
        #expect(second.hasValidConsent(for: .diseaseStoryArcs))
        #expect(second.hasValidConsent(for: .externalLinks))
    }

    @Test func clearForTestingWipesAll() {
        let service = ParentalConsentService(defaults: Self.makeIsolatedDefaults())
        for kind in ParentalConsentKind.allCases {
            service.recordGrant(for: kind)
        }
        #expect(service.records.count == ParentalConsentKind.allCases.count)
        service.clearForTesting()
        #expect(service.records.isEmpty)
    }

    @Test func consentKindRawValueStabilityForPersistence() {
        // The persistence schema depends on stable raw values across
        // releases. If a value changes here without a migration, every
        // already-granted consent on a device gets silently dropped on
        // next launch. Lock the canonical strings.
        #expect(ParentalConsentKind.diseaseStoryArcs.rawValue == "disease_story_arcs")
        #expect(ParentalConsentKind.weeklySummaryNotifications.rawValue == "weekly_summary_notifications")
        #expect(ParentalConsentKind.externalLinks.rawValue == "external_links")
        #expect(ParentalConsentKind.classroomMode.rawValue == "classroom_mode")
    }

    @Test func consentKindDescriptionIsTraumaSafe() {
        // The description copy is rendered to the parent in the consent
        // manager view. Stoplist mirrors the portfolio trauma-informed
        // posture — no shame / punitive / loss-aversion language even
        // though this is parent-facing copy (the surface is reached
        // through profile → settings, so the kid can stumble in too).
        let stopWords = ["failed", "wrong", "denied", "must", "should"]
        for kind in ParentalConsentKind.allCases {
            let copy = kind.description.lowercased()
            for stop in stopWords {
                #expect(!copy.contains(stop), "ParentalConsentKind.\(kind.rawValue) description contains stop-word \"\(stop)\": \(copy)")
            }
        }
    }
}
