import Observation
import SwiftUI

struct RecoveryLibraryScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(recoveryCards: any RecoveryCardRepository, payload: RecoveryLibraryPayload) {
        _viewModel = State(initialValue: ViewModel(recoveryCards: recoveryCards, payload: payload))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    filters(viewModel: $viewModel)

                    switch viewModel.state {
                    case .loaded(let cards):
                        if cards.isEmpty {
                            emptyState
                        } else {
                            cardList(cards, viewModel: viewModel)
                        }
                    case .empty:
                        emptyState
                    }
                }
                .padding(20)
            }
            .onChange(of: viewModel.scrollTargetID) { _, cardID in
                guard let cardID else { return }
                withAnimation {
                    proxy.scrollTo(cardID, anchor: .top)
                }
            }
        }
        .background(AppBackground())
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.filterSignature)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.expandedCardID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preparation library")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Keep practical supplies, notes, and pause plans ready before the next drive.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func filters(viewModel: Bindable<ViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter preparation cards")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Picker("Observation filter", selection: viewModel.filter) {
                ForEach(ViewModel.Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.accent)
            .accessibilityLabel("Filter preparation cards by observation")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private func cardList(_ cards: [RecoveryCard], viewModel: ViewModel) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("\(cards.count) preparation \(cards.count == 1 ? "card" : "cards")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(cards) { card in
                cardView(card, isExpanded: viewModel.expandedCardID == card.id)
                    .id(card.id)
            }
        }
    }

    private func cardView(_ card: RecoveryCard, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.select(card)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: card.trigger))
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(card.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(triggerTitle(for: card.trigger))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(isExpanded ? "Hide" : "Show") preparation for \(card.title)")
            .accessibilityHint(isExpanded ? "Hides the preparation note" : "Shows the full preparation note")

            if isExpanded {
                Text(card.preparation)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    openGlossary(for: card)
                } label: {
                    Label("Learn about \(triggerTitle(for: card.trigger))", systemImage: "book.closed")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("Open glossary for \(triggerTitle(for: card.trigger))")
                .accessibilityHint("Shows related observation terms")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No preparation cards", systemImage: "checklist")
        } description: {
            Text("Choose another observation filter to see available preparation.")
        } actions: {
            Button("Show every card") {
                viewModel.clearFilter()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Show every preparation card")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func openGlossary(for card: RecoveryCard) {
        store.path.append(
            .glossary(
                GlossaryPayload(
                    id: "recovery-glossary-\(card.id)",
                    category: glossaryCategory(for: card.trigger),
                    highlightedTerm: nil,
                    returnToActive: false
                )
            )
        )
    }

    private func glossaryCategory(for trigger: ObservationKind) -> GlossaryCategory {
        switch trigger {
        case .visibleCondition, .warningIndicator:
            return .visibleCondition
        case .steeringFeel:
            return .steeringFeel
        case .sound:
            return .sound
        }
    }

    private func icon(for trigger: ObservationKind) -> String {
        switch trigger {
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

    private func triggerTitle(for trigger: ObservationKind) -> String {
        switch trigger {
        case .visibleCondition:
            return "Visible condition"
        case .steeringFeel:
            return "Steering feel"
        case .sound:
            return "Sound"
        case .warningIndicator:
            return "Warning indicator"
        }
    }
}

extension RecoveryLibraryScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded([RecoveryCard])
            case empty
        }

        enum Filter: String, CaseIterable, Identifiable {
            case all
            case visibleCondition
            case steeringFeel
            case sound
            case warningIndicator

            var id: String { rawValue }

            var title: String {
                switch self {
                case .all:
                    return "All topics"
                case .visibleCondition:
                    return "Visible condition"
                case .steeringFeel:
                    return "Steering feel"
                case .sound:
                    return "Sound"
                case .warningIndicator:
                    return "Warning indicator"
                }
            }
        }

        private let recoveryCards: any RecoveryCardRepository
        private let payload: RecoveryLibraryPayload
        private var allCards: [RecoveryCard] = []
        private var hasLoaded = false

        var state: State = .empty
        var filter: Filter = .all {
            didSet { applyFilter() }
        }
        var expandedCardID: String?
        var scrollTargetID: String?

        var filterSignature: String {
            filter.rawValue
        }

        init(recoveryCards: any RecoveryCardRepository, payload: RecoveryLibraryPayload) {
            self.recoveryCards = recoveryCards
            self.payload = payload
        }

        func load() {
            guard !hasLoaded else { return }
            hasLoaded = true
            allCards = recoveryCards.recoveryCards()
            applyFilter()

            if let card = highlightedCard() {
                expandedCardID = card.id
                scrollTargetID = card.id
            } else if payload.showPreparationFirst, let firstCard = allCards.first {
                expandedCardID = firstCard.id
                scrollTargetID = firstCard.id
            }
        }

        func clearFilter() {
            filter = .all
        }

        func select(_ card: RecoveryCard) {
            expandedCardID = expandedCardID == card.id ? nil : card.id
        }

        private func applyFilter() {
            let matchingCards = allCards.filter { card in
                switch filter {
                case .all:
                    return true
                case .visibleCondition:
                    return card.trigger == .visibleCondition
                case .steeringFeel:
                    return card.trigger == .steeringFeel
                case .sound:
                    return card.trigger == .sound
                case .warningIndicator:
                    return card.trigger == .warningIndicator
                }
            }
            state = matchingCards.isEmpty ? .empty : .loaded(matchingCards)
        }

        private func highlightedCard() -> RecoveryCard? {
            guard let highlightedCardID = payload.highlightedCardID else {
                return nil
            }
            return allCards.first { $0.id == highlightedCardID }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RecoveryLibraryScreen(
        recoveryCards: dependencies.recoveryCards,
        payload: RecoveryLibraryPayload(
            id: "preview-recovery-library",
            origin: .catalog,
            highlightedCardID: "recovery-01",
            showPreparationFirst: true
        )
    )
        .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
