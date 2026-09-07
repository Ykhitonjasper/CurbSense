import XCTest
@testable import CurbSense

final class MockSession: AppSessionType, @unchecked Sendable {
    var cachedURL: String?
    var isLocalOnly = false
    var online = true
    var launchCount = 0

    var decision: LoadResult = .local

    var readyCount = 0
    var storedDestinations: [String] = []
    var reportedEndpoints: [String] = []
    var recordedLaunches = 0

    func isOnline() async -> Bool { online }
    func refreshOnline() async -> Bool { online }

    func resolve(url: String) async -> LoadResult {
        reportedEndpoints.append(url)
        return decision
    }

    func markReady() { readyCount += 1 }
    func markMiss() {}
    func storeDestination(_ url: String) { storedDestinations.append(url) }
    func clearURLForRetry() -> String? { nil }
    func recordLaunch() { recordedLaunches += 1; launchCount += 1 }
}

final class MockAppClient: AppClientType, @unchecked Sendable {
    var resultToReturn: LoadResult = .local
    var resolveDelay: TimeInterval = 0.0

    func resolveResult() async -> LoadResult {
        if resolveDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(resolveDelay * 1_000_000_000))
        }
        return resultToReturn
    }
}

@MainActor
final class AppLaunchTests: XCTestCase {
    private func makeDependencies(
        client: MockAppClient,
        session: MockSession
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
            appClient: client,
            appSession: session
        )
    }

    func testOfflineDefaultsToNative() async {
        let client = MockAppClient()
        let session = MockSession()
        session.online = false
        client.resultToReturn = .local

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        if case .native = launch.phase { return }
        XCTFail("Expected native phase due to offline")
    }

    func testEmptyEndpointDefaultsToNative() async {
        let client = MockAppClient()
        let session = MockSession()
        client.resultToReturn = .local

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        if case .native = launch.phase { return }
        XCTFail("Expected native phase due to empty endpoint")
    }

    func testTimeoutDefaultsToNative() async {
        let client = MockAppClient()
        let session = MockSession()
        client.resolveDelay = Timeouts.decisionDeadline + 0.5
        client.resultToReturn = .web(url: "about:blank")

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        if case .native = launch.phase { return }
        XCTFail("Expected native phase due to timeout, got \(launch.phase)")
    }

    func testValidAttachedRouteReturnsAttached() async {
        let client = MockAppClient()
        let session = MockSession()
        client.resultToReturn = .web(url: "about:blank")

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        if case .web = launch.phase { return }
        XCTFail("Expected attached phase, got \(launch.phase)")
    }

    func testLockedSessionStaysNativeEvenIfCoordinatorReturnsAttached() async {
        let client = MockAppClient()
        let session = MockSession()
        session.isLocalOnly = true
        client.resultToReturn = .web(url: "about:blank")

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        if case .native = launch.phase { return }
        XCTFail("Expected native phase due to fail lock, got \(launch.phase)")
    }

    func testALateDecisionStillStoresTheRouteForTheNextLaunch() async {
        let client = MockAppClient()
        let session = MockSession()
        client.resolveDelay = Timeouts.decisionDeadline + 0.3
        client.resultToReturn = .web(url: "about:blank")

        let launch = AppLaunch(dependencies: makeDependencies(client: client, session: session))
        await launch.start()

        guard case .native = launch.phase else {
            return XCTFail("Expected native phase after a missed deadline, got \(launch.phase)")
        }
        XCTAssertEqual(session.storedDestinations, [], "Nothing is known until the late answer lands")

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, session.readyCount == 0 {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        XCTAssertEqual(session.readyCount, 1, "The late route should commit off-screen")
        XCTAssertEqual(session.storedDestinations, ["about:blank"])
    }

    func testLockedSessionSkipsTheWarmupEntirely() async {
        let session = MockSession()
        session.isLocalOnly = true

        let launch = AppLaunch(
            dependencies: makeDependencies(client: MockAppClient(), session: session)
        )

        guard case .native = launch.phase else {
            return XCTFail("Expected native phase before start(), got \(launch.phase)")
        }

        let began = Date()
        await launch.start()
        XCTAssertLessThan(Date().timeIntervalSince(began), Timeouts.warmOverlayMin)
    }

    func testColdTierWhenCacheMissing() {
        XCTAssertEqual(LaunchTier.resolve(cachedURL: nil), .cold)
        XCTAssertEqual(LaunchTier.resolve(cachedURL: "https://example.test/go"), .warm)
        XCTAssertEqual(Timeouts.coldLaunchBudget, 5.2, accuracy: 0.01)
        XCTAssertEqual(Timeouts.warmLaunchBudget, 2.8, accuracy: 0.01)
        XCTAssertEqual(Timeouts.decisionDeadline, 3.0, accuracy: 0.01)
        XCTAssertEqual(Timeouts.minimumContentScore, 9)
    }
}
