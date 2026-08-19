import Observation
import SwiftUI

struct RunbookDetailScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var model: RunbookDetailViewModel

    init(payload: RunbookDetailPayload, dependencies: AppDependencies = .app()) {
        _model = State(
            initialValue: RunbookDetailViewModel(
                payload: payload,
                repository: dependencies.runbooks,
                traversal: dependencies.traversal
            )
        )
    }

    var body: some View {
        Group {
            if let content = model.content {
                loadedContent(content)
            } else {
                emptyContent
            }
        }
        .background(AppBackground())
        .navigationTitle(model.content?.runbook.title ?? AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let content = model.content {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openDuplicate(for: content)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Duplicate \(content.runbook.title)")
                }
            }
        }
    }

    private func loadedContent(_ content: RunbookDetailViewModel.Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.runbook.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(content.runbook.summary)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 12) {
                        Label("\(content.runbook.durationMinutes) min", systemImage: "clock")
                        Text(riskLabel(for: content.runbook.riskBand))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(riskColor(for: content.runbook.riskBand))
                }

                detailSection(title: "Bring along", systemImage: "bag") {
                    ForEach(content.runbook.supplyNames, id: \.self) { supply in
                        Label(supply, systemImage: "checkmark.circle")
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }

                detailSection(title: "Walk preview", systemImage: "point.topleft.down.to.point.bottomright.curvepath") {
                    Text("\(content.nodes.count) observable checks guide this walk.")
                        .foregroundStyle(AppTheme.textPrimary)

                    if let firstNode = content.nodes.first {
                        Text(firstNode.prompt)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                validationSection(content.validation)

                Button {
                    store.start(runbook: content.runbook)
                } label: {
                    Label("Start walk", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .disabled(!content.validation.isValid)
                .accessibilityLabel("Start \(content.runbook.title) walk")

                Button {
                    openGlossary()
                } label: {
                    Label("Open observation glossary", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("Open observation glossary")
            }
            .padding()
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label("Runbook unavailable", systemImage: "book.closed")
        } description: {
            Text("This runbook is no longer in your local library.")
        } actions: {
            Button("Browse runbooks") {
                store.selectedTab = "Runbooks"
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Browse runbooks")
        }
    }

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16))
    }

    private func validationSection(_ validation: GraphValidation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                validation.isValid ? "Walk ready" : "Walk needs attention",
                systemImage: validation.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
            )
            .font(.headline)
            .foregroundStyle(validation.isValid ? AppTheme.accent : AppTheme.danger)

            Text("\(validation.reachableNodeCount) checks are reachable from the starting point.")
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(validation.issues, id: \.self) { issue in
                Text(issue)
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16))
    }

    private func openDuplicate(for content: RunbookDetailViewModel.Content) {
        store.path.append(
            .duplicateTitle(
                DuplicatePayload(
                    id: "duplicate-\(content.runbook.id)",
                    sourceRunbookID: content.runbook.id,
                    suggestedTitle: "\(content.runbook.title) copy",
                    copiedNodeCount: content.nodes.count
                )
            )
        )
    }

    private func openGlossary() {
        store.path.append(
            .glossary(
                GlossaryPayload(
                    id: "glossary-\(model.payload.runbookID)",
                    category: nil,
                    highlightedTerm: nil,
                    returnToActive: false
                )
            )
        )
    }

    private func riskLabel(for riskBand: RiskBand) -> String {
        switch riskBand {
        case .routine:
            return "Routine"
        case .caution:
            return "Caution"
        case .stop:
            return "Stop"
        }
    }

    private func riskColor(for riskBand: RiskBand) -> Color {
        switch riskBand {
        case .routine, .caution:
            return AppTheme.accent
        case .stop:
            return AppTheme.danger
        }
    }
}

@MainActor
@Observable
private final class RunbookDetailViewModel {
    struct Content {
        let runbook: Runbook
        let nodes: [Node]
        let validation: GraphValidation
    }

    let payload: RunbookDetailPayload
    let content: Content?

    init(
        payload: RunbookDetailPayload,
        repository: any RunbookRepository,
        traversal: any RunbookTraversing
    ) {
        self.payload = payload
        guard let runbook = repository.runbook(id: payload.runbookID) else {
            content = nil
            return
        }
        let nodes = repository.nodes(runbookID: runbook.id)
        content = Content(
            runbook: runbook,
            nodes: nodes,
            validation: traversal.validateGraph(runbook: runbook, nodes: nodes)
        )
    }
}

#Preview {
    NavigationStack {
        RunbookDetailScreen(
            payload: RunbookDetailPayload(
                id: "preview-runbook-detail",
                runbookID: "runbook-01",
                origin: .catalog,
                focusNodeID: nil
            ),
            dependencies: .preview()
        )
    }
    .environment(CurbSenseStore(dependencies: .preview(), hasCompletedOnboarding: true))
}
