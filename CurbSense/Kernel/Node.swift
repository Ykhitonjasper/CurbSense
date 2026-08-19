import Foundation
import SwiftData

@Model
final class Node: Identifiable {
    @Attribute(.unique) var id: String
    var runbookID: String
    var sequenceIndex: Int
    var prompt: String
    var observationKind: ObservationKind
    var choiceIDs: [String]
    var choiceLabels: [String]
    var choiceTargetNodeIDs: [String]
    var endingClass: EndingClass?

    init(
        id: String,
        runbookID: String,
        sequenceIndex: Int,
        prompt: String,
        observationKind: ObservationKind,
        choiceIDs: [String],
        choiceLabels: [String],
        choiceTargetNodeIDs: [String],
        endingClass: EndingClass?
    ) {
        self.id = id
        self.runbookID = runbookID
        self.sequenceIndex = sequenceIndex
        self.prompt = prompt
        self.observationKind = observationKind
        self.choiceIDs = choiceIDs
        self.choiceLabels = choiceLabels
        self.choiceTargetNodeIDs = choiceTargetNodeIDs
        self.endingClass = endingClass
    }
}
