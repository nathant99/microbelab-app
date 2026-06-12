import Foundation
import SwiftData

/// SwiftData model: kid-authored journal note. Surfaces "what did you notice
/// today?" prompts in line with reflective-pillar pattern.
@Model
public final class JournalEntry {
    public var id: UUID = UUID()
    public var createdAt: Date = Date()
    /// Per `.claude/rules/age-assurance.md` + portfolio COPPA posture, journal
    /// text stays on-device only — never network-synced.
    public var body: String = ""
    /// Optional pointer to a microbe the kid was observing when they journaled.
    public var relatedMicrobeID: UUID?
    /// Optional ForgeKit `ReflectionPromptStorage` prompt slug that triggered this entry.
    public var promptSlug: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        body: String = "",
        relatedMicrobeID: UUID? = nil,
        promptSlug: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.body = body
        self.relatedMicrobeID = relatedMicrobeID
        self.promptSlug = promptSlug
    }
}
