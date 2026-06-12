import Foundation
import Testing
@testable import Models

/// Sanity tests for the `PerfSignpost` value-type wrapper. The signposter
/// itself is owned by `os.signpost` — these tests pin that the wrapper
/// types compose, channels stay unique per category, and the `interval`
/// closure form returns the wrapped value.
@Suite("PerfSignpost")
struct PerfSignpostTests {
    @Test func canonicalChannelsExist() {
        // Compile-time presence + Sendable conformance.
        let _: PerfSignpost.Channel = PerfSignpost.zoomTransition
        let _: PerfSignpost.Channel = PerfSignpost.simulatorTick
        let _: PerfSignpost.Channel = PerfSignpost.immuneWave
    }

    @Test func intervalReturnsClosureResult() {
        let value = PerfSignpost.simulatorTick.interval("test") { 42 }
        #expect(value == 42)
    }

    @Test func intervalSurfacesThrownErrors() {
        struct Boom: Error {}
        var didThrow = false
        do {
            _ = try PerfSignpost.zoomTransition.interval("throwTest") {
                throw Boom()
            }
        } catch is Boom {
            didThrow = true
        } catch {
            Issue.record("unexpected error: \(error)")
        }
        #expect(didThrow)
    }

    @Test func customChannelInitializes() {
        let channel = PerfSignpost.Channel(subsystem: "com.microbelab.tests", category: "custom")
        let result = channel.interval("ok") { "value" }
        #expect(result == "value")
    }
}
