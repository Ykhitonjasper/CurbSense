import XCTest
@testable import CurbSense

final class MockAnalyticsSession: AnalyticsSessionProviding, @unchecked Sendable {
    var cachedRouteURL: String?
    var hasFinalURL = false
    var online = true

    func isOnline() async -> Bool { online }
    func clearCache() {}
    func setFinalURLIfNeeded(_ url: String) {}
}

final class MockAnalyticsCoordinator: AnalyticsCoordinating, @unchecked Sendable {
    var resultToReturn: TrackResult = .nativeUI
    var resolveDelay: TimeInterval = 0.0

    func resolveResult() async -> TrackResult {
        if resolveDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(resolveDelay * 1_000_000_000))
        }
        return resultToReturn
    }
}

@MainActor
final class StartupRouterTests: XCTestCase {
    private func makeDependencies(
        coordinator: MockAnalyticsCoordinator,
        session: MockAnalyticsSession
    ) -> AppDependencies {
        let archive = CurbSenseArchiveStore.memory()
        return AppDependencies(
            runbooks: SeededRunbookRepository(store: archive),
            sessions: SeededRunSessionRepository(store: archive),
            recoveryCards: SeededRecoveryCardRepository(),
            actionPacks: SeededActionPackRepository(store: archive),
            glossary: SeededGlossaryRepository(),
            localState: ArchiveLocalStateRepository(store: archive),
            traversal: DeterministicRunbookEngine(),
            formatter: PlainTextActionPackFormatter(),
            analyticsCoordinator: coordinator,
            analyticsSession: session
        )
    }

    func testOfflineDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        session.online = false
        coordinator.resultToReturn = .nativeUI

        let router = StartupRouter(dependencies: makeDependencies(coordinator: coordinator, session: session))
        await router.start()

        if case .native = router.phase {
            return
        }
        XCTFail("Expected native phase due to offline")
    }

    func testEmptyEndpointDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .nativeUI

        let router = StartupRouter(dependencies: makeDependencies(coordinator: coordinator, session: session))
        await router.start()

        if case .native = router.phase {
            return
        }
        XCTFail("Expected native phase due to empty endpoint")
    }

    func testTimeoutDefaultsToNative() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resolveDelay = 4.5
        coordinator.resultToReturn = .experiment(url: "https://example.com/experiment")

        let router = StartupRouter(dependencies: makeDependencies(coordinator: coordinator, session: session))
        await router.start()

        if case .native = router.phase {
            return
        }
        XCTFail("Expected native phase due to timeout, got \(router.phase)")
    }

    func testValidExperimentReturnsExperiment() async {
        let coordinator = MockAnalyticsCoordinator()
        let session = MockAnalyticsSession()
        coordinator.resultToReturn = .experiment(url: "about:blank")

        let router = StartupRouter(dependencies: makeDependencies(coordinator: coordinator, session: session))
        await router.start()

        if case .experiment = router.phase {
            return
        }
        XCTFail("Expected experiment phase, got \(router.phase)")
    }
}
