import Observation
import SwiftUI

struct HistoryDetailScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(payload: HistoryDetailPayload, dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(
            payload: payload,
            sessions: dependencies.sessions,
            runbooks: dependencies.runbooks,
            actionPacks: dependencies.actionPacks
        ))
    }

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loaded(let detail):
                loadedContent(detail)
            case .empty:
                emptyContent
            }
        }
        .background(AppTheme.bgBase)
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.highlightedNodeID)
        .sensoryFeedback(.success, trigger: viewModel.openedActionPackID)
    }

    private func loadedContent(_ detail: ViewModel.Detail) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Completed path", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)

                Text(detail.runbookTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(detail.pathDescription)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Completed path for \(detail.runbookTitle). \(detail.entries.count) observations recorded.")

            VStack(alignment: .leading, spacing: 12) {
                Text(detail.pathTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(detail.entries) { entry in
                    Button {
                        viewModel.highlight(entry)
                    } label: {
                        pathEntry(entry, isHighlighted: viewModel.highlightedNodeID == entry.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: entry))
                    .accessibilityHint("Shows the observation and selected condition together")
                }
            }

            if let actionPack = detail.actionPack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saved next steps")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(actionPack.headline)
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                }

                Button {
                    openActionPack(actionPack, sessionID: detail.sessionID)
                } label: {
                    Label("Open saved next steps", systemImage: "checklist")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .accessibilityLabel("Open saved next steps")
                .accessibilityHint("Opens the retained action pack for this completed path")
            }
        }
        .padding(20)
    }

    private func pathEntry(_ entry: ViewModel.PathEntry, isHighlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Observation \(entry.sequenceIndex)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isHighlighted ? AppTheme.accent : AppTheme.textSecondary)
                Spacer()
                Image(systemName: isHighlighted ? "eye.fill" : "chevron.right")
                    .foregroundStyle(isHighlighted ? AppTheme.accent : AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }

            Text(entry.prompt)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.choiceTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(entry.choiceLabel)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isHighlighted ? AppTheme.accent : AppTheme.hairline, lineWidth: isHighlighted ? 2 : 1)
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("Path unavailable", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("This completed path is no longer stored in History.")
        } actions: {
            Button("Back to History") {
                store.selectedTab = "history"
                if !store.path.isEmpty {
                    store.path.removeLast()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Back to History")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(24)
    }

    private func accessibilityLabel(for entry: ViewModel.PathEntry) -> String {
        "Observation \(entry.sequenceIndex). \(entry.prompt) \(entry.choiceTitle): \(entry.choiceLabel)"
    }

    private func openActionPack(_ actionPack: ActionPack, sessionID: String) {
        store.path.append(.actionPack(ActionPackPayload(
            id: "history-action-pack-\(actionPack.id)",
            actionPackID: actionPack.id,
            sessionID: sessionID,
            permitsSharing: true
        )))
        viewModel.openedActionPackID = actionPack.id
    }
}

extension HistoryDetailScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded(Detail)
            case empty
        }

        struct Detail {
            let sessionID: String
            let runbookTitle: String
            let entries: [PathEntry]
            let actionPack: ActionPack?
            let pathTitle: String
            let pathDescription: String
        }

        struct PathEntry: Identifiable {
            let id: String
            let sequenceIndex: Int
            let prompt: String
            let choiceTitle: String
            let choiceLabel: String
        }

        private let payload: HistoryDetailPayload
        private let sessions: any RunSessionRepository
        private let runbooks: any RunbookRepository
        private let actionPacks: any ActionPackRepository

        var state: State = .empty
        var highlightedNodeID: String?
        var openedActionPackID: String?

        init(
            payload: HistoryDetailPayload,
            sessions: any RunSessionRepository,
            runbooks: any RunbookRepository,
            actionPacks: any ActionPackRepository
        ) {
            self.payload = payload
            self.sessions = sessions
            self.runbooks = runbooks
            self.actionPacks = actionPacks
        }

        func load() {
            guard let session = sessions.allSessions().first(where: { $0.id == payload.sessionID }),
                  session.status == .completed,
                  session.runbookID == payload.runbookID,
                  let runbook = runbooks.runbook(id: payload.runbookID) else {
                state = .empty
                return
            }

            let nodesByID = Dictionary(
                uniqueKeysWithValues: runbooks.nodes(runbookID: payload.runbookID).map { ($0.id, $0) }
            )
            let entries = session.visitedNodeIDs.enumerated().compactMap { index, nodeID -> PathEntry? in
                guard let node = nodesByID[nodeID] else {
                    return nil
                }
                let choiceID = session.selectedChoiceIDs.indices.contains(index)
                    ? session.selectedChoiceIDs[index]
                    : nil
                let choiceIndex = choiceID.flatMap { node.choiceIDs.firstIndex(of: $0) }
                let choiceLabel = choiceIndex.flatMap { index in
                    node.choiceLabels.indices.contains(index) ? node.choiceLabels[index] : nil
                }
                return PathEntry(
                    id: node.id,
                    sequenceIndex: node.sequenceIndex,
                    prompt: node.prompt,
                    choiceTitle: choiceIndex == nil ? "Path result" : "Selected condition",
                    choiceLabel: choiceLabel ?? endingLabel(for: node.endingClass)
                )
            }

            guard entries.count == session.visitedNodeIDs.count else {
                state = .empty
                return
            }

            let actionPack = session.actionPackID
                .flatMap { actionPacks.actionPack(id: $0) }
                .flatMap { $0.sessionID == session.id ? $0 : nil }
            highlightedNodeID = entryID(for: payload.highlightedChoiceID, entries: entries) ?? entries.first?.id
            state = .loaded(Detail(
                sessionID: session.id,
                runbookTitle: runbook.title,
                entries: entries,
                actionPack: actionPack,
                pathTitle: payload.showTimeline ? "Ordered timeline" : "Recorded choices",
                pathDescription: payload.showTimeline
                    ? "Review each observation and the condition selected at that point."
                    : "Review the observations and conditions retained for this completed path."
            ))
        }

        func highlight(_ entry: PathEntry) {
            highlightedNodeID = entry.id
        }

        private func entryID(for choiceID: String?, entries: [PathEntry]) -> String? {
            guard let choiceID,
                  let session = sessions.allSessions().first(where: { $0.id == payload.sessionID }),
                  let index = session.selectedChoiceIDs.firstIndex(of: choiceID) else {
                return nil
            }
            return entries.indices.contains(index) ? entries[index].id : nil
        }

        private func endingLabel(for endingClass: EndingClass?) -> String {
            switch endingClass {
            case .safeActionComplete:
                "Visible checks completed"
            case .stopAndWaitSafely:
                "Departure should wait"
            case .contactTrustedSupport:
                "Trusted support is the next step"
            case nil:
                "Recorded observation"
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let store = CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true)
    let payload = HistoryDetailPayload(
        id: "history-detail-session-002",
        sessionID: "session-002",
        runbookID: "runbook-02",
        highlightedChoiceID: "uneven-2",
        showTimeline: true
    )

    return NavigationStack {
        HistoryDetailScreen(payload: payload, dependencies: dependencies)
    }
    .environment(store)
}
