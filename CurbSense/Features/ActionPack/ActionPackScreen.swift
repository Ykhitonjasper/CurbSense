import Observation
import SwiftUI

struct ActionPackScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ViewModel

    init(payload: ActionPackPayload, dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(
            payload: payload,
            actionPacks: dependencies.actionPacks,
            sessions: dependencies.sessions,
            runbooks: dependencies.runbooks,
            formatter: dependencies.formatter
        ))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loaded(let content):
                loadedContent(content)
            case .empty:
                emptyContent
            }
        }
        .background(AppTheme.bgBase)
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back to verdict", systemImage: "chevron.backward")
                }
                .accessibilityLabel("Back to verdict")
            }
        }
        .onAppear {
            viewModel.load()
        }
    }

    private func loadedContent(_ content: ViewModel.Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Your next steps", systemImage: "checklist")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text(content.actionPack.headline)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(content.runbook.title)
                        .font(.subheadline)
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
                .accessibilityLabel("Next steps for \(content.runbook.title). \(content.actionPack.headline)")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Follow in order")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(Array(content.actionPack.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.bgBase)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.accent, in: Circle())
                                .accessibilityHidden(true)

                            Text(step)
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Step \(index + 1). \(step)")
                    }
                }

                if viewModel.permitsSharing {
                    ShareLink(
                        item: content.shareText,
                        subject: Text(content.actionPack.headline),
                        message: Text("Next steps from \(AppTheme.displayName)")
                    ) {
                        Label("Share next steps", systemImage: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .accessibilityLabel("Share next steps")
                    .accessibilityHint("Opens the system share sheet with this action pack")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Back to verdict", systemImage: "arrow.backward")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("Back to verdict")
                .accessibilityHint("Returns to the verdict for this check")
            }
            .padding(20)
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("Action pack unavailable", systemImage: "checklist")
        } description: {
            Text("This saved action pack is no longer available.")
        } actions: {
            Button("Back to verdict") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Back to verdict")
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(24)
    }
}

extension ActionPackScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded(Content)
            case empty
        }

        struct Content {
            let actionPack: ActionPack
            let runbook: Runbook
            let shareText: String
        }

        private let payload: ActionPackPayload
        private let actionPacks: any ActionPackRepository
        private let sessions: any RunSessionRepository
        private let runbooks: any RunbookRepository
        private let formatter: any ActionPackFormatting

        var state: State = .empty

        var permitsSharing: Bool {
            payload.permitsSharing
        }

        init(
            payload: ActionPackPayload,
            actionPacks: any ActionPackRepository,
            sessions: any RunSessionRepository,
            runbooks: any RunbookRepository,
            formatter: any ActionPackFormatting
        ) {
            self.payload = payload
            self.actionPacks = actionPacks
            self.sessions = sessions
            self.runbooks = runbooks
            self.formatter = formatter
        }

        func load() {
            guard let actionPack = actionPacks.actionPack(id: payload.actionPackID),
                  actionPack.sessionID == payload.sessionID,
                  let session = sessions.allSessions().first(where: { $0.id == payload.sessionID }),
                  let runbook = runbooks.runbook(id: session.runbookID) else {
                state = .empty
                return
            }

            state = .loaded(Content(
                actionPack: actionPack,
                runbook: runbook,
                shareText: formatter.plainText(
                    actionPack: actionPack,
                    session: session,
                    runbook: runbook
                )
            ))
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let store = CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true)
    let payload = ActionPackPayload(
        id: "preview-action-pack",
        actionPackID: "action-001",
        sessionID: "session-001",
        permitsSharing: true
    )

    return NavigationStack {
        ActionPackScreen(payload: payload, dependencies: dependencies)
    }
    .environment(store)
}
