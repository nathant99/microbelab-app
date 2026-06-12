import Foundation
import Models

/// Loads + queries the bundled 12-microbe Phase 1 catalog.
///
/// The catalog JSON lives at `Services/Resources/microbes.json` and is loaded
/// via `Bundle.module` per `.claude/rules/spm-architecture.md` § Key Rules.
///
/// Service is a value type — load once during app boot and pass the populated
/// instance to ViewModels. Avoid global singletons per
/// `.claude/rules/workflow.md` § Service Architecture.
public nonisolated struct MicrobeCatalogService: Sendable {
    public let microbes: [MicrobeCharacter]

    /// JSON envelope shape that mirrors the on-disk catalog.
    private nonisolated struct Envelope: Codable, Sendable {
        let version: Int
        let microbes: [MicrobeCharacter]
    }

    public enum CatalogError: Error, Sendable {
        case resourceMissing
        case decodingFailed(message: String)
    }

    public init(microbes: [MicrobeCharacter]) {
        self.microbes = microbes
    }

    /// Load from the bundled JSON. Returns `.failure` if the resource is
    /// missing or malformed; callers should treat catalog absence as a build
    /// configuration bug (not a runtime fallback path).
    public static func loadBundled() -> Result<MicrobeCatalogService, CatalogError> {
        guard let url = Bundle.module.url(forResource: "microbes", withExtension: "json") else {
            return .failure(.resourceMissing)
        }
        do {
            let data = try Data(contentsOf: url)
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            return .success(MicrobeCatalogService(microbes: envelope.microbes))
        } catch {
            return .failure(.decodingFailed(message: String(describing: error)))
        }
    }

    public func microbe(forSlug slug: String) -> MicrobeCharacter? {
        microbes.first { $0.slug == slug }
    }

    public func microbes(in slot: GutSlot) -> [MicrobeCharacter] {
        microbes.filter { $0.preferredEnvironment == slot }
    }

    public func microbes(role: MicrobeRole) -> [MicrobeCharacter] {
        microbes.filter { $0.role == role }
    }

    public func microbes(introducedByKit kit: Int) -> [MicrobeCharacter] {
        microbes.filter { $0.firstKit <= kit }
    }
}
