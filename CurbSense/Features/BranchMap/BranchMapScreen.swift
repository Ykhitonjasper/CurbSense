import Observation
import SwiftUI

struct BranchMapScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(payload: BranchMapPayload, dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(
            payload: payload,
            runbooks: dependencies.runbooks,
            sessions: dependencies.sessions,
            traversal: dependencies.traversal
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch viewModel.state {
                case .loaded(let map):
                    loadedContent(map)
                case .empty:
                    emptyContent
                }
            }
            .padding(20)
        }
        .background(AppBackground())
        .navigationTitle("Route map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Return") {
                    returnToActive()
                }
                .accessibilityLabel("Return to active check")
            }
        }
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedNodeID)
    }

    private func loadedContent(_ map: ViewModel.MapData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            header(map)
            progress(map.progress)
            legend

            VStack(alignment: .leading, spacing: 12) {
                Text("Observation path")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(map.nodes) { node in
                    Button {
                        viewModel.select(node)
                    } label: {
                        nodeCard(node, status: map.status(for: node), isSelected: viewModel.selectedNodeID == node.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: node, status: map.status(for: node)))
                    .accessibilityHint("Selects this observation in the route map")
                }
            }
        }
    }

    private func header(_ map: ViewModel.MapData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(map.runbookTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Review what you have visited, the current observation, and the remaining route.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func progress(_ progress: BranchProgress) -> some View {
        let completed = min(progress.visitedCount, progress.totalCount)
        let value = progress.totalCount > 0 ? Double(completed) / Double(progress.totalCount) : 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Path progress")
                    .font(.headline)
                Spacer()
                Text("\(completed) of \(progress.totalCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .foregroundStyle(AppTheme.textPrimary)

            ProgressView(value: value)
                .tint(AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Path progress")
        .accessibilityValue("\(completed) of \(progress.totalCount) observations visited")
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem("Visited", icon: "checkmark.circle.fill", color: AppTheme.accent)
            legendItem("Current", icon: "location.circle.fill", color: AppTheme.textPrimary)
            legendItem("Remaining", icon: "circle", color: AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Map legend: visited, current, and remaining observations")
    }

    private func legendItem(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
    }

    private func nodeCard(_ node: Node, status: ViewModel.NodeStatus, isSelected: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundStyle(status.color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Step \(node.sequenceIndex)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(status.color)
                    Spacer()
                    Text(status.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text(node.prompt)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                if isSelected {
                    Text("Selected observation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? AppTheme.accent : AppTheme.hairline, lineWidth: isSelected ? 2 : 1)
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("Route map unavailable", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
        } description: {
            Text("Return to the active check to continue the observation path.")
        } actions: {
            Button("Return to active check") {
                returnToActive()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Return to active check")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func accessibilityLabel(for node: Node, status: ViewModel.NodeStatus) -> String {
        "Step \(node.sequenceIndex), \(status.title). \(node.prompt)"
    }

    private func returnToActive() {
        guard !store.path.isEmpty else { return }
        store.path.removeLast()
    }
}

extension BranchMapScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded(MapData)
            case empty
        }

        enum NodeStatus {
            case visited
            case current
            case remaining

            var title: String {
                switch self {
                case .visited: "Visited"
                case .current: "Current"
                case .remaining: "Remaining"
                }
            }

            var icon: String {
                switch self {
                case .visited: "checkmark.circle.fill"
                case .current: "location.circle.fill"
                case .remaining: "circle"
                }
            }

            var color: Color {
                switch self {
                case .visited: AppTheme.accent
                case .current: AppTheme.textPrimary
                case .remaining: AppTheme.textSecondary
                }
            }
        }

        struct MapData {
            let runbookTitle: String
            let session: RunSession
            let nodes: [Node]
            let progress: BranchProgress

            func status(for node: Node) -> NodeStatus {
                if node.id == session.currentNodeID {
                    return .current
                }
                if session.visitedNodeIDs.contains(node.id) {
                    return .visited
                }
                return .remaining
            }
        }

        private let payload: BranchMapPayload
        private let runbooks: any RunbookRepository
        private let sessions: any RunSessionRepository
        private let traversal: any RunbookTraversing

        var state: State = .empty
        var selectedNodeID: String?

        init(
            payload: BranchMapPayload,
            runbooks: any RunbookRepository,
            sessions: any RunSessionRepository,
            traversal: any RunbookTraversing
        ) {
            self.payload = payload
            self.runbooks = runbooks
            self.sessions = sessions
            self.traversal = traversal
            self.selectedNodeID = payload.selectedNodeID
        }

        func load() {
            guard let session = sessions.allSessions().first(where: { $0.id == payload.sessionID }) else {
                state = .empty
                return
            }

            let nodes = runbooks.nodes(runbookID: session.runbookID)
                .sorted { $0.sequenceIndex < $1.sequenceIndex }
            guard !nodes.isEmpty,
                  let runbook = runbooks.runbook(id: session.runbookID) else {
                state = .empty
                return
            }

            let progress = traversal.branchProgress(session: session, nodes: nodes)
            let displayedNodeIDs = Set(session.visitedNodeIDs)
                .union(progress.remainingNodeIDs)
                .union([session.currentNodeID])
            let visibleNodes = payload.showVisitedOnly
                ? nodes.filter { session.visitedNodeIDs.contains($0.id) || $0.id == session.currentNodeID }
                : nodes.filter { displayedNodeIDs.contains($0.id) }
            guard !visibleNodes.isEmpty else {
                state = .empty
                return
            }

            if !visibleNodes.contains(where: { $0.id == selectedNodeID }) {
                selectedNodeID = session.currentNodeID
            }

            state = .loaded(MapData(
                runbookTitle: runbook.title,
                session: session,
                nodes: visibleNodes,
                progress: progress
            ))
        }

        func select(_ node: Node) {
            selectedNodeID = node.id
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let store = CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true)

    return BranchMapScreen(
        payload: BranchMapPayload(
            id: "branch-map-session-001",
            sessionID: "session-001",
            selectedNodeID: "node-01-06",
            showVisitedOnly: false
        ),
        dependencies: dependencies
    )
    .environment(store)
}
