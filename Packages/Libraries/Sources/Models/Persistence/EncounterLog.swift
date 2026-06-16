import Foundation
import SwiftData

/// SwiftData model: one record per microbe-meet event in the codex.
///
/// Encounters drive: (a) the codex "discovered" set, (b) XP awards for
/// first-meet, (c) `Cilia` mentor first-meet catchphrase trigger.
@Model
public final class EncounterLog {
    public var id: UUID = UUID()
    /// The `MicrobeCharacter.id` the player met.
    public var microbeID: UUID = UUID()
    public var slug: String = ""
    public var encounteredAt: Date = Date()
    public var atZoomTierRaw: Int = ZoomTier.unaided.rawValue
    public var inSlot: String = GutSlot.colon.rawValue
    public var sessionID: UUID?

    public init(
        id: UUID = UUID(),
        microbeID: UUID,
        slug: String,
        encounteredAt: Date = Date(),
        atZoomTierRaw: Int = ZoomTier.unaided.rawValue,
        inSlot: String = GutSlot.colon.rawValue,
        sessionID: UUID? = nil
    ) {
        self.id = id
        self.microbeID = microbeID
        self.slug = slug
        self.encounteredAt = encounteredAt
        self.atZoomTierRaw = atZoomTierRaw
        self.inSlot = inSlot
        self.sessionID = sessionID
    }

    public var atZoomTier: ZoomTier {
        ZoomTier(rawValue: atZoomTierRaw) ?? .unaided
    }
}
