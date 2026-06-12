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

    public init(
        soundEffectsEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        forceReduceMotion: Bool = false,
        forceReduceTransparency: Bool = false,
        diseaseStoryGateEnabled: Bool = true,
        dailySessionCap: DailySessionCap = .thirty
    ) {
        self.soundEffectsEnabled = soundEffectsEnabled
        self.hapticsEnabled = hapticsEnabled
        self.forceReduceMotion = forceReduceMotion
        self.forceReduceTransparency = forceReduceTransparency
        self.diseaseStoryGateEnabled = diseaseStoryGateEnabled
        self.dailySessionCap = dailySessionCap
    }

    public static let `default` = AppSettings()
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
