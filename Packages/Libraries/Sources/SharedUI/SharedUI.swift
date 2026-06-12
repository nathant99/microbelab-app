import SwiftUI

/// Placeholder root file for the `SharedUI` target. Real components land in
/// follow-up PRs (microscope HUD, cast cards, codex grid, mentor speech bubble).
///
/// Per `.claude/rules/forgekit.md` § ForgeUI Quick Reference, prefer ForgeKit
/// components (`ForgeXPBar` / `ForgeScoreHUD` / `ForgeStreakBadge` / etc.) over
/// hand-rolled equivalents whenever a ForgeUI component already covers the
/// pattern.
public enum SharedUIVersion {
    public static let stub = "phase1-scaffold"
}
