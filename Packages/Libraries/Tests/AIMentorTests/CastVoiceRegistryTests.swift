import Testing
import Foundation
@testable import AIMentor
import ForgeAI

@Suite("CastVoiceRegistry")
struct CastVoiceRegistryTests {

    // MARK: - Profile catalog presence + ordering

    @Test
    func registryShipsSixCanonicalProfiles() {
        let registry = CastVoiceRegistry()
        #expect(registry.profiles.count == 6)
    }

    @Test
    func profilesAreInChapterOrder() {
        let registry = CastVoiceRegistry()
        let slugs = registry.profiles.map(\.id)
        #expect(slugs == ["lacto", "yeast", "photo", "net", "spore", "guard"])
    }

    @Test
    func registeredSlugsCoversAllSlugConstants() {
        let registry = CastVoiceRegistry()
        let constants = Set(MicrobeCastVoiceProfiles.Slug.all)
        #expect(registry.registeredSlugs == constants)
    }

    @Test
    func slugLookupReturnsMatchingProfile() {
        let registry = CastVoiceRegistry()
        for slug in MicrobeCastVoiceProfiles.Slug.all {
            let profile = registry.profile(forSlug: slug)
            #expect(profile != nil, "Profile for slug \(slug) must be present")
            #expect(profile?.id == slug)
        }
    }

    @Test
    func slugLookupReturnsNilForUnknownSlug() {
        let registry = CastVoiceRegistry()
        #expect(registry.profile(forSlug: "nonexistent") == nil)
    }

    @Test
    func slugConstantsAreUnique() {
        let constants = MicrobeCastVoiceProfiles.Slug.all
        #expect(Set(constants).count == constants.count)
    }

    // MARK: - Catchphrase invariants

    @Test
    func everyProfileHasAtLeastThreeCatchphrases() {
        let registry = CastVoiceRegistry()
        #expect(registry.minimumCatchphraseCount >= 3)
        for profile in registry.profiles {
            #expect(profile.catchphrases.count >= 3, "Profile \(profile.id) needs >= 3 catchphrases")
        }
    }

    @Test
    func firstCatchphraseMatchesChapterPrimitiveLine() {
        let registry = CastVoiceRegistry()
        let expected: [String: String] = [
            "lacto": "Friend in your food. Friend in your gut.",
            "yeast": "I make air inside bread.",
            "photo": "Sunlight. Then air. Then everything else.",
            "net": "Forests talk through me.",
            "spore": "Some friends. Some not. All real.",
            "guard": "I check IDs. Patient and careful.",
        ]
        for (slug, primitive) in expected {
            let profile = registry.profile(forSlug: slug)
            #expect(profile?.catchphrases.first == primitive,
                    "Profile \(slug)'s first catchphrase must mirror the chapter primitive line")
        }
    }

    @Test
    func catchphrasesAreNonEmpty() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            for line in profile.catchphrases {
                #expect(!line.isEmpty, "Profile \(profile.id) has an empty catchphrase")
            }
        }
    }

    // MARK: - Embodiment invariants

    @Test
    func embodimentNamesThePrimitive() {
        let registry = CastVoiceRegistry()
        let expectedPrimitive: [String: String] = [
            "lacto": "helpful-bacteria",
            "yeast": "helpful-fungi",
            "photo": "photosynthetic-microbes",
            "net": "mycorrhizal-fungi",
            "spore": "pathogen",
            "guard": "immune-cells",
        ]
        for (slug, primitive) in expectedPrimitive {
            let profile = registry.profile(forSlug: slug)
            #expect(
                profile?.embodiment.contains(primitive) == true,
                "Profile \(slug)'s embodiment must reference '\(primitive)' per DN-S handoff schema"
            )
        }
    }

    @Test
    func embodimentIsAtLeastOneSentence() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            #expect(profile.embodiment.count > 40,
                    "Profile \(profile.id)'s embodiment must be substantive (≥ 40 chars)")
        }
    }

    // MARK: - Trauma-informed register stoplist

    /// The shared trauma-informed register stoplist. Anti-pattern strings
    /// reference these tokens as guards; the test ensures the catchphrases +
    /// embodiment NEVER contain the forbidden lexicon. Mirrors the parameterized
    /// stoplist on `MicrobeCharacter` catchphrases in `MicrobeCatalogServiceTests`.
    static let warfareStoplist: [String] = [
        "fight", "attack", "war", "battle", "enemy", "weapon",
        "soldier", "warrior", "kill", "destroy",
    ]

    /// Body-shame stoplist. Bodies + microbiomes are ecosystems, not moral tests.
    static let shameStoplist: [String] = [
        "dirty", "gross", "nasty", "ugly", "ashamed",
    ]

    /// COVID-trauma-aware stoplist. The cast never mentions COVID specifically;
    /// avoid pandemic-era imagery.
    static let covidStoplist: [String] = [
        "covid", "coronavirus", "pandemic",
    ]

    @Test
    func catchphrasesNeverContainWarfareLexicon() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            for line in profile.catchphrases {
                let lower = line.lowercased()
                for token in Self.warfareStoplist {
                    #expect(!lower.contains(token),
                            "Profile \(profile.id) catchphrase contains forbidden token '\(token)': \(line)")
                }
            }
        }
    }

    @Test
    func catchphrasesNeverContainShameLexicon() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            for line in profile.catchphrases {
                let lower = line.lowercased()
                for token in Self.shameStoplist {
                    #expect(!lower.contains(token),
                            "Profile \(profile.id) catchphrase contains forbidden token '\(token)': \(line)")
                }
            }
        }
    }

    @Test
    func embodimentNeverContainsCovidReferences() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            let lower = profile.embodiment.lowercased()
            for token in Self.covidStoplist {
                #expect(!lower.contains(token),
                        "Profile \(profile.id) embodiment contains COVID reference '\(token)'")
            }
        }
    }

    @Test
    func catchphrasesNeverReferenceCovid() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            for line in profile.catchphrases {
                let lower = line.lowercased()
                for token in Self.covidStoplist {
                    #expect(!lower.contains(token),
                            "Profile \(profile.id) catchphrase contains COVID reference '\(token)': \(line)")
                }
            }
        }
    }

    // MARK: - Anti-pattern guards

    @Test
    func sharedAntiPatternsAreLoadBearing() {
        let shared = MicrobeCastVoiceProfiles.sharedAntiPatterns
        #expect(shared.count >= 5, "Shared anti-pattern guard surface must remain substantive")
        let joined = shared.joined(separator: " ").lowercased()
        #expect(joined.contains("warfare"))
        #expect(joined.contains("shame"))
        #expect(joined.contains("covid"))
    }

    @Test
    func everyProfileShipsTheSharedAntiPatterns() {
        let registry = CastVoiceRegistry()
        let shared = Set(MicrobeCastVoiceProfiles.sharedAntiPatterns)
        for profile in registry.profiles {
            let owned = Set(profile.antiPatterns)
            #expect(shared.isSubset(of: owned),
                    "Profile \(profile.id) is missing one or more shared anti-pattern guards")
        }
    }

    @Test
    func sporeExtendsTheSharedAntiPatternsWithExtraGuards() {
        let registry = CastVoiceRegistry()
        guard let spore = registry.profile(forSlug: "spore") else {
            Issue.record("Spore profile missing")
            return
        }
        #expect(spore.antiPatterns.count > MicrobeCastVoiceProfiles.sharedAntiPatterns.count,
                "Spore must carry the strongest anti-pattern surface (shared + Spore-extra)")
        for extra in MicrobeCastVoiceProfiles.sporeExtraAntiPatterns {
            #expect(spore.antiPatterns.contains(extra),
                    "Spore must carry the Spore-extra guard: \(extra)")
        }
    }

    @Test
    func nonSporeProfilesDoNotShipSporeExtraGuards() {
        let registry = CastVoiceRegistry()
        for profile in registry.profiles where profile.id != "spore" {
            for extra in MicrobeCastVoiceProfiles.sporeExtraAntiPatterns {
                #expect(!profile.antiPatterns.contains(extra),
                        "Profile \(profile.id) shouldn't carry Spore-extra anti-pattern guard")
            }
        }
    }

    // MARK: - Reviewer gating

    @Test
    func everyProfileIsNotReviewerGated() {
        // Per the handoff: trauma-gating: NONE + moderation-sensitivity: .normal.
        let registry = CastVoiceRegistry()
        for profile in registry.profiles {
            #expect(profile.reviewerGated == false,
                    "Profile \(profile.id) should not be reviewer-gated per handoff")
        }
    }

    // MARK: - CastDialog wiring

    @Test
    func registerIntoCastDialogPopulatesAllSixProfiles() async throws {
        let registry = CastVoiceRegistry()
        let dialog = CastDialog()
        let registered = try await registry.register(into: dialog)
        #expect(registered == 6)
        for slug in MicrobeCastVoiceProfiles.Slug.all {
            let isRegistered = await dialog.isRegistered(slug)
            #expect(isRegistered, "Slug \(slug) should be registered after wiring")
        }
    }

    @Test
    func registeringCustomProfileSetExposesItForLookup() {
        let custom = CastVoiceProfile(
            id: "lacto",
            displayName: "Lacto-Test",
            embodiment: "Test embodiment.",
            catchphrases: ["a", "b", "c"]
        )
        let registry = CastVoiceRegistry(profiles: [custom])
        #expect(registry.profile(forSlug: "lacto")?.displayName == "Lacto-Test")
        #expect(registry.profiles.count == 1)
        #expect(registry.registeredSlugs == ["lacto"])
    }
}
