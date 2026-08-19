import Observation
import SwiftUI

struct ObservationGlossaryScreen: View {
    @Environment(CurbSenseStore.self) private var store
    @State private var viewModel: ViewModel

    init(glossary: any GlossaryRepository, payload: GlossaryPayload) {
        _viewModel = State(
            initialValue: ViewModel(
                glossary: glossary,
                initialCategory: payload.category,
                highlightedTerm: payload.highlightedTerm,
                returnToActive: payload.returnToActive
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                categoryFilter(viewModel: $viewModel)

                switch viewModel.state {
                case .loaded(let entries):
                    glossaryList(entries, viewModel: viewModel)
                case .empty:
                    emptyState
                }
            }
            .padding(20)
        }
        .background(AppBackground())
        .navigationTitle(AppTheme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search observation terms"
        )
        .onAppear {
            viewModel.load()
        }
        .sensoryFeedback(.selection, trigger: viewModel.filterSignature)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.expandedEntryID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observation glossary")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Use these shared terms to describe sounds, steering feel, and visible conditions without guessing at a cause.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            if viewModel.returnToActive {
                Button {
                    returnToActiveCheck()
                } label: {
                    Label("Return to active check", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .accessibilityLabel("Return to active check")
                .accessibilityHint("Returns to the active runbook step")
            }
        }
    }

    private func categoryFilter(viewModel: Bindable<ViewModel>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter observation terms")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Picker("Observation category", selection: viewModel.categoryFilter) {
                ForEach(ViewModel.CategoryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.accent)
            .accessibilityLabel("Filter glossary by observation category")
            .accessibilityHint("Shows terms from the selected observation category")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
    }

    private func glossaryList(_ entries: [GlossaryEntry], viewModel: ViewModel) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("\(entries.count) \(entries.count == 1 ? "term" : "terms")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityLabel("\(entries.count) glossary \(entries.count == 1 ? "term" : "terms") shown")

            ForEach(entries) { entry in
                entryCard(entry, isExpanded: viewModel.expandedEntryID == entry.id)
            }
        }
    }

    private func entryCard(_ entry: GlossaryEntry, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.select(entry)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: entry.category))
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.term)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(categoryTitle(for: entry.category))
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
            .accessibilityLabel("\(isExpanded ? "Hide" : "Show") \(categoryTitle(for: entry.category)) definition for \(entry.term)")
            .accessibilityHint(isExpanded ? "Hides the definition and examples" : "Shows the definition and examples")

            if isExpanded {
                Text(entry.definition)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(entry.examples, id: \.self) { example in
                        Label(example, systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
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
            Label("No matching terms", systemImage: "magnifyingglass")
        } description: {
            Text("Clear the search or choose every category to see the available observation terms.")
        } actions: {
            Button("Show every term") {
                viewModel.clearFilters()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Show every glossary term")
            .accessibilityHint("Clears the search and category filter")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func categoryTitle(for category: GlossaryCategory) -> String {
        switch category {
        case .sound:
            "Sound"
        case .steeringFeel:
            "Steering feel"
        case .visibleCondition:
            "Visible condition"
        }
    }

    private func icon(for category: GlossaryCategory) -> String {
        switch category {
        case .sound:
            "waveform"
        case .steeringFeel:
            "steeringwheel"
        case .visibleCondition:
            "eye"
        }
    }

    private func returnToActiveCheck() {
        store.path.removeAll()
        store.selectedTab = "Active"
    }
}

extension ObservationGlossaryScreen {
    @MainActor
    @Observable
    final class ViewModel {
        enum State {
            case loaded([GlossaryEntry])
            case empty
        }

        enum CategoryFilter: String, CaseIterable, Identifiable {
            case all
            case sound
            case steeringFeel
            case visibleCondition

            var id: String { rawValue }

            var title: String {
                switch self {
                case .all:
                    "Every category"
                case .sound:
                    "Sound"
                case .steeringFeel:
                    "Steering feel"
                case .visibleCondition:
                    "Visible condition"
                }
            }

            var category: GlossaryCategory? {
                switch self {
                case .all:
                    nil
                case .sound:
                    .sound
                case .steeringFeel:
                    .steeringFeel
                case .visibleCondition:
                    .visibleCondition
                }
            }
        }

        private let glossary: any GlossaryRepository
        private var highlightedTerm: String?
        private var allEntries: [GlossaryEntry] = []

        var state: State = .empty
        var categoryFilter: CategoryFilter {
            didSet { applyFilters() }
        }
        var searchText = "" {
            didSet { applyFilters() }
        }
        var expandedEntryID: String?
        let returnToActive: Bool

        var filterSignature: String {
            "\(categoryFilter.rawValue)-\(searchText)"
        }

        init(
            glossary: any GlossaryRepository,
            initialCategory: GlossaryCategory?,
            highlightedTerm: String?,
            returnToActive: Bool
        ) {
            self.glossary = glossary
            self.highlightedTerm = highlightedTerm
            self.categoryFilter = Self.filter(for: initialCategory)
            self.returnToActive = returnToActive
        }

        func load() {
            allEntries = glossary.glossaryEntries()
            applyFilters()
        }

        func clearFilters() {
            categoryFilter = .all
            searchText = ""
        }

        func select(_ entry: GlossaryEntry) {
            expandedEntryID = expandedEntryID == entry.id ? nil : entry.id
        }

        private func applyFilters() {
            let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchingEntries = allEntries.filter { entry in
                matchesCategory(entry) && matchesSearch(entry, query: normalizedSearch)
            }
            state = matchingEntries.isEmpty ? .empty : .loaded(matchingEntries)

            if let highlightedTerm,
               let highlightedEntry = matchingEntries.first(where: {
                   $0.term.caseInsensitiveCompare(highlightedTerm) == .orderedSame
               }) {
                expandedEntryID = highlightedEntry.id
            }
            highlightedTerm = nil
        }

        private func matchesCategory(_ entry: GlossaryEntry) -> Bool {
            guard let category = categoryFilter.category else { return true }
            return entry.category == category
        }

        private func matchesSearch(_ entry: GlossaryEntry, query: String) -> Bool {
            guard !query.isEmpty else { return true }
            return entry.term.localizedCaseInsensitiveContains(query)
                || entry.definition.localizedCaseInsensitiveContains(query)
                || entry.examples.contains { $0.localizedCaseInsensitiveContains(query) }
        }

        private static func filter(for category: GlossaryCategory?) -> CategoryFilter {
            switch category {
            case .sound:
                .sound
            case .steeringFeel:
                .steeringFeel
            case .visibleCondition:
                .visibleCondition
            case nil:
                .all
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    ObservationGlossaryScreen(
        glossary: dependencies.glossary,
        payload: GlossaryPayload(
            id: "preview-glossary",
            category: nil,
            highlightedTerm: "Steering pull",
            returnToActive: false
        )
    )
    .environment(CurbSenseStore(dependencies: dependencies, hasCompletedOnboarding: true))
}
