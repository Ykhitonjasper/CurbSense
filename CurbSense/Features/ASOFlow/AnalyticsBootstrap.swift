import FirebaseCore

enum AnalyticsBootstrap {
    private static var didStart = false

    static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    static func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        guard !ProcessInfo.processInfo.arguments.contains("UI-Testing") else { return }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }

        FirebaseApp.configure()
    }
}
