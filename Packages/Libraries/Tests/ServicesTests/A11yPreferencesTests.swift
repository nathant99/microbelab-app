import Foundation
import Testing
@testable import Services

@Suite("A11yPreferences")
struct A11yPreferencesTests {
    @Test func defaultsAreNoReduction() {
        let prefs = A11yPreferences.none
        #expect(prefs.reduceMotion == false)
        #expect(prefs.reduceTransparency == false)
    }

    @Test func systemReductionPropagates() {
        let prefs = A11yPreferences.resolved(
            systemReduceMotion: true,
            systemReduceTransparency: true,
            settings: .default
        )
        #expect(prefs.reduceMotion == true)
        #expect(prefs.reduceTransparency == true)
    }

    @Test func forceReduceMotionAlone() {
        var settings = AppSettings.default
        settings.forceReduceMotion = true
        let prefs = A11yPreferences.resolved(
            systemReduceMotion: false,
            systemReduceTransparency: false,
            settings: settings
        )
        #expect(prefs.reduceMotion == true)
        #expect(prefs.reduceTransparency == false)
    }

    @Test func forceReduceTransparencyAlone() {
        var settings = AppSettings.default
        settings.forceReduceTransparency = true
        let prefs = A11yPreferences.resolved(
            systemReduceMotion: false,
            systemReduceTransparency: false,
            settings: settings
        )
        #expect(prefs.reduceMotion == false)
        #expect(prefs.reduceTransparency == true)
    }

    @Test func forceCannotUnreduceSystem() {
        // If iOS has been told to reduce motion, the app's "force off"
        // toggle (which doesn't exist — toggles only force MORE reduction)
        // can never override. The OR semantics make this structurally
        // true; this test pins the invariant.
        let settings = AppSettings.default // both force fields default to false
        let prefs = A11yPreferences.resolved(
            systemReduceMotion: true,
            systemReduceTransparency: true,
            settings: settings
        )
        #expect(prefs.reduceMotion == true)
        #expect(prefs.reduceTransparency == true)
    }

    @Test func bothForcedTogether() {
        var settings = AppSettings.default
        settings.forceReduceMotion = true
        settings.forceReduceTransparency = true
        let prefs = A11yPreferences.resolved(
            systemReduceMotion: false,
            systemReduceTransparency: false,
            settings: settings
        )
        #expect(prefs.reduceMotion == true)
        #expect(prefs.reduceTransparency == true)
    }
}
