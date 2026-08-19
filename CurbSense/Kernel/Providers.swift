import Foundation

final class SeededRunbookRepository: RunbookRepository {
    private let store: CurbSenseArchiveStore

    init(store: CurbSenseArchiveStore = .memory()) {
        self.store = store
    }

    func allRunbooks() -> [Runbook] {
        store.read().runbooks.map { $0.makeRunbook() }.sorted { $0.title < $1.title }
    }

    func runbook(id: String) -> Runbook? {
        store.read().runbooks.first { $0.id == id }?.makeRunbook()
    }

    func nodes(runbookID: String) -> [Node] {
        store.read().nodes.filter { $0.runbookID == runbookID }.map { $0.makeNode() }.sorted { $0.sequenceIndex < $1.sequenceIndex }
    }

    func duplicateRunbook(sourceID: String, title: String) -> Runbook? {
        var created: RunbookSnapshot?
        _ = store.update { archive in
            guard let source = archive.runbooks.first(where: { $0.id == sourceID }) else { return }
            let sourceNodes = archive.nodes.filter { $0.runbookID == sourceID }
            let sequence = archive.nextDuplicateSequence
            let newID = String(format: "custom-runbook-%06d", sequence)
            let idMap = Dictionary(uniqueKeysWithValues: sourceNodes.map { ($0.id, String(format: "custom-node-%06d-%02d", sequence, $0.sequenceIndex)) })
            let copiedNodes = sourceNodes.compactMap { node -> NodeSnapshot? in
                guard let copiedID = idMap[node.id] else { return nil }
                let copiedTargets = node.choiceTargetNodeIDs.compactMap { idMap[$0] }
                guard copiedTargets.count == node.choiceTargetNodeIDs.count else { return nil }
                var copy = node
                copy.id = copiedID
                copy.runbookID = newID
                copy.choiceTargetNodeIDs = copiedTargets
                return copy
            }
            guard copiedNodes.count == sourceNodes.count,
                  let copiedStart = idMap[source.startNodeID] else { return }
            var runbookCopy = source
            runbookCopy.id = newID
            runbookCopy.title = title
            runbookCopy.startNodeID = copiedStart
            runbookCopy.isSeeded = false
            runbookCopy.sourceRunbookID = source.id
            archive.nextDuplicateSequence += 1
            archive.runbooks.append(runbookCopy)
            archive.nodes.append(contentsOf: copiedNodes)
            created = runbookCopy
        }
        return created?.makeRunbook()
    }

    func removeAllRunbooks() -> Int {
        let removed = store.read().runbooks.count
        _ = store.update { archive in
            archive.runbooks.removeAll()
            archive.nodes.removeAll()
            archive.nextDuplicateSequence = 1
        }
        return removed
    }

    func restoreSeedRunbooks() -> Int {
        guard store.read().runbooks.isEmpty else { return 0 }
        let runbooks = CurbSenseSeedData.runbooks()
        let nodes = CurbSenseSeedData.nodes()
        _ = store.update { archive in
            archive.runbooks = runbooks.map(RunbookSnapshot.init)
            archive.nodes = nodes.map(NodeSnapshot.init)
        }
        return runbooks.count
    }
}

final class SeededRunSessionRepository: RunSessionRepository {
    private let store: CurbSenseArchiveStore

    init(store: CurbSenseArchiveStore = .memory()) {
        self.store = store
    }

    func allSessions() -> [RunSession] {
        store.read().sessions.map { $0.makeSession() }.sorted {
            $0.startedAt == $1.startedAt ? $0.id > $1.id : $0.startedAt > $1.startedAt
        }
    }

    func activeSession() -> RunSession? {
        store.read().sessions.filter { $0.status == .active }.sorted {
            $0.startedAt == $1.startedAt ? $0.id > $1.id : $0.startedAt > $1.startedAt
        }.first?.makeSession()
    }

    func nextSessionID() -> String {
        var identifier = "local-session-000001"
        _ = store.update { archive in
            let sequence = max(archive.nextSessionSequence, 1)
            identifier = String(format: "local-session-%06d", sequence)
            archive.nextSessionSequence = sequence + 1
        }
        return identifier
    }

    func replaceActiveSession(_ session: RunSession) -> Bool {
        store.update { archive in
            for index in archive.sessions.indices where archive.sessions[index].status == .active {
                archive.sessions[index].status = .abandoned
                archive.sessions[index].completedAt = session.startedAt
            }
            let snapshot = RunSessionSnapshot(session)
            if let index = archive.sessions.firstIndex(where: { $0.id == snapshot.id }) {
                archive.sessions[index] = snapshot
            } else {
                archive.sessions.append(snapshot)
            }
        }
    }

    func saveSession(_ session: RunSession) -> Bool {
        store.update { archive in
            let snapshot = RunSessionSnapshot(session)
            if let index = archive.sessions.firstIndex(where: { $0.id == snapshot.id }) {
                archive.sessions[index] = snapshot
            } else {
                archive.sessions.append(snapshot)
            }
        }
    }

    func removeAllSessions() -> Int {
        let removed = store.read().sessions.count
        _ = store.update { archive in
            archive.sessions.removeAll()
            archive.nextSessionSequence = 1
        }
        return removed
    }
}

struct SeededRecoveryCardRepository: RecoveryCardRepository {
    private let cards: [RecoveryCard]

    init(cards: [RecoveryCard] = CurbSenseSeedData.recoveryCards()) {
        self.cards = cards
    }

    func recoveryCards() -> [RecoveryCard] {
        cards.sorted { $0.priority < $1.priority }
    }

    func recoveryCard(id: String) -> RecoveryCard? {
        cards.first { $0.id == id }
    }
}

final class SeededActionPackRepository: ActionPackRepository {
    private let store: CurbSenseArchiveStore

    init(store: CurbSenseArchiveStore = .memory()) {
        self.store = store
    }

    func actionPacks() -> [ActionPack] {
        store.read().actionPacks.map { $0.makeActionPack() }.sorted { $0.generatedAt > $1.generatedAt }
    }

    func actionPack(id: String) -> ActionPack? {
        store.read().actionPacks.first { $0.id == id }?.makeActionPack()
    }

    func saveActionPack(_ actionPack: ActionPack) -> Bool {
        store.update { archive in
            let snapshot = ActionPackSnapshot(actionPack)
            if let index = archive.actionPacks.firstIndex(where: { $0.id == snapshot.id }) {
                archive.actionPacks[index] = snapshot
            } else {
                archive.actionPacks.append(snapshot)
            }
        }
    }

    func removeAllActionPacks() -> Int {
        let removed = store.read().actionPacks.count
        _ = store.update { archive in archive.actionPacks.removeAll() }
        return removed
    }
}

struct SeededGlossaryRepository: GlossaryRepository {
    private let glossary: [GlossaryEntry]

    init(entries: [GlossaryEntry] = CurbSenseSeedData.glossaryEntries()) {
        glossary = entries
    }

    func glossaryEntries() -> [GlossaryEntry] {
        glossary.sorted { $0.term < $1.term }
    }

    func entries(category: GlossaryCategory) -> [GlossaryEntry] {
        glossary.filter { $0.category == category }.sorted { $0.term < $1.term }
    }
}

final class ArchiveLocalStateRepository: LocalStateRepository {
    private let store: CurbSenseArchiveStore

    init(store: CurbSenseArchiveStore) {
        self.store = store
    }

    func onboardingComplete() -> Bool {
        store.read().onboardingComplete
    }

    func markOnboardingComplete() -> Bool {
        store.update { archive in archive.onboardingComplete = true }
    }

    func resetLocalState() -> Bool {
        store.reset()
    }
}
