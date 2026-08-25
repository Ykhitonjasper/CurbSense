import UIKit
import FirebaseCore
import FirebaseRemoteConfig

public final class AnalyticsCoordinator: @unchecked Sendable {
    public static let shared = AnalyticsCoordinator()

    private init() {}

    public func resolveResult() async -> TrackResult {
        guard FirebaseApp.app() != nil else { return .nativeUI }
        let endpoint = await fetchEndpoint()
        guard !endpoint.isEmpty else { return .nativeUI }
        return await AnalyticsSession.shared.decide(endpoint: endpoint)
    }

    public func clearExperimentCache() {
        AnalyticsSession.shared.clearCache()
    }

    private func fetchEndpoint() async -> String {
        guard FirebaseApp.app() != nil else { return "" }

        return await withCheckedContinuation { continuation in
            let box = OneShotContinuation(continuation)
            let rc = RemoteConfig.remoteConfig()
            let settings = RemoteConfigSettings()
            #if DEBUG
            settings.minimumFetchInterval = 0
            #else
            settings.minimumFetchInterval = 3600
            #endif
            settings.fetchTimeout = AnalyticsTracker.remoteConfigTimeout
            rc.configSettings = settings
            rc.setDefaults([AnalyticsTracker.endpointKey: "" as NSObject])

            rc.fetchAndActivate { _, _ in
                box.resume(rc.configValue(forKey: AnalyticsTracker.endpointKey).stringValue ?? "")
            }
        }
    }
}
