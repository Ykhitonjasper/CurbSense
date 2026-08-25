import SwiftUI

@MainActor
struct RootView: View {
    @Environment(CurbSenseStore.self) private var store

    private let dependencies: AppDependencies
    @State private var router: StartupRouter

    init(dependencies: AppDependencies, router: StartupRouter? = nil) {
        self.dependencies = dependencies
        _router = State(initialValue: router ?? StartupRouter(dependencies: dependencies))
    }

    var body: some View {
        Group {
            switch router.phase {
            case .warming:
                CurbSenseWarmupView()
            case .native:
                if store.hasCompletedOnboarding {
                    RootTabView(dependencies: dependencies)
                } else {
                    OnboardingScreen()
                }
            case .experiment(let webView):
                ExperimentWebViewWrapper(webView: webView)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.phase.isWarming)
        .environment(store)
        .tint(AppTheme.accent)
        .sensoryFeedback(.impact(weight: .light), trigger: router.phase.isWarming)
        .task { await router.start() }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RootView(dependencies: dependencies, router: .previewNative())
        .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
