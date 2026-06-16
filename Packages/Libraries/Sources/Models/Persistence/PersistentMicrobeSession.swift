import Foundation
import SwiftData

/// SwiftData model: snapshot of a microbiome simulator session.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § SwiftData @Model classes the storage strategy
/// is snapshot-per-session (JSON-encoded `MicrobiomeState` blob) — cheap to roll
/// back, no relationship traversal cost in views.
///
/// `@Model` types stay MainActor-isolated; nonisolated decode/encode helpers
/// live on `MicrobiomeState` itself (the value type).
@Model
public final class PersistentMicrobeSession {
    public var id: UUID = UUID()
    /// JSON-encoded `MicrobiomeState` snapshot at session end.
    /// Read via `decodedState()`; write via `encodeState(_:)`.
    public var encodedStateData: Data = Data()
    public var startedAt: Date = Date()
    public var endedAt: Date?
    /// Highest zoom tier reached during the session. Drives codex-discovery XP.
    public var highestZoomTierRaw: Int = ZoomTier.unaided.rawValue

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        encodedStateData: Data = Data(),
        highestZoomTierRaw: Int = ZoomTier.unaided.rawValue
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.encodedStateData = encodedStateData
        self.highestZoomTierRaw = highestZoomTierRaw
    }

    public var highestZoomTier: ZoomTier {
        ZoomTier(rawValue: highestZoomTierRaw) ?? .unaided
    }

    /// Decode the stored snapshot. Per `.claude/rules/warnings.md` § `@Model` +
    /// Codable isolation, decode lives on the value type; this helper is a thin
    /// pass-through.
    public func decodedState() -> MicrobiomeState? {
        guard !encodedStateData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MicrobiomeState.self, from: encodedStateData)
    }

    public func encodeState(_ state: MicrobiomeState) {
        if let data = try? JSONEncoder().encode(state) {
            encodedStateData = data
        }
    }
}
