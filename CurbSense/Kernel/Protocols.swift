import Foundation

protocol RunbookRepository {
    func allRunbooks() -> [Runbook]
    func runbook(id: String) -> Runbook?
    func nodes(runbookID: String) -> [Node]
    func duplicateRunbook(sourceID: String, title: String) -> Runbook?
    func removeAllRunbooks() -> Int
    func restoreSeedRunbooks() -> Int
}

protocol RunSessionRepository {
    func allSessions() -> [RunSession]
    func activeSession() -> RunSession?
    func nextSessionID() -> String
    func replaceActiveSession(_ session: RunSession) -> Bool
    func saveSession(_ session: RunSession) -> Bool
    func removeAllSessions() -> Int
}

protocol RecoveryCardRepository {
    func recoveryCards() -> [RecoveryCard]
    func recoveryCard(id: String) -> RecoveryCard?
}

protocol ActionPackRepository {
    func actionPacks() -> [ActionPack]
    func actionPack(id: String) -> ActionPack?
    func saveActionPack(_ actionPack: ActionPack) -> Bool
    func removeAllActionPacks() -> Int
}

protocol GlossaryRepository {
    func glossaryEntries() -> [GlossaryEntry]
    func entries(category: GlossaryCategory) -> [GlossaryEntry]
}

protocol LocalStateRepository {
    func onboardingComplete() -> Bool
    func markOnboardingComplete() -> Bool
    func resetLocalState() -> Bool
}

protocol RunbookTraversing {
    func nextNode(from node: Node, choiceID: String, nodes: [Node]) -> Node?
    func validateGraph(runbook: Runbook, nodes: [Node]) -> GraphValidation
    func branchProgress(session: RunSession, nodes: [Node]) -> BranchProgress
}

protocol ActionPackFormatting {
    func plainText(actionPack: ActionPack, session: RunSession, runbook: Runbook) -> String
}
