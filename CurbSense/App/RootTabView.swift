import SwiftUI

struct RootTabView: View {
    let dependencies: AppDependencies
    @Environment(CurbSenseStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationStack(path: $store.path) {
            TabView(selection: tabSelection) {
                RunbookCatalogScreen(
                    runbooks: dependencies.runbooks,
                    recoveryCards: dependencies.recoveryCards
                )
                    .tabItem {
                        Label("Runbooks", systemImage: "books.vertical")
                    }
                    .tag("Runbooks")
                    .accessibilityLabel("Runbooks")

                ActiveStepScreen(dependencies: dependencies)
                    .tabItem {
                        Label("Active", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                    .tag("Active")
                    .accessibilityLabel("Active")

                RunHistoryScreen(dependencies: dependencies)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag("History")
                    .accessibilityLabel("History")

                SettingsScreen()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag("Settings")
                    .accessibilityLabel("Settings")
            }
            .modifier(NavigationIntegrator(dependencies: dependencies))
        }
    }

    private var tabSelection: Binding<String> {
        Binding(
            get: {
                switch store.selectedTab {
                case "runbooks":
                    "Runbooks"
                case "active":
                    "Active"
                case "history":
                    "History"
                case "settings":
                    "Settings"
                default:
                    store.selectedTab
                }
            },
            set: { store.selectedTab = $0 }
        )
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RootTabView(dependencies: dependencies)
        .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
