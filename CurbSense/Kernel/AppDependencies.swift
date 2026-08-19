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
