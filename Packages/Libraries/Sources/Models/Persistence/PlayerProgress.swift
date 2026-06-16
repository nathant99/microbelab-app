import Foundation
import SwiftData

/// SwiftData model: per-player progress envelope. One record per profile.
@Model
public final class PlayerProgress {
    public var id: UUID = UUID()
    public var displayName: String = ""
    public var totalXP: Int = 0
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var lastActiveDate: Date?
    /// `MicrobeCharacter.id` UUIDs the player has met in the codex.
    public var discoveredMicrobeIDsData: Data = Data()
    /// Earned achievement slugs (FK to ForgeKit achievement definitions).
    public var earnedAchievementSlugsData: Data = Data()

    public init(
        id: UUID = UUID(),
        displayName: String = "",
        totalXP: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        discoveredMicrobeIDsData: Data = Data(),
        earnedAchievementSlugsData: Data = Data()
    ) {
        self.id = id
        self.displayName = displayName
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.discoveredMicrobeIDsData = discoveredMicrobeIDsData
        self.earnedAchievementSlugsData = earnedAchievementSlugsData
    }

    public var discoveredMicrobeIDs: Set<UUID> {
        get { (try? JSONDecoder().decode(Set<UUID>.self, from: discoveredMicrobeIDsData)) ?? [] }
        set { discoveredMicrobeIDsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    public var earnedAchievementSlugs: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: earnedAchievementSlugsData)) ?? [] }
        set { earnedAchievementSlugsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
