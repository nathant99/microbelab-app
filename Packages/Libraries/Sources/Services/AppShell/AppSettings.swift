import Foundation

/// Daily session-time cap surfaced in parental controls.
/// Defaults to 30 minutes per `.claude/rules/age-assurance.md` § Portfolio Status.
public nonisolated enum DailySessionCap: String, Codable, Sendable, CaseIterable, Identifiable {
    case fifteen = "15"
    case thirty = "30"
    case fortyFive = "45"
    case sixty = "60"
    case unlimited = "unlimited"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fifteen: return "15 minutes"
        case .thirty: return "30 minutes"
        case .fortyFive: return "45 minutes"
        case .sixty: return "60 minutes"
        case .unlimited: return "No limit"
        }
    }

    public var minutes: Int? {
        switch self {
        case .fifteen: return 15
        case .thirty: return 30
        case .fortyFive: return 45
        case .sixty: return 60
        case .unlimited: return nil
        }
    }
}

/// Persistable app-wide settings. All defaults are trauma-safe: difficult
/// content gated ON, daily cap 30 min, sound + haptics on, motion overrides
/// inherit system preferences.
public nonisolated struct AppSettings: Codable, Sendable, Equatable {
    public var soundEffectsEnabled: Bool
    public var hapticsEnabled: Bool
    /// When true, force-reduce motion regardless of system preference.
    public var forceReduceMotion: Bool
    /// When true, force-reduce transparency (Liquid Glass falls back to solid).
    public var forceReduceTransparency: Bool
    /// Disease-narrative content gate. Phase 3 surfaces only opt-in. Defaults ON.
    public var diseaseStoryGateEnabled: Bool
    public var dailySessionCap: DailySessionCap
    /// Parent-gated accessibility toggle that pins `DifficultyAdjuster` to
    /// `.introductory` regardless of session count. Defaults OFF; the curve
    /// already starts gentle in sessions 1-2 — this is the long-term
    /// override for kids who want the chill version permanently.
    public var simplifyChallenge: Bool
    /// Opt-in toggle for the local weekly summary notification per
    /// FEATURE_PLAN.md § Parent Integration → "Weekly summary". Defaults
    /// OFF per 2026 FTC COPPA Rule § Opt-in consent. Toggling on requires
    /// (a) parental-gate adult confirm + (b) granted
    /// `ParentalConsentService.weeklySummaryNotifications` consent + (c)
    /// `UNUserNotificationCenter` authorization. The SettingsView toggle
    /// orchestrates all three gates.
    public var weeklySummaryNotificationEnabled: Bool

    public init(
        soundEffectsEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        forceReduceMotion: Bool = false,
        forceReduceTransparency: Bool = false,
        diseaseStoryGateEnabled: Bool = true,
        dailySessionCap: DailySessionCap = .thirty,
        simplifyChallenge: Bool = false,
        weeklySummaryNotificationEnabled: Bool = false
    ) {
        self.soundEffectsEnabled = soundEffectsEnabled
        self.hapticsEnabled = hapticsEnabled
        self.forceReduceMotion = forceReduceMotion
        self.forceReduceTransparency = forceReduceTransparency
        self.diseaseStoryGateEnabled = diseaseStoryGateEnabled
        self.dailySessionCap = dailySessionCap
        self.simplifyChallenge = simplifyChallenge
        self.weeklySummaryNotificationEnabled = weeklySummaryNotificationEnabled
    }

    public static let `default` = AppSettings()

    // Custom decoder so adding fields over time doesn't invalidate the
    // entire persisted struct. `try?` in `AppSettingsStore.init` would
    // otherwise discard every preference the kid + parent already saved
    // the moment a new field lands.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        self.soundEffectsEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEffectsEnabled) ?? defaults.soundEffectsEnabled
        self.hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? defaults.hapticsEnabled
        self.forceReduceMotion = try container.decodeIfPresent(Bool.self, forKey: .forceReduceMotion) ?? defaults.forceReduceMotion
        self.forceReduceTransparency = try container.decodeIfPresent(Bool.self, forKey: .forceReduceTransparency) ?? defaults.forceReduceTransparency
        self.diseaseStoryGateEnabled = try container.decodeIfPresent(Bool.self, forKey: .diseaseStoryGateEnabled) ?? defaults.diseaseStoryGateEnabled
        self.dailySessionCap = try container.decodeIfPresent(DailySessionCap.self, forKey: .dailySessionCap) ?? defaults.dailySessionCap
        self.simplifyChallenge = try container.decodeIfPresent(Bool.self, forKey: .simplifyChallenge) ?? defaults.simplifyChallenge
        self.weeklySummaryNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .weeklySummaryNotificationEnabled) ?? defaults.weeklySummaryNotificationEnabled
    }
}

/// On-device persistent store for `AppSettings`. UserDefaults-backed per
/// portfolio convention; the constructor accepts an injected `UserDefaults`
/// for test isolation per `.claude/rules/testing.md` § Crash-Resilience.
@MainActor
public final class AppSettingsStore {
    private let defaults: UserDefaults
    private let key: String
    public private(set) var settings: AppSettings

    public init(defaults: UserDefaults = .standard, key: String = "MicrobeLab.AppSettings") {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    /// Persist `settings` to the injected UserDefaults. Errors are logged
    /// via `DebugLog.data` per `.claude/rules/debug-logging.md`.
    public func save(_ next: AppSettings) {
        settings = next
        do {
            let data = try JSONEncoder().encode(next)
            defaults.set(data, forKey: key)
        } catch {
            DebugLog.data("AppSettingsStore.save — encode failed", error: error)
        }
    }
}
