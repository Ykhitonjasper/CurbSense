import SwiftUI

struct RootView: View {
    @Environment(CurbSenseStore.self) private var store

    private let dependencies: AppDependencies
    @State private var launch: AppLaunch
    @StateObject private var appCover = AppCover()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @MainActor
    init(dependencies: AppDependencies, launch: AppLaunch? = nil) {
        self.dependencies = dependencies
        _launch = State(initialValue: launch ?? AppLaunch(dependencies: dependencies))
    }

    var body: some View {
        ZStack {
            if let webView = displayedWeb {
                coveredWebView(webView)
                    .scaleEffect(webSettleScale)
            } else if case .native = launch.phase {
                coveredNative
            } else {
                AppTheme.bgBase.ignoresSafeArea()
            }
        }
        .overlay {
            loaderOverlay
        }
        .environment(store)
        .tint(AppTheme.accent)
        .sensoryFeedback(.impact(weight: .medium), trigger: launch.loaderProgress >= 1)
        .task { await launch.start() }
        .onChange(of: scenePhase) { _, phase in
            appCover.handleScenePhase(phase)
        }
    }

    private var webSettleScale: CGFloat {
        guard launch.phase.isLoading || launch.coverOpacity > 0.02 else { return 1 }
        return 1 + CGFloat(launch.coverOpacity) * 0.018
    }

    private var displayedWeb: WebViewController? {
        if case .web(let webView) = launch.phase { return webView }
        return launch.pendingWeb
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.16, 1.0, 0.3, 1.0, duration: revealDuration)
    }

    private var revealDuration: TimeInterval {
        switch launch.coverStyle {
        case .scrim: return Timeouts.warmScrimMax
        case .warm: return Timeouts.warmRevealCrossfade
        case .branded, .invisible: return Timeouts.revealCrossfade
        }
    }

    @ViewBuilder
    private var loaderOverlay: some View {
        let veil = launch.coverOpacity
        Group {
            switch launch.phase {
            case .loading:
                switch launch.coverStyle {
                case .branded:
                    BrandedSplash(progress: launch.loaderProgress, veil: veil)
                case .warm:
                    WarmOverlay(progress: launch.loaderProgress, veil: veil)
                case .scrim:
                    WarmScrim(progress: launch.loaderProgress, veil: veil)
                case .invisible:
                    Color.clear
                }
            default:
                EmptyView()
            }
        }
        .animation(revealAnimation, value: veil)
    }

    private func coveredWebView(_ webView: WebViewController) -> some View {
        ZStack {
            WebViewScreen(webView: webView)
            coverLayer
        }
        .ignoresSafeArea()
        .animation(revealAnimation, value: launch.coverOpacity)
        .onDisappear {
            appCover.deactivateImmediately()
        }
    }

    private var coveredNative: some View {
        ZStack {
            nativeTree
            coverLayer
        }
    }

    @ViewBuilder
    private var coverLayer: some View {
        if appCover.isCoverVisible {
            CurbSenseCover()
                .transition(.opacity)
                .contentShape(Rectangle())
                .onTapGesture { appCover.deactivateImmediately() }
        }
    }

    @ViewBuilder
    private var nativeTree: some View {
        if store.hasCompletedOnboarding {
            RootTabView(dependencies: dependencies)
        } else {
            OnboardingScreen()
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RootView(dependencies: dependencies, launch: .previewNative())
        .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
