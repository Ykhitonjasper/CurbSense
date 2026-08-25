import SwiftUI

@main
@MainActor
struct CurbSenseApp: App {
    private let dependencies: AppDependencies
    @State private var store: CurbSenseStore

    init() {
        let dependencies = AppDependencies.app()
        self.dependencies = dependencies
        _store = State(initialValue: CurbSenseStore(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(store)
        }
    }
}
