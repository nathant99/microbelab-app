import Foundation

/// Categorized debug logger for MicrobeLab. Single-seam emitter — every
/// category is one line so release builds compile to `()` with zero overhead.
///
/// Pattern lifted from CuriosityQuest per `.claude/rules/debug-logging.md`.
/// Categories map to detection domains, not implementation layers.
///
/// All methods are `nonisolated` so they're callable from any context (view
/// body, nonisolated callback, background queue) without an isolation hop.
///
/// Usage:
/// ```
/// DebugLog.lifecycle("scenePhase \(old) → \(new)")
/// DebugLog.state("ZoomMachine \(machine.currentTier)")
/// DebugLog.data("PlayerProgress.save — modelContext.save failed", error: error)
/// ```
public nonisolated enum DebugLog: Sendable {
    public nonisolated static func startup(_ message: String, _ context: StaticString = #function) {
        emit("STARTUP", message, context)
    }

    public nonisolated static func lifecycle(_ message: String, _ context: StaticString = #function) {
        emit("LIFE", message, context)
    }

    public nonisolated static func state(_ message: String, _ context: StaticString = #function) {
        emit("STATE", message, context)
    }

    public nonisolated static func network(_ message: String, _ context: StaticString = #function) {
        emit("NET", message, context)
    }

    /// Silent-`try?`-replacement category. Pair with a logged `catch` block
    /// per `.claude/rules/debug-logging.md` § Replace silent `try?` with
    /// logged catches.
    public nonisolated static func data(_ message: String, error: Error? = nil, _ context: StaticString = #function) {
        if let error {
            emit("DATA", "\(message): \(error)", context)
        } else {
            emit("DATA", message, context)
        }
    }

    public nonisolated static func permission(_ message: String, _ context: StaticString = #function) {
        emit("PERM", message, context)
    }

    /// Always-emit category — even gated-verbose toggles should not silence
    /// errors. Surface every swallowed catch through this seam.
    public nonisolated static func error(_ message: String, error: Error? = nil, _ context: StaticString = #function) {
        if let error {
            emit("ERR", "\(message): \(error)", context)
        } else {
            emit("ERR", message, context)
        }
    }

    /// FoundationModels / Cilia mentor lifecycle. Always emit since this is
    /// operationally noisy + diagnostic on AI-availability changes.
    public nonisolated static func mentor(_ message: String, _ context: StaticString = #function) {
        emit("MENTOR", message, context)
    }

    // MARK: - Internal seam

    private nonisolated static func emit(_ category: String, _ message: String, _ context: StaticString) {
        #if DEBUG
        let thread = Thread.isMainThread ? "main" : "bg(\(Thread.current.name ?? "unnamed"))"
        print("[\(category)] \(context) — \(message) [thread=\(thread)]")
        #endif
    }
}
