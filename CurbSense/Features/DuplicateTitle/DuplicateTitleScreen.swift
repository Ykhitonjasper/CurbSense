import Foundation
import Observation
import SwiftUI

struct DuplicateTitleScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(payload: DuplicatePayload, dependencies: AppDependencies) {
        _viewModel = State(initialValue: ViewModel(payload: payload, runbooks: dependencies.runbooks))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.state {
                    case .loaded(let content):
                        loadedContent(content)
                    case .unavailable:
                        unavailableContent
                    }
                }
                .padding(20)
            }
            .background(AppTheme.bgBase)
            .navigationTitle("Copy runbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel copying runbook")
                    .accessibilityHint("Returns to the source runbook without saving a copy")
                }
            }
        }
        .sensoryFeedback(.error, trigger: viewModel.validationMessage)
        .sensoryFeedback(.success, trigger: viewModel.createdRunbookID)
    }

    private func loadedContent(_ content: ViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Copying from \(content.source.title)", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)

                Text("Keep the familiar observation path and give this local copy a title that makes its purpose clear.")
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Copying \(content.source.title), including \(content.nodeCount) observation steps")

            VStack(alignment: .leading, spacing: 8) {
                Text("New title")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                TextField("Runbook title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("New runbook title")
                    .accessibilityHint("Enter a unique title for this copied runbook")

                Text("The source runbook remains unchanged.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                if let validationMessage = viewModel.validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                        .accessibilityLabel(validationMessage)
                }
            }
            .padding(16)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            }

            Label("\(content.nodeCount) observation steps will be copied", systemImage: "list.number")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel("\(content.nodeCount) observation steps will be copied")

            Button {
                saveAndStart()
            } label: {
                Label("Copy and start", systemImage: "play.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(!viewModel.canSave)
            .accessibilityLabel("Copy and start runbook")
            .accessibilityHint("Saves the copied runbook and opens its first observation")
        }
    }

    private var unavailableContent: some View {
        ContentUnavailableView {
            Label("Runbook unavailable", systemImage: "doc.on.doc")
        } description: {
            Text("This source runbook is no longer available to copy.")
        } actions: {
            Button("Return to runbook") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Return to runbook")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func saveAndStart() {
        guard let copiedRunbook = viewModel.saveDuplicate() else { return }
        store.start(runbook: copiedRunbook)
        dismiss()
    }
}

extension DuplicateTitleScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded(Content)
            case unavailable
        }

        struct Content {
            let source: Runbook
            let nodeCount: Int
        }

        private let payload: DuplicatePayload
        private let runbooks: any RunbookRepository

        var title: String
        var validationMessage: String?
        var createdRunbookID: String?
        var state: State

        var canSave: Bool {
            titleError == nil
        }

        init(payload: DuplicatePayload, runbooks: any RunbookRepository) {
            self.payload = payload
            self.runbooks = runbooks
            self.title = payload.suggestedTitle
            self.validationMessage = nil
            self.createdRunbookID = nil

            guard let source = runbooks.runbook(id: payload.sourceRunbookID),
                  source.isSeeded,
                  runbooks.nodes(runbookID: source.id).count == payload.copiedNodeCount else {
                self.state = .unavailable
                return
            }

            self.state = .loaded(Content(source: source, nodeCount: payload.copiedNodeCount))
        }

        func saveDuplicate() -> Runbook? {
            guard let titleError else {
                let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let copiedRunbook = runbooks.duplicateRunbook(
                    sourceID: payload.sourceRunbookID,
                    title: normalizedTitle
                ) else {
                    validationMessage = "The runbook could not be copied."
                    return nil
                }
                createdRunbookID = copiedRunbook.id
                validationMessage = nil
                return copiedRunbook
            }

            validationMessage = titleError
            return nil
        }

        private var titleError: String? {
            let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedTitle.isEmpty else {
                return "Enter a title for the copied runbook."
            }

            let normalizedExistingTitles = Set(
                runbooks.allRunbooks().map {
                    $0.title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(normalizedTitle) == .orderedSame
                }
            )
            guard !normalizedExistingTitles.contains(true) else {
                return "Choose a title that is different from an existing runbook."
            }

            return nil
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let store = CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true)
    let payload = DuplicatePayload(
        id: "duplicate-runbook-01",
        sourceRunbookID: "runbook-01",
        suggestedTitle: "Curb Strike Check — Winter Wheels",
        copiedNodeCount: 8
    )

    return DuplicateTitleScreen(payload: payload, dependencies: dependencies)
        .environment(store)
}
