import Foundation
import Testing
@testable import Services

@Suite("AgeAssuranceService")
@MainActor
struct AgeAssuranceServiceTests {
    @Test func initialResultDefaultsToNotAttempted() {
        let service = AgeAssuranceService()
        #expect(service.result == .notAttempted)
    }

    @Test func recordResultUpdatesState() {
        let service = AgeAssuranceService()
        service.recordResult(.systemVerified(adult: true))
        #expect(service.result == .systemVerified(adult: true))
        service.recordResult(.systemDeclined)
        #expect(service.result == .systemDeclined)
    }

    @Test func requestSystemVerificationReturnsUnavailableWhenIncapable() async {
        // Test target's Bundle.main does not declare the entitlement, so
        // isCapable resolves to false here. `requestSystemVerification`
        // surfaces `.systemUnavailable` and records the same.
        let service = AgeAssuranceService()
        #expect(service.isCapable == false)
        let result = await service.requestSystemVerification()
        #expect(result == .systemUnavailable)
        #expect(service.result == .systemUnavailable)
    }
}

@Suite("AgeAssuranceCapability")
@MainActor
struct AgeAssuranceCapabilityTests {
    @Test func entitlementProbeIsFalseInTestBundle() {
        // The test bundle never ships an entitlements blob; the probe
        // returns false so downstream UI defaults to the math gate.
        #expect(AgeAssuranceCapability.isDeclaredAgeRangeAvailable == false)
    }

    @Test func entitlementKeyMatchesApple() {
        #expect(AgeAssuranceEntitlement.key == "com.apple.developer.declared-age-range")
    }
}

@Suite("AgeAssuranceResult")
struct AgeAssuranceResultTests {
    @Test func equalityCoversAllCases() {
        #expect(AgeAssuranceResult.notAttempted == .notAttempted)
        #expect(AgeAssuranceResult.systemVerified(adult: true) == .systemVerified(adult: true))
        #expect(AgeAssuranceResult.systemVerified(adult: false) != .systemVerified(adult: true))
        #expect(AgeAssuranceResult.systemDeclined != .systemUnavailable)
    }
}
