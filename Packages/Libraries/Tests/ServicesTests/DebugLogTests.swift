import Testing
@testable import Services

@Suite("DebugLog")
nonisolated struct DebugLogTests {
    // Smoke test only — `print()`-based logger has no observable side
    // effects in a release build. The real verification is "every call
    // compiles to () outside DEBUG". Calling the API here just ensures the
    // public surface stays callable and gated as expected.

    @Test func categoryMethodsAreCallable() {
        DebugLog.startup("test")
        DebugLog.lifecycle("test")
        DebugLog.state("test")
        DebugLog.network("test")
        DebugLog.data("test")
        DebugLog.data("test", error: TestError.example)
        DebugLog.permission("test")
        DebugLog.error("test")
        DebugLog.error("test", error: TestError.example)
        DebugLog.mentor("test")
    }
}

private enum TestError: Error {
    case example
}
