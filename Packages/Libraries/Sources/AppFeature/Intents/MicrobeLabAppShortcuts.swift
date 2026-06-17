import Foundation
import AppIntents

/// Single `AppShortcutsProvider` for MicrobeLab. Apple discovers exactly
/// one provider per app via the AppIntents runtime; this is it. The
/// shortcuts surface in Siri / Spotlight / Shortcuts the first time the
/// kid launches the app.
///
/// Per Apple's HIG: provide up to ~10 shortcuts; each shortcut has 1-2
/// short phrases the user can speak to Siri. The phrases must include the
/// app name so Siri can disambiguate against other apps' shortcuts.
///
/// Trauma-informed posture: every phrase reads as a kid-friendly invitation
/// ("Open the microbe lab", "Show me the microbe codex"). No
/// engagement-pressure framing ("Earn XP fast!" / "Complete your daily
/// streak!").
public struct MicrobeLabAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenMicroscopeIntent(),
            phrases: [
                "Open Microscope in \(.applicationName)",
                "Show me the microscope in \(.applicationName)"
            ],
            shortTitle: "Open Microscope",
            systemImageName: "microscope"
        )
        AppShortcut(
            intent: OpenCodexIntent(),
            phrases: [
                "Open Codex in \(.applicationName)",
                "Show me the microbe codex in \(.applicationName)"
            ],
            shortTitle: "Open Codex",
            systemImageName: "book"
        )
        AppShortcut(
            intent: OpenMicrobiomeIntent(),
            phrases: [
                "Open Microbiome in \(.applicationName)",
                "Show me the microbiome in \(.applicationName)"
            ],
            shortTitle: "Open Microbiome",
            systemImageName: "leaf"
        )
        AppShortcut(
            intent: OpenDiseaseStoriesIntent(),
            phrases: [
                "Open Disease Stories in \(.applicationName)",
                "Show me the disease stories in \(.applicationName)"
            ],
            shortTitle: "Open Disease Stories",
            systemImageName: "book.closed.fill"
        )
        AppShortcut(
            intent: OpenVaccineExplainerIntent(),
            phrases: [
                "Open Vaccine Explainer in \(.applicationName)",
                "Show me the vaccine explainer in \(.applicationName)"
            ],
            shortTitle: "Open Vaccine Explainer",
            systemImageName: "syringe.fill"
        )
        AppShortcut(
            intent: OpenHistoricalContextIntent(),
            phrases: [
                "Open Historical Context in \(.applicationName)",
                "Show me the historical context cards in \(.applicationName)"
            ],
            shortTitle: "Open Historical Context",
            systemImageName: "person.crop.rectangle.stack"
        )
        AppShortcut(
            intent: OpenGlobalMicrobiomeTourIntent(),
            phrases: [
                "Open Global Tour in \(.applicationName)",
                "Show me the global microbiome tour in \(.applicationName)"
            ],
            shortTitle: "Open Global Tour",
            systemImageName: "globe.americas.fill"
        )
    }
}
