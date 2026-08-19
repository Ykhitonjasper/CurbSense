import Observation
import SwiftUI

struct ActiveStepScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(
            runbooks: dependencies.runbooks,
            traversal: dependencies.traversal
        ))
    }

    var body: some View {
        ZStack {
            AppBackground()

            if let session = store.activeSession,
               let node = viewModel.currentNode(for: session) {
                loadedContent(session: session, node: node)
            } else {
                emptyContent
            }
        }
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: store.activeSession?.currentNodeID)
    }

    private func loadedContent(session: RunSession, node: Node) -> some View {
        let progress = viewModel.progress(for: session)

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                progressRail(progress)

                VStack(alignment: .leading, spacing: 16) {
                    Label("Current observation", systemImage: observationIcon(for: node.observationKind))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text(node.prompt)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        openGlossary(for: node)
                    } label: {
                        Label("Learn this observation", systemImage: "book.closed")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .accessibilityLabel("Open observation glossary")
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current observation. \(node.prompt)")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose what you observed")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(Array(zip(node.choiceIDs, node.choiceLabels)), id: \.0) { choiceID, label in
                        Button {
                            store.choose(choiceID)
                        } label: {
                            HStack(spacing: 14) {
                                Text(label)
                                    .font(.body.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 12)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose \(label)")
                        .accessibilityHint("Advances to the next observation")
                    }
                }

                Button {
                    openBranchMap(for: session, node: node)
                } label: {
                    Label("View route map", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("View route map")
                .accessibilityHint("Shows visited, current, and remaining observations")
            }
            .padding(20)
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("No active check", systemImage: "checklist")
        } description: {
            Text("Choose a runbook to begin a guided observation path.")
        } actions: {
            Button("Browse runbooks") {
                store.selectedTab = "runbooks"
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Browse runbooks")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(24)
    }

    private func progressRail(_ progress: BranchProgress) -> some View {
        let completed = min(progress.visitedCount, progress.totalCount)
        let progressValue = progress.totalCount > 0 ? Double(completed) / Double(progress.totalCount) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Observation path")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(completed) of \(progress.totalCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .foregroundStyle(AppTheme.textPrimary)

            ProgressView(value: progressValue)
                .tint(AppTheme.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Observation path progress")
        .accessibilityValue("\(completed) of \(progress.totalCount) observations visited")
    }

    private func openBranchMap(for session: RunSession, node: Node) {
        store.path.append(.branchMap(BranchMapPayload(
            id: "branch-map-\(session.id)",
            sessionID: session.id,
            selectedNodeID: node.id,
            showVisitedOnly: false
        )))
    }

    private func openGlossary(for node: Node) {
        store.path.append(.glossary(GlossaryPayload(
            id: "glossary-\(node.id)",
            category: glossaryCategory(for: node.observationKind),
            highlightedTerm: nil,
            returnToActive: true
        )))
    }

    private func observationIcon(for kind: ObservationKind) -> String {
        switch kind {
        case .visibleCondition:
            return "eye"
        case .steeringFeel:
            return "steeringwheel"
        case .sound:
            return "waveform"
        case .warningIndicator:
            return "exclamationmark.triangle"
        }
    }

    private func glossaryCategory(for kind: ObservationKind) -> GlossaryCategory? {
        switch kind {
        case .visibleCondition, .warningIndicator:
            return .visibleCondition
        case .steeringFeel:
            return .steeringFeel
        case .sound:
            return .sound
        }
    }

    @MainActor
    @Observable
    fileprivate final class ViewModel {
        private let runbooks: any RunbookRepository
        private let traversal: any RunbookTraversing

        init(runbooks: any RunbookRepository, traversal: any RunbookTraversing) {
            self.runbooks = runbooks
            self.traversal = traversal
        }

        func currentNode(for session: RunSession) -> Node? {
            runbooks.nodes(runbookID: session.runbookID)
                .first { $0.id == session.currentNodeID }
        }

        func progress(for session: RunSession) -> BranchProgress {
            traversal.branchProgress(
                session: session,
                nodes: runbooks.nodes(runbookID: session.runbookID)
            )
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let store = CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true)

    if let runbook = dependencies.runbooks.runbook(id: "runbook-01") {
        store.start(runbook: runbook)
    }

    return ActiveStepScreen(dependencies: dependencies)
        .environment(store)
}
