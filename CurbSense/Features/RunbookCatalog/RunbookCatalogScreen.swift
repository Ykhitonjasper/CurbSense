import Observation
import SwiftUI

struct RunbookCatalogScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(
        runbooks: any RunbookRepository,
        recoveryCards: any RecoveryCardRepository
    ) {
        _viewModel = State(
            initialValue: ViewModel(
                runbooks: runbooks,
                recoveryCards: recoveryCards
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                filters(viewModel: $viewModel)

                switch viewModel.state {
                case .loaded(let runbooks):
                    if runbooks.isEmpty {
                        emptyState
                    } else {
                        catalog(runbooks)
                    }
                case .empty:
                    emptyState
                }

                recoveryLibrary(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppBackground())
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.filterSignature)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.openedRecoveryID)
        .sensoryFeedback(.success, trigger: viewModel.openedRunbookID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vehicle condition runbooks")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Choose a focused observation path before deciding what to do next.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func filters(viewModel: Bindable<ViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter runbooks")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Picker("Risk filter", selection: viewModel.riskFilter) {
                ForEach(ViewModel.RiskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Filter runbooks by risk")

            Picker("Duration filter", selection: viewModel.durationFilter) {
                ForEach(ViewModel.DurationFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Filter runbooks by duration")
        }
        .padding(16)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func catalog(_ runbooks: [Runbook]) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("\(runbooks.count) available")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(runbooks) { runbook in
                Button {
                    open(runbook)
                } label: {
                    runbookCard(runbook)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(runbook.title)")
                .accessibilityHint("Opens this runbook's details")
            }
        }
    }

    private func runbookCard(_ runbook: Runbook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(runbook.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(runbook.summary)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                label(riskTitle(for: runbook.riskBand), icon: riskSymbol(for: runbook.riskBand))
                label("\(runbook.durationMinutes) min", icon: "clock")
                if !runbook.isSeeded {
                    label("Copied", icon: "doc.on.doc")
                }
            }

            if !runbook.supplyNames.isEmpty {
                Text("Bring: \(runbook.supplyNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private func label(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.bgBase, in: Capsule())
    }

    private func riskTitle(for band: RiskBand) -> String {
        switch band {
        case .routine: "Routine"
        case .caution: "Caution"
        case .stop: "Stop"
        }
    }

    private func riskSymbol(for band: RiskBand) -> String {
        switch band {
        case .routine: "checkmark.circle"
        case .caution: "exclamationmark.triangle"
        case .stop: "hand.raised"
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No matching runbooks", systemImage: "books.vertical")
        } description: {
            Text("Change the filters to see another observation path.")
        } actions: {
            Button("Show all runbooks") {
                viewModel.clearFilters()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Show all runbooks")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func recoveryLibrary(viewModel: ViewModel) -> some View {
        Button {
            openRecovery()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preparation library")
                            .font(.headline)
                        Text("\(viewModel.recoveryCards.count) practical cards for a safer pause.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .accessibilityHidden(true)
                }

                if let card = viewModel.recoveryCards.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.subheadline.weight(.semibold))
                        Text(card.preparation)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.bgBase, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(16)
            .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open preparation library")
        .accessibilityHint("Shows all preparation cards")
    }

    private func openRecovery() {
        let highlightedCardID = viewModel.recoveryCards.first?.id
        viewModel.openedRecoveryID = highlightedCardID ?? "recovery-library"
        store.path.append(
            .recoveryLibrary(
                RecoveryLibraryPayload(
                    id: "catalog-recovery-library",
                    origin: .catalog,
                    highlightedCardID: highlightedCardID,
                    showPreparationFirst: true
                )
            )
        )
    }

    private func open(_ runbook: Runbook) {
        viewModel.openedRunbookID = runbook.id
        store.path.append(
            .runbookDetail(
                RunbookDetailPayload(
                    id: "catalog-\(runbook.id)",
                    runbookID: runbook.id,
                    origin: .catalog,
                    focusNodeID: nil
                )
            )
        )
    }
}

extension RunbookCatalogScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded([Runbook])
            case empty
        }

        enum RiskFilter: String, CaseIterable, Identifiable {
            case all
            case routine
            case caution
            case stop

            var id: String { rawValue }

            var title: String {
                switch self {
                case .all: "All"
                case .routine: "Routine"
                case .caution: "Caution"
                case .stop: "Stop"
                }
            }
        }

        enum DurationFilter: String, CaseIterable, Identifiable {
            case all
            case quick
            case thorough

            var id: String { rawValue }

            var title: String {
                switch self {
                case .all: "Any time"
                case .quick: "5–6 min"
                case .thorough: "7+ min"
                }
            }
        }

        private let runbooks: any RunbookRepository
        private let recoveryRepository: any RecoveryCardRepository
        private var allRunbooks: [Runbook] = []

        var state: State = .empty
        var riskFilter: RiskFilter = .all {
            didSet { applyFilters() }
        }
        var durationFilter: DurationFilter = .all {
            didSet { applyFilters() }
        }
        var recoveryCards: [RecoveryCard] = []
        var openedRunbookID: String?
        var openedRecoveryID: String?

        var filterSignature: String {
            "\(riskFilter.rawValue)-\(durationFilter.rawValue)"
        }

        init(
            runbooks: any RunbookRepository,
            recoveryCards: any RecoveryCardRepository
        ) {
            self.runbooks = runbooks
            self.recoveryRepository = recoveryCards
        }

        func load() {
            allRunbooks = runbooks.allRunbooks()
            recoveryCards = recoveryRepository.recoveryCards()
            applyFilters()
        }

        func clearFilters() {
            riskFilter = .all
            durationFilter = .all
        }

        private func applyFilters() {
            let matching = allRunbooks.filter { runbook in
                matchesRisk(runbook) && matchesDuration(runbook)
            }
            state = matching.isEmpty ? .empty : .loaded(matching)
        }

        private func matchesRisk(_ runbook: Runbook) -> Bool {
            switch riskFilter {
            case .all:
                true
            case .routine:
                runbook.riskBand == .routine
            case .caution:
                runbook.riskBand == .caution
            case .stop:
                runbook.riskBand == .stop
            }
        }

        private func matchesDuration(_ runbook: Runbook) -> Bool {
            switch durationFilter {
            case .all:
                true
            case .quick:
                runbook.durationMinutes <= 6
            case .thorough:
                runbook.durationMinutes >= 7
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RunbookCatalogScreen(
        runbooks: dependencies.runbooks,
        recoveryCards: dependencies.recoveryCards
    )
    .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
