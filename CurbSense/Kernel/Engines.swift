import Foundation

struct DeterministicRunbookEngine: RunbookTraversing {
    func nextNode(from node: Node, choiceID: String, nodes: [Node]) -> Node? {
        guard let choiceIndex = node.choiceIDs.firstIndex(of: choiceID),
              node.choiceTargetNodeIDs.indices.contains(choiceIndex) else {
            return nil
        }
        let targetID = node.choiceTargetNodeIDs[choiceIndex]
        return nodes.first { $0.id == targetID }
    }

    func validateGraph(runbook: Runbook, nodes: [Node]) -> GraphValidation {
        var issues: [String] = []
        let matchingNodes = nodes.filter { $0.runbookID == runbook.id }
        let ids = matchingNodes.map(\.id)
        let idSet = Set(ids)
        if ids.count != idSet.count {
            issues.append("Node identities must be unique.")
        }
        if !idSet.contains(runbook.startNodeID) {
            issues.append("The start step is missing.")
        }
        for node in matchingNodes {
            if node.choiceIDs.count != node.choiceLabels.count ||
                node.choiceIDs.count != node.choiceTargetNodeIDs.count {
                issues.append("Choice columns do not align at \(node.id).")
            }
            for target in node.choiceTargetNodeIDs where !idSet.contains(target) {
                issues.append("Choice target \(target) is missing.")
            }
        }

        var reachable: Set<String> = []
        var visiting: Set<String> = []
        var cycleFound = false

        func walk(_ nodeID: String) {
            if visiting.contains(nodeID) {
                cycleFound = true
                return
            }
            if reachable.contains(nodeID) {
                return
            }
            reachable.insert(nodeID)
            visiting.insert(nodeID)
            if let node = matchingNodes.first(where: { $0.id == nodeID }) {
                for target in node.choiceTargetNodeIDs {
                    walk(target)
                }
            }
            visiting.remove(nodeID)
        }

        walk(runbook.startNodeID)
        if cycleFound {
            issues.append("The branch graph contains a cycle.")
        }
        if reachable.count != matchingNodes.count {
            issues.append("Every step must be reachable from the start.")
        }
        let endings = Set(matchingNodes.compactMap(\.endingClass))
        let restrictedSafetyRunbook = runbook.id == "runbook-08" || runbook.id == "runbook-12"
        let requiredEndings: Set<EndingClass> = restrictedSafetyRunbook ? [.stopAndWaitSafely, .contactTrustedSupport] : Set(EndingClass.allCases)
        if !requiredEndings.isSubset(of: endings) {
            issues.append("Required ending classes are missing.")
        }
        return GraphValidation(
            id: "validation-\(runbook.id)",
            isValid: issues.isEmpty,
            issues: issues,
            reachableNodeCount: reachable.count
        )
    }

    func branchProgress(session: RunSession, nodes: [Node]) -> BranchProgress {
        let runNodes = nodes.filter { $0.runbookID == session.runbookID }
        let visited = Set(session.visitedNodeIDs)
        let remaining = runNodes
            .filter { !visited.contains($0.id) }
            .sorted { $0.sequenceIndex < $1.sequenceIndex }
            .map(\.id)
        return BranchProgress(
            id: "progress-\(session.id)",
            visitedCount: visited.count,
            totalCount: runNodes.count,
            remainingNodeIDs: remaining
        )
    }
}

struct PlainTextActionPackFormatter: ActionPackFormatting {
    func plainText(actionPack: ActionPack, session: RunSession, runbook: Runbook) -> String {
        let numberedSteps = actionPack.steps.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
        return "\(runbook.title)\n\(actionPack.headline)\n\n\(numberedSteps)\n\nPath: \(session.selectedChoiceIDs.joined(separator: " → "))"
    }
}
