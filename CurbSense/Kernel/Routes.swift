import Foundation

enum AppRoute: Hashable, Sendable {
    case runbookDetail(RunbookDetailPayload)
    case recoveryLibrary(RecoveryLibraryPayload)
    case branchMap(BranchMapPayload)
    case verdict(VerdictPayload)
    case actionPack(ActionPackPayload)
    case historyDetail(HistoryDetailPayload)
    case duplicateTitle(DuplicatePayload)
    case glossary(GlossaryPayload)
}
