import SwiftUI

struct NavigationIntegrator: ViewModifier {
    let dependencies: AppDependencies
    @Environment(CurbSenseStore.self) private var store
    @State private var duplicatePayload: DuplicatePayload?

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
            .sheet(item: $duplicatePayload) { payload in
                DuplicateTitleScreen(payload: payload, dependencies: dependencies)
            }
            .task {
                extractDuplicateRoute()
            }
            .onChange(of: store.path) {
                extractDuplicateRoute()
            }
            .onChange(of: store.hasCompletedOnboarding) { _, hasCompletedOnboarding in
                if !hasCompletedOnboarding {
                    duplicatePayload = nil
                }
            }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .runbookDetail(let payload):
            RunbookDetailScreen(payload: payload, dependencies: dependencies)
        case .recoveryLibrary(let payload):
            RecoveryLibraryScreen(recoveryCards: dependencies.recoveryCards, payload: payload)
        case .branchMap(let payload):
            BranchMapScreen(payload: payload, dependencies: dependencies)
        case .verdict(let payload):
            VerdictScreen(dependencies: dependencies, payload: payload)
        case .actionPack(let payload):
            ActionPackScreen(payload: payload, dependencies: dependencies)
        case .historyDetail(let payload):
            HistoryDetailScreen(payload: payload, dependencies: dependencies)
        case .duplicateTitle:
            EmptyView()
        case .glossary(let payload):
            ObservationGlossaryScreen(glossary: dependencies.glossary, payload: payload)
        }
    }

    private func extractDuplicateRoute() {
        guard case .duplicateTitle(let payload)? = store.path.last else {
            return
        }
        store.path.removeLast()
        duplicatePayload = payload
    }
}
