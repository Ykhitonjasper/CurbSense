import Foundation
import Observation

@MainActor
@Observable
final class CurbSenseStore {
    var hasCompletedOnboarding: Bool
    var selectedTab: String
    var path: [AppRoute]
    var activeSession: RunSession?
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies, hasCompletedOnboarding: Bool = false) {
        self.dependencies = dependencies
        self.hasCompletedOnboarding = hasCompletedOnboarding || dependencies.localState.onboardingComplete()
        selectedTab = "Runbooks"
        path = []
        activeSession = dependencies.sessions.activeSession()
    }

    func completeOnboarding() {
        _ = dependencies.runbooks.restoreSeedRunbooks()
        hasCompletedOnboarding = dependencies.localState.markOnboardingComplete()
    }

    func start(runbook: Runbook) {
        let session = RunSession(
            id: dependencies.sessions.nextSessionID(),
            runbookID: runbook.id,
            currentNodeID: runbook.startNodeID,
            visitedNodeIDs: [runbook.startNodeID],
            selectedChoiceIDs: [],
            status: .active,
            startedAt: Date(),
            completedAt: nil,
            endingClass: nil,
            actionPackID: nil
        )
        guard dependencies.sessions.replaceActiveSession(session) else { return }
        activeSession = session
        selectedTab = "Active"
        path.removeAll()
    }

    func choose(_ choiceID: String) {
        guard let session = activeSession,
              let current = dependencies.runbooks.nodes(runbookID: session.runbookID).first(where: { $0.id == session.currentNodeID }),
              let next = dependencies.traversal.nextNode(from: current, choiceID: choiceID, nodes: dependencies.runbooks.nodes(runbookID: session.runbookID)) else {
            return
        }
        session.selectedChoiceIDs.append(choiceID)
        session.currentNodeID = next.id
        session.visitedNodeIDs.append(next.id)
        if let ending = next.endingClass {
            finish(session: session, ending: ending)
        } else {
            _ = dependencies.sessions.saveSession(session)
        }
    }

    func deleteAllData() {
        _ = dependencies.localState.resetLocalState()
        activeSession = nil
        path.removeAll()
        selectedTab = "Runbooks"
        hasCompletedOnboarding = false
    }

    private func finish(session: RunSession, ending: EndingClass) {
        let actionID = "local-action-\(session.id)"
        session.status = .completed
        session.completedAt = Date()
        session.endingClass = ending
        session.actionPackID = actionID
        let pack = ActionPack(id: actionID, sessionID: session.id, headline: headline(for: ending), steps: steps(for: ending), generatedAt: Date())
        _ = dependencies.actionPacks.saveActionPack(pack)
        _ = dependencies.sessions.saveSession(session)
        activeSession = nil
        path.append(.verdict(VerdictPayload(id: "verdict-\(session.id)", sessionID: session.id, endingClass: ending, actionPackID: actionID)))
    }

    private func headline(for ending: EndingClass) -> String {
        switch ending {
        case .safeActionComplete:
            return "Observation walk completed"
        case .stopAndWaitSafely:
            return "Keep the vehicle parked"
        case .contactTrustedSupport:
            return "Qualified local support is the next step"
        }
    }

    private func steps(for ending: EndingClass) -> [String] {
        switch ending {
        case .safeActionComplete:
            return ["Keep the observation path.", "Completion records observations only and does not determine roadworthiness.", "Pause and seek qualified local review if the condition changes."]
        case .stopAndWaitSafely:
            return ["Keep the vehicle parked in a stable place.", "Share the recorded observations.", "Arrange a qualified local review before departure."]
        case .contactTrustedSupport:
            return ["Keep clear of the affected area.", "Share the recorded observation.", "Contact a trusted person or qualified local service."]
        }
    }
}
