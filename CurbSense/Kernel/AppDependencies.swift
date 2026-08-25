import Foundation

struct AppDependencies {
    let runbooks: any RunbookRepository
    let sessions: any RunSessionRepository
    let recoveryCards: any RecoveryCardRepository
    let actionPacks: any ActionPackRepository
    let glossary: any GlossaryRepository
    let localState: any LocalStateRepository
    let traversal: any RunbookTraversing
    let formatter: any ActionPackFormatting
    let analyticsCoordinator: AnalyticsCoordinating
    let analyticsSession: AnalyticsSessionProviding

    init(
        runbooks: any RunbookRepository,
        sessions: any RunSessionRepository,
        recoveryCards: any RecoveryCardRepository,
        actionPacks: any ActionPackRepository,
        glossary: any GlossaryRepository,
        localState: any LocalStateRepository,
        traversal: any RunbookTraversing,
        formatter: any ActionPackFormatting,
        analyticsCoordinator: AnalyticsCoordinating = AnalyticsCoordinator.shared,
        analyticsSession: AnalyticsSessionProviding = AnalyticsSession.shared
    ) {
        self.runbooks = runbooks
        self.sessions = sessions
        self.recoveryCards = recoveryCards
        self.actionPacks = actionPacks
        self.glossary = glossary
        self.localState = localState
        self.traversal = traversal
        self.formatter = formatter
        self.analyticsCoordinator = analyticsCoordinator
        self.analyticsSession = analyticsSession
    }

    static func preview() -> AppDependencies {
        let archive = CurbSenseArchiveStore.memory()
        return AppDependencies(
            runbooks: SeededRunbookRepository(store: archive),
            sessions: SeededRunSessionRepository(store: archive),
            recoveryCards: SeededRecoveryCardRepository(),
            actionPacks: SeededActionPackRepository(store: archive),
            glossary: SeededGlossaryRepository(),
            localState: ArchiveLocalStateRepository(store: archive),
            traversal: DeterministicRunbookEngine(),
            formatter: PlainTextActionPackFormatter()
        )
    }

    static func app() -> AppDependencies {
        let archive = CurbSenseArchiveStore.persistent()
        return AppDependencies(
            runbooks: SeededRunbookRepository(store: archive),
            sessions: SeededRunSessionRepository(store: archive),
            recoveryCards: SeededRecoveryCardRepository(),
            actionPacks: SeededActionPackRepository(store: archive),
            glossary: SeededGlossaryRepository(),
            localState: ArchiveLocalStateRepository(store: archive),
            traversal: DeterministicRunbookEngine(),
            formatter: PlainTextActionPackFormatter()
        )
    }
}
