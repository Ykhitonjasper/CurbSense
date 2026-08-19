import Observation
import SwiftUI

struct RunHistoryScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(
            sessions: dependencies.sessions,
            runbooks: dependencies.runbooks
        ))
    }

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loaded(let sessions):
                loadedContent(sessions)
            case .empty:
                emptyContent
            }
        }
        .background(AppBackground())
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.openedSessionID)
    }

    private func loadedContent(_ sessions: [ViewModel.HistorySession]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Completed checks")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Review the observation paths you saved on this device.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Completed checks. Review the observation paths you saved on this device.")

            Text("\(sessions.count) saved \(sessions.count == 1 ? "check" : "checks")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            LazyVStack(spacing: 12) {
                ForEach(sessions) { session in
                    historyCard(session)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func historyCard(_ history: ViewModel.HistorySession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(history.runbookTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(history.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Label(history.ending.title, systemImage: history.ending.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(history.ending.tint)
                    .multilineTextAlignment(.trailing)
            }

            Text(history.ending.detail)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    openHistoryDetail(for: history)
                } label: {
                    Label("View path", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("View path for \(history.runbookTitle)")
                .accessibilityHint("Opens the recorded observation choices")

                Button {
                    openVerdict(for: history)
                } label: {
                    Label("View result", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .accessibilityLabel("View result for \(history.runbookTitle)")
                .accessibilityHint("Opens the ending reason and next steps")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("No completed checks", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Start a runbook to save its observation path and result here.")
        } actions: {
            Button("Browse runbooks") {
                store.selectedTab = "Runbooks"
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Browse runbooks")
            .accessibilityHint("Opens the runbook catalog")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(24)
    }

    private func openHistoryDetail(for history: ViewModel.HistorySession) {
        store.path.append(.historyDetail(HistoryDetailPayload(
            id: "history-\(history.session.id)",
            sessionID: history.session.id,
            runbookID: history.session.runbookID,
            highlightedChoiceID: history.session.selectedChoiceIDs.last,
            showTimeline: true
        )))
        viewModel.openedSessionID = history.session.id
    }

    private func openVerdict(for history: ViewModel.HistorySession) {
        store.path.append(.verdict(VerdictPayload(
            id: "verdict-\(history.session.id)",
            sessionID: history.session.id,
            endingClass: history.endingClass,
            actionPackID: history.actionPackID
        )))
        viewModel.openedSessionID = history.session.id
    }

    @MainActor
    @Observable
    fileprivate final class ViewModel {
        enum State {
            case loaded([HistorySession])
            case empty
        }

        struct HistorySession: Identifiable {
            struct Ending {
                let title: String
                let detail: String
                let icon: String
                let tint: Color
            }

            let session: RunSession
            let runbookTitle: String
            let completedAt: Date
            let endingClass: EndingClass
            let actionPackID: String
            let ending: Ending

            var id: String { session.id }
        }

        private let sessions: any RunSessionRepository
        private let runbooks: any RunbookRepository

        var state: State = .empty
        var openedSessionID: String?

        init(
            sessions: any RunSessionRepository,
            runbooks: any RunbookRepository
        ) {
            self.sessions = sessions
            self.runbooks = runbooks
        }

        func load() {
            let completedSessions = sessions.allSessions().compactMap { session -> HistorySession? in
                guard session.status == .completed,
                      let completedAt = session.completedAt,
                      let endingClass = session.endingClass,
                      let actionPackID = session.actionPackID,
                      !actionPackID.isEmpty,
                      let runbook = runbooks.runbook(id: session.runbookID) else {
                    return nil
                }

                return HistorySession(
                    session: session,
                    runbookTitle: runbook.title,
                    completedAt: completedAt,
                    endingClass: endingClass,
                    actionPackID: actionPackID,
                    ending: ending(for: endingClass)
                )
            }
            .sorted { $0.completedAt > $1.completedAt }

            state = completedSessions.isEmpty ? .empty : .loaded(completedSessions)
        }

        private func ending(for endingClass: EndingClass) -> HistorySession.Ending {
            switch endingClass {
            case .safeActionComplete:
                HistorySession.Ending(
                    title: "Checks complete",
                    detail: "Visible observations supported a cautious next departure.",
                    icon: "checkmark.circle.fill",
                    tint: AppTheme.accent
                )
            case .stopAndWaitSafely:
                HistorySession.Ending(
                    title: "Wait before departure",
                    detail: "The recorded condition called for a safe pause.",
                    icon: "pause.circle.fill",
                    tint: AppTheme.danger
                )
            case .contactTrustedSupport:
                HistorySession.Ending(
                    title: "Seek trusted support",
                    detail: "The recorded condition called for support before further action.",
                    icon: "person.crop.circle.badge.exclamationmark",
                    tint: AppTheme.danger
                )
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()

    NavigationStack {
        RunHistoryScreen(dependencies: dependencies)
    }
    .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
