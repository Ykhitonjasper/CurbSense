import Foundation
import SwiftData

@Model
final class RunSession: Identifiable {
    @Attribute(.unique) var id: String
    var runbookID: String
    var currentNodeID: String
    var visitedNodeIDs: [String]
    var selectedChoiceIDs: [String]
    var status: SessionStatus
    var startedAt: Date
    var completedAt: Date?
    var endingClass: EndingClass?
    var actionPackID: String?

    init(
        id: String,
        runbookID: String,
        currentNodeID: String,
        visitedNodeIDs: [String],
        selectedChoiceIDs: [String],
        status: SessionStatus,
        startedAt: Date,
        completedAt: Date?,
        endingClass: EndingClass?,
        actionPackID: String?
    ) {
        self.id = id
        self.runbookID = runbookID
        self.currentNodeID = currentNodeID
        self.visitedNodeIDs = visitedNodeIDs
        self.selectedChoiceIDs = selectedChoiceIDs
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.endingClass = endingClass
        self.actionPackID = actionPackID
    }
}
