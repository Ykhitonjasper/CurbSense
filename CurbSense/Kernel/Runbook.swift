import Foundation
import SwiftData

@Model
final class Runbook: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var summary: String
    var riskBand: RiskBand
    var durationMinutes: Int
    var supplyNames: [String]
    var startNodeID: String
    var isSeeded: Bool
    var sourceRunbookID: String?

    init(
        id: String,
        title: String,
        summary: String,
        riskBand: RiskBand,
        durationMinutes: Int,
        supplyNames: [String],
        startNodeID: String,
        isSeeded: Bool,
        sourceRunbookID: String?
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.riskBand = riskBand
        self.durationMinutes = durationMinutes
        self.supplyNames = supplyNames
        self.startNodeID = startNodeID
        self.isSeeded = isSeeded
        self.sourceRunbookID = sourceRunbookID
    }
}
