import Observation
import SwiftUI

struct VerdictScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    private let payload: VerdictPayload

    init(dependencies: AppDependencies, payload: VerdictPayload) {
        self.payload = payload
        _viewModel = State(initialValue: ViewModel(
            runbooks: dependencies.runbooks,
            sessions: dependencies.sessions,
            actionPacks: dependencies.actionPacks
        ))
    }

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loaded(let verdict):
                loadedContent(verdict)
            case .empty:
                emptyContent
            }
        }
        .background(AppTheme.bgBase)
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(payload: payload)
        }
        .sensoryFeedback(.success, trigger: viewModel.openedActionPackID)
        .sensoryFeedback(.selection, trigger: viewModel.didOpenHistory)
    }

    private func loadedContent(_ verdict: ViewModel.Verdict) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(verdict.ending.title, systemImage: verdict.ending.icon)
                    .font(.headline)
                    .foregroundStyle(verdict.ending.tint)

                Text(verdict.ending.message)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(verdict.ending.guidance)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(verdict.ending.title). \(verdict.ending.message). \(verdict.ending.guidance)")

            VStack(alignment: .leading, spacing: 10) {
                Text("Why this path ended")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(verdict.reason)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Why this path ended. \(verdict.reason)")

            VStack(alignment: .leading, spacing: 12) {
                Text("Next step")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(verdict.actionPack.headline)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 4)

            Button {
                openActionPack(verdict)
            } label: {
                Label("View next steps", systemImage: "checklist")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("View next steps")
            .accessibilityHint("Opens the action pack for this completed check")

            Button {
                openHistory()
            } label: {
                Label("View in History", systemImage: "clock.arrow.circlepath")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.accent)
            .accessibilityLabel("View in History")
            .accessibilityHint("Selects the History tab and retains this completed check")
        }
        .padding(20)
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("No completed result", systemImage: "checkmark.circle")
        } description: {
            Text("Complete a guided observation path to review its ending and next steps.")
        } actions: {
            Button("Browse runbooks") {
                store.path.removeAll()
                store.selectedTab = "runbooks"
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Browse runbooks")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(24)
    }

    private func openActionPack(_ verdict: ViewModel.Verdict) {
        store.path.append(.actionPack(ActionPackPayload(
            id: "action-pack-\(verdict.actionPack.id)",
            actionPackID: verdict.actionPack.id,
            sessionID: verdict.session.id,
            permitsSharing: true
        )))
        viewModel.openedActionPackID = verdict.actionPack.id
    }

    private func openHistory() {
        store.path.removeAll()
        store.selectedTab = "history"
        viewModel.didOpenHistory.toggle()
    }

    @MainActor
    @Observable
    fileprivate final class ViewModel {
        enum State {
            case loaded(Verdict)
            case empty
        }

        struct Verdict {
            let session: RunSession
            let actionPack: ActionPack
            let ending: Ending
            let reason: String
        }

        struct Ending {
            let title: String
            let message: String
            let guidance: String
            let icon: String
            let tint: Color
        }

        private let runbooks: any RunbookRepository
        private let sessions: any RunSessionRepository
        private let actionPacks: any ActionPackRepository

        var state: State = .empty
        var openedActionPackID: String?
        var didOpenHistory = false

        init(
            runbooks: any RunbookRepository,
            sessions: any RunSessionRepository,
            actionPacks: any ActionPackRepository
        ) {
            self.runbooks = runbooks
            self.sessions = sessions
            self.actionPacks = actionPacks
        }

        func load(payload: VerdictPayload) {
            guard let session = sessions.allSessions().first(where: { $0.id == payload.sessionID }),
                  session.status == .completed,
                  session.endingClass == payload.endingClass,
                  session.actionPackID == payload.actionPackID,
                  let actionPack = actionPacks.actionPack(id: payload.actionPackID),
                  actionPack.sessionID == session.id else {
                state = .empty
                return
            }

            let reason = runbooks.nodes(runbookID: session.runbookID)
                .first(where: { $0.id == session.currentNodeID })?
                .prompt ?? "This completed path retained the observations that led to its final recommendation."

            state = .loaded(Verdict(
                session: session,
                actionPack: actionPack,
                ending: ending(for: payload.endingClass),
                reason: reason
            ))
        }

        private func ending(for endingClass: EndingClass) -> Ending {
            switch endingClass {
            case .safeActionComplete:
                Ending(
                    title: "Observation walk completed",
                    message: "Completion records observations only and does not determine roadworthiness.",
                    guidance: "Pause and seek qualified local review if the condition changes.",
                    icon: "checkmark.circle.fill",
                    tint: AppTheme.accent
                )
            case .stopAndWaitSafely:
                Ending(
                    title: "Wait before departure",
                    message: "The recorded condition needs a safe pause before the vehicle is used.",
                    guidance: "Keep the vehicle parked safely and arrange a suitable local review.",
                    icon: "pause.circle.fill",
                    tint: AppTheme.danger
                )
            case .contactTrustedSupport:
                Ending(
                    title: "Seek trusted support",
                    message: "The recorded condition calls for support before any further action.",
                    guidance: "Keep clear of the affected area and contact a trusted person or suitable local service.",
                    icon: "person.crop.circle.badge.exclamationmark",
                    tint: AppTheme.danger
                )
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let payload = VerdictPayload(
        id: "verdict-session-002",
        sessionID: "session-002",
        endingClass: .stopAndWaitSafely,
        actionPackID: "action-002"
    )

    return NavigationStack {
        VerdictScreen(dependencies: dependencies, payload: payload)
    }
    .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
