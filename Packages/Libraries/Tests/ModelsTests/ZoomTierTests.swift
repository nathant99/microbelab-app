import Foundation
import Testing
@testable import Models

@Suite("ZoomTier")
nonisolated struct ZoomTierTests {
    @Test func ordering() {
        #expect(ZoomTier.unaided < ZoomTier.light)
        #expect(ZoomTier.light < ZoomTier.fluorescence)
        #expect(ZoomTier.fluorescence < ZoomTier.electron)
    }

    @Test func magnificationLadder() {
        #expect(ZoomTier.unaided.magnification == 1)
        #expect(ZoomTier.light.magnification == 100)
        #expect(ZoomTier.fluorescence.magnification == 1_000)
        #expect(ZoomTier.electron.magnification == 10_000)
    }

    @Test func nextPrevious() {
        #expect(ZoomTier.unaided.next == .light)
        #expect(ZoomTier.electron.next == nil)
        #expect(ZoomTier.unaided.previous == nil)
        #expect(ZoomTier.electron.previous == .fluorescence)
    }

    @Test func codableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(ZoomTier.fluorescence)
        let decoded = try JSONDecoder().decode(ZoomTier.self, from: encoded)
        #expect(decoded == .fluorescence)
    }
}
