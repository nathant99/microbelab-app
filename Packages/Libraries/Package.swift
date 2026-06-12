// swift-tools-version: 6.2
import PackageDescription

// MARK: - Swift Settings
//
// Applied to EVERY target — Xcode build settings (SWIFT_DEFAULT_ACTOR_ISOLATION,
// SWIFT_APPROACHABLE_CONCURRENCY) do NOT propagate to SPM package targets.
// See `.claude/rules/spm-architecture.md` § Build Settings in SPM.

let defaultSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-default-isolation", "MainActor"]),
    .enableExperimentalFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "Libraries",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "SharedUI", targets: ["SharedUI"]),
        .library(name: "GameEngine", targets: ["GameEngine"]),
        .library(name: "AIMentor", targets: ["AIMentor"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathant99/forgekit.git", from: "0.99.0"),
    ],
    targets: [
        // MARK: - Models
        // Domain value types (Sendable, nonisolated) + SwiftData @Model classes.
        // No bundled resources — microbe catalog JSON lives in `Services/Resources/`.
        .target(
            name: "Models",
            dependencies: [
                .product(name: "ForgeModels", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - Services
        // Persistence, audio, networking, AI session management.
        .target(
            name: "Services",
            dependencies: [
                "Models",
                .product(name: "ForgePersistence", package: "forgekit"),
                .product(name: "ForgeGamification", package: "forgekit"),
                .product(name: "ForgeAccessibility", package: "forgekit"),
                .product(name: "ForgeModels", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - SharedUI
        // Reusable SwiftUI components with ForgeUI theme integration.
        .target(
            name: "SharedUI",
            dependencies: [
                "Models",
                .product(name: "ForgeUI", package: "forgekit"),
                .product(name: "ForgePedagogy", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - GameEngine
        // SpriteKit microscope-zoom scenes, microbiome simulator, immune minigame.
        .target(
            name: "GameEngine",
            dependencies: [
                "Models",
                .product(name: "ForgeGameEngine", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - AIMentor
        // FoundationModels @Generable types, Vee Socratic mentor session.
        .target(
            name: "AIMentor",
            dependencies: [
                "Models",
                .product(name: "ForgeAI", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - AppFeature
        // Root view, navigation, app coordinator. ForgeKit hub modules live here.
        .target(
            name: "AppFeature",
            dependencies: [
                "Models",
                "Services",
                "SharedUI",
                "GameEngine",
                "AIMentor",
                .product(name: "ForgeAdventure", package: "forgekit"),
                .product(name: "ForgeCelebration", package: "forgekit"),
                .product(name: "ForgeNavigation", package: "forgekit"),
                .product(name: "ForgeAccessibility", package: "forgekit"),
                .product(name: "ForgeGamification", package: "forgekit"),
                .product(name: "ForgeAnalytics", package: "forgekit"),
                .product(name: "ForgeAvatar", package: "forgekit"),
                .product(name: "ForgeSync", package: "forgekit"),
                .product(name: "ForgeKnowledgeGraph", package: "forgekit"),
                .product(name: "ForgePedagogy", package: "forgekit"),
                .product(name: "ForgeModels", package: "forgekit"),
                .product(name: "ForgeUI", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - Test Targets
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "AIMentorTests",
            dependencies: ["AIMentor"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI", "Models"],
            swiftSettings: defaultSwiftSettings
        ),
    ]
)
