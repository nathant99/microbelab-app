import Foundation
import Observation

/// Distinct features that require verifiable parental consent under the
/// 2026 FTC COPPA Rule Amendments (effective April 22 2026). Per
/// `.claude/rules/age-assurance.md` § 2026 FTC COPPA Rule Amendments:
/// **separate consent flows are required per data-sharing class**;
/// rolling everything into a single binary toggle no longer satisfies
/// the rule. Each case below maps to one consent flow surfaced through
/// `ParentalConsentManagerView`.
///
/// New cases get appended at the end so the `String` raw value stays
/// stable for any consent record already persisted to disk.
public nonisolated enum ParentalConsentKind: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Disease-story narrative arcs (Phase 3). Trauma-aware framing per
    /// SAMHSA TIP 57; disabled by default; opt-in. Mirrors the existing
    /// `AppSettings.diseaseStoryGateEnabled` toggle but adds a documented
    /// consent record per the FTC rule.
    case diseaseStoryArcs = "disease_story_arcs"
    /// Opt-in weekly local notification summarizing the kid's engagement.
    /// Local-only (`UNUserNotificationCenter`) — no cloud, no PII.
    case weeklySummaryNotifications = "weekly_summary_notifications"
    /// Parental gate before opening any external URL (e.g. crisis-resource
    /// `tel:` / `sms:` deep links surfaced from Settings).
    case externalLinks = "external_links"
    /// Future opt-in: classroom-mode integration (ForgeKit 0.94 `ForgeClassroom`
    /// LiveKit microphone surface). The consent is captured here even before
    /// the integration ships so the audit trail predates first use.
    case classroomMode = "classroom_mode"

    public var id: String { rawValue }

    /// Kid-and-parent-readable headline for the consent row.
    public var displayName: String {
        switch self {
        case .diseaseStoryArcs:
            return "Disease story arcs"
        case .weeklySummaryNotifications:
            return "Weekly summary notification"
        case .externalLinks:
            return "External links"
        case .classroomMode:
            return "Classroom mode"
        }
    }

    /// Trauma-informed plain-language explanation of what the consent
    /// covers. Surfaced under the consent toggle in
    /// `ParentalConsentManagerView`.
    public var description: String {
        switch self {
        case .diseaseStoryArcs:
            return "Phase 3 narrative arcs about diseases the body fights off. Trauma-aware framing; off-ramps every page."
        case .weeklySummaryNotifications:
            return "An on-device reminder once a week with what the kid explored. No cloud, no PII."
        case .externalLinks:
            return "Phone + text links to crisis hotlines (988, Childhelp, Crisis Text Line). The link still opens the system phone or messages app — never inside MicrobeLab."
        case .classroomMode:
            return "Future opt-in for teachers running MicrobeLab in a classroom. Off until the surface ships."
        }
    }
}

/// One persisted record that an adult granted consent for a specific
/// feature kind. PII-safe: stores the kind slug + the grant timestamp +
/// the expiry. Never stores the adult's name, email, or any account
/// identifier — the parental gate already established the adult is
/// present at grant time.
///
/// Annual re-consent per FTC 2026: the expiry is set at grant + 365
/// calendar days; `isValid(at:)` returns false past the expiry so the
/// manager view surfaces a re-confirm prompt automatically.
public nonisolated struct ParentalConsentRecord: Codable, Sendable, Equatable, Identifiable {
    public let kind: ParentalConsentKind
    public let grantedAt: Date
    public let expiresAt: Date

    public var id: String { kind.rawValue }

    public init(kind: ParentalConsentKind, grantedAt: Date, expiresAt: Date) {
        self.kind = kind
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
    }

    /// True when `now` is between the grant date and the annual-re-consent
    /// expiry. Per FTC 2026 the rolling window is 365 calendar days.
    public func isValid(at now: Date = .now) -> Bool {
        now >= grantedAt && now < expiresAt
    }
}

/// MainActor `@Observable` UserDefaults-backed store for per-feature
/// parental consent records. Closes two FEATURE_PLAN items at once:
/// "Parental consent service" (the COPPA-compliant grant + revoke + annual
/// re-consent mechanism) and "Parental gates" (the consumer-side check
/// that any data-sharing / external-link path calls
/// `hasValidConsent(for:)` before proceeding).
///
/// Storage: a JSON-encoded array of `ParentalConsentRecord` under one
/// UserDefaults key. Bounded by `ParentalConsentKind.allCases.count` so
/// the store never grows beyond a few dozen bytes regardless of how many
/// times the adult grants + revokes.
///
/// Trauma-informed posture: there is no "consent denied" record — only
/// "consent granted with expiry". A revoke deletes the record. This
/// keeps the surface kid-readable in `ParentalConsentManagerView`
/// (revoking simply hides the feature; the kid never sees a "DENIED"
/// status line). The annual re-consent surfaces as a calm reconfirm
/// prompt, never as a "your consent expired" punitive frame.
///
/// Privacy: per `.claude/rules/age-assurance.md` § Portfolio Status —
/// counts + slugs + timestamps only; never PII. The grant flow assumes
/// the adult has already passed `ParentalGateView`'s math gate; this
/// store does not re-prompt.
@MainActor
@Observable
public final class ParentalConsentService {
    public static let userDefaultsKey = "com.microbelab.parental.consents"

    /// Annual re-consent window per 2026 FTC COPPA Rule Amendments.
    /// Defaults to 365 calendar days from the grant timestamp.
    public static let reconsentWindowDays: Int = 365

    public private(set) var records: [ParentalConsentRecord]

    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.calendar = calendar
        if let data = defaults.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ParentalConsentRecord].self, from: data) {
            self.records = decoded
        } else {
            self.records = []
        }
    }

    /// True when a valid (non-expired) record exists for `kind`. The
    /// parental-gate consumer call site (e.g. crisis-resource external
    /// link tap, weekly-summary scheduler, disease-story arc unlock)
    /// guards on this; a false return surfaces the re-consent flow.
    public func hasValidConsent(for kind: ParentalConsentKind, at now: Date = .now) -> Bool {
        guard let record = records.first(where: { $0.kind == kind }) else { return false }
        return record.isValid(at: now)
    }

    /// Record an adult-confirmed grant. Replaces any prior record for
    /// the same kind so the re-consent clock resets. `expiresAt` derives
    /// from `grantedAt + reconsentWindowDays`; pass an explicit `now`
    /// for test reproducibility.
    public func recordGrant(for kind: ParentalConsentKind, now: Date = .now) {
        let expiresAt: Date
        if let derived = calendar.date(byAdding: .day, value: Self.reconsentWindowDays, to: now) {
            expiresAt = derived
        } else {
            // Calendar-arithmetic failure is vanishingly rare but we
            // fall back to a 365-day delta computed via TimeInterval so
            // the record always has a defensible expiry.
            expiresAt = now.addingTimeInterval(TimeInterval(Self.reconsentWindowDays) * 86_400)
        }
        let record = ParentalConsentRecord(kind: kind, grantedAt: now, expiresAt: expiresAt)
        records.removeAll { $0.kind == kind }
        records.append(record)
        persist()
        DebugLog.permission("ParentalConsentService granted \(kind.rawValue); expiresAt=\(expiresAt)")
    }

    /// Drop the record for `kind`. Calling revoke for a kind that has no
    /// record is a no-op. Surfaces as "Revoke" in the manager view; the
    /// kid never sees a status change beyond the feature disappearing.
    public func revoke(_ kind: ParentalConsentKind) {
        let priorCount = records.count
        records.removeAll { $0.kind == kind }
        if records.count != priorCount {
            persist()
            DebugLog.permission("ParentalConsentService revoked \(kind.rawValue)")
        }
    }

    /// Records that have crossed their re-consent expiry. Useful for the
    /// manager view's "Needs reconfirm" section so an adult can refresh
    /// a still-desired consent in one tap.
    public func expiredRecords(at now: Date = .now) -> [ParentalConsentRecord] {
        records.filter { !$0.isValid(at: now) }
    }

    /// Records currently within the annual re-consent window. Powers the
    /// manager view's "Active" section.
    public func activeRecords(at now: Date = .now) -> [ParentalConsentRecord] {
        records.filter { $0.isValid(at: now) }
    }

    /// Wipe persisted state. Test-only — the production surface never
    /// silently clears consent. Adult revoke goes through `revoke(_:)`.
    public func clearForTesting() {
        records.removeAll()
        defaults.removeObject(forKey: Self.userDefaultsKey)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: Self.userDefaultsKey)
        } catch {
            DebugLog.error("ParentalConsentService.persist failed", error: error)
        }
    }
}
