import Foundation

enum CurbSenseSeedData {
    static func runbooks() -> [Runbook] {
        [
            Runbook(id: "runbook-01", title: "Curb Strike Check", summary: "Review visible wheel and tire conditions after touching a curb.", riskBand: .caution, durationMinutes: 8, supplyNames: ["Flashlight", "Tire gauge"], startNodeID: "node-01-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-02", title: "Pothole Thump", summary: "Compare tire, wheel, and steering observations after a sharp road impact.", riskBand: .caution, durationMinutes: 9, supplyNames: ["Flashlight", "Clean cloth"], startNodeID: "node-02-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-03", title: "New Steering Pull", summary: "Walk through safe stationary checks for a newly noticed steering pull.", riskBand: .caution, durationMinutes: 7, supplyNames: ["Tire gauge", "Notepad"], startNodeID: "node-03-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-04", title: "Scrape After Parking", summary: "Sort cosmetic marks from loose or sharp exterior pieces.", riskBand: .routine, durationMinutes: 6, supplyNames: ["Flashlight", "Gloves"], startNodeID: "node-04-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-05", title: "Tire Sidewall Mark", summary: "Classify a visible sidewall mark without treating it as a diagnosis.", riskBand: .stop, durationMinutes: 7, supplyNames: ["Flashlight", "Tire gauge"], startNodeID: "node-05-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-06", title: "Wheel Vibration", summary: "Record when vibration appears and choose a cautious next action.", riskBand: .caution, durationMinutes: 8, supplyNames: ["Notepad", "Tire gauge"], startNodeID: "node-06-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-07", title: "Low Tire Pressure Light", summary: "Check visible tire shape and pressure readings before departure.", riskBand: .caution, durationMinutes: 8, supplyNames: ["Tire gauge", "Vehicle handbook"], startNodeID: "node-07-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-08", title: "Brake Warning Before Departure", summary: "Use stationary observations to decide whether departure should wait.", riskBand: .stop, durationMinutes: 6, supplyNames: ["Vehicle handbook", "Flashlight"], startNodeID: "node-08-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-09", title: "Fluid Under the Car", summary: "Observe location, color, and amount while keeping a safe distance.", riskBand: .stop, durationMinutes: 7, supplyNames: ["Flashlight", "Cardboard"], startNodeID: "node-09-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-10", title: "Loose Bumper Panel", summary: "Check whether an exterior panel is secure and clear of moving parts.", riskBand: .caution, durationMinutes: 6, supplyNames: ["Flashlight", "Gloves"], startNodeID: "node-10-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-11", title: "Spare Tire Missing", summary: "Prepare an alternative roadside plan before the next drive.", riskBand: .routine, durationMinutes: 5, supplyNames: ["Vehicle handbook", "Notepad"], startNodeID: "node-11-01", isSeeded: true, sourceRunbookID: nil),
            Runbook(id: "runbook-12", title: "Temperature Gauge Rising", summary: "Respond conservatively to a rising gauge and visible heat signs.", riskBand: .stop, durationMinutes: 5, supplyNames: ["Vehicle handbook", "Phone"], startNodeID: "node-12-01", isSeeded: true, sourceRunbookID: nil),
        ]
    }

    static func nodes() -> [Node] {
        let definitions: [(String, String, [String])] = [
            ("runbook-01", "wheel edge and tire", ["node-01-01", "node-01-02", "node-01-03", "node-01-04", "node-01-05", "node-01-06", "node-01-07", "node-01-08"]),
            ("runbook-02", "impact-side wheel area", ["node-02-01", "node-02-02", "node-02-03", "node-02-04", "node-02-05", "node-02-06", "node-02-07", "node-02-08"]),
            ("runbook-03", "front tires and steering", ["node-03-01", "node-03-02", "node-03-03", "node-03-04", "node-03-05", "node-03-06", "node-03-07", "node-03-08"]),
            ("runbook-04", "scraped exterior area", ["node-04-01", "node-04-02", "node-04-03", "node-04-04", "node-04-05", "node-04-06", "node-04-07", "node-04-08"]),
            ("runbook-05", "marked tire sidewall", ["node-05-01", "node-05-02", "node-05-03", "node-05-04", "node-05-05", "node-05-06", "node-05-07", "node-05-08"]),
            ("runbook-06", "wheel and cabin vibration", ["node-06-01", "node-06-02", "node-06-03", "node-06-04", "node-06-05", "node-06-06", "node-06-07", "node-06-08"]),
            ("runbook-07", "low-pressure tire", ["node-07-01", "node-07-02", "node-07-03", "node-07-04", "node-07-05", "node-07-06", "node-07-07", "node-07-08"]),
            ("runbook-08", "brake warning display", ["node-08-01", "node-08-02", "node-08-03", "node-08-04", "node-08-05", "node-08-06", "node-08-07", "node-08-08"]),
            ("runbook-09", "fluid patch location", ["node-09-01", "node-09-02", "node-09-03", "node-09-04", "node-09-05", "node-09-06", "node-09-07", "node-09-08"]),
            ("runbook-10", "bumper panel edge", ["node-10-01", "node-10-02", "node-10-03", "node-10-04", "node-10-05", "node-10-06", "node-10-07", "node-10-08"]),
            ("runbook-11", "roadside equipment bay", ["node-11-01", "node-11-02", "node-11-03", "node-11-04", "node-11-05", "node-11-06", "node-11-07", "node-11-08"]),
            ("runbook-12", "temperature display and heat signs", ["node-12-01", "node-12-02", "node-12-03", "node-12-04", "node-12-05", "node-12-06", "node-12-07", "node-12-08"]),
        ]
        return definitions.flatMap { makeNodes(runbookID: $0.0, subject: $0.1, ids: $0.2) }
    }

    private static func makeNodes(runbookID: String, subject: String, ids: [String]) -> [Node] {
        guard ids.count == 8 else { return [] }
        if runbookID == "runbook-08" || runbookID == "runbook-12" {
            return restrictedSafetyNodes(runbookID: runbookID, subject: subject, ids: ids)
        }
        return [
            Node(id: ids[0], runbookID: runbookID, sequenceIndex: 1, prompt: "Park in a stable place and look at the \(subject). Is there an immediate hazard?", observationKind: .visibleCondition, choiceIDs: ["clear-1", "hazard-1"], choiceLabels: ["No immediate hazard", "Hazard is visible"], choiceTargetNodeIDs: [ids[1], ids[7]], endingClass: nil),
            Node(id: ids[1], runbookID: runbookID, sequenceIndex: 2, prompt: "Compare both sides. Does the \(subject) look uneven or displaced?", observationKind: .visibleCondition, choiceIDs: ["even-2", "uneven-2"], choiceLabels: ["Looks even", "Looks uneven"], choiceTargetNodeIDs: [ids[2], ids[6]], endingClass: nil),
            Node(id: ids[2], runbookID: runbookID, sequenceIndex: 3, prompt: "Without touching hot or moving parts, note any fresh sound or movement.", observationKind: .sound, choiceIDs: ["quiet-3", "concerning-3"], choiceLabels: ["Nothing concerning", "Concerning sign present"], choiceTargetNodeIDs: [ids[3], ids[7]], endingClass: nil),
            Node(id: ids[3], runbookID: runbookID, sequenceIndex: 4, prompt: "Check the relevant handbook indicator and record what remains visible.", observationKind: .warningIndicator, choiceIDs: ["stable-4", "changed-4"], choiceLabels: ["Condition is stable", "Condition has changed"], choiceTargetNodeIDs: [ids[4], ids[6]], endingClass: nil),
            Node(id: ids[4], runbookID: runbookID, sequenceIndex: 5, prompt: "Choose the next action that matches only the observations you recorded.", observationKind: .steeringFeel, choiceIDs: ["complete-5", "pause-5"], choiceLabels: ["Finish the preparation", "Wait before departure"], choiceTargetNodeIDs: [ids[5], ids[6]], endingClass: nil),
            Node(id: ids[5], runbookID: runbookID, sequenceIndex: 6, prompt: "The observation walk is complete. This records visible conditions only and does not determine roadworthiness.", observationKind: .visibleCondition, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .safeActionComplete),
            Node(id: ids[6], runbookID: runbookID, sequenceIndex: 7, prompt: "Pause the drive and wait in a safe place until the condition can be reviewed.", observationKind: .visibleCondition, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .stopAndWaitSafely),
            Node(id: ids[7], runbookID: runbookID, sequenceIndex: 8, prompt: "Keep clear of the vehicle and contact a trusted person or suitable local service.", observationKind: .visibleCondition, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .contactTrustedSupport),
        ]
    }

    private static func restrictedSafetyNodes(runbookID: String, subject: String, ids: [String]) -> [Node] {
        [
            Node(id: ids[0], runbookID: runbookID, sequenceIndex: 1, prompt: "Keep the vehicle parked and observe the \(subject) from a stable place. Is there an immediate hazard?", observationKind: .warningIndicator, choiceIDs: ["continue-observation-1", "qualified-support-1"], choiceLabels: ["Continue the parked observation", "Contact a qualified local service"], choiceTargetNodeIDs: [ids[1], ids[7]], endingClass: nil),
            Node(id: ids[1], runbookID: runbookID, sequenceIndex: 2, prompt: "Does the warning remain visible while the vehicle stays parked?", observationKind: .warningIndicator, choiceIDs: ["warning-remains-2", "warning-changed-2"], choiceLabels: ["Warning remains visible", "Warning changed or heat signs appeared"], choiceTargetNodeIDs: [ids[2], ids[6]], endingClass: nil),
            Node(id: ids[2], runbookID: runbookID, sequenceIndex: 3, prompt: "Without touching hot or moving parts, note any fresh sound, smell, or visible change.", observationKind: .sound, choiceIDs: ["recorded-3", "concerning-3"], choiceLabels: ["Observation recorded", "Concerning sign present"], choiceTargetNodeIDs: [ids[3], ids[7]], endingClass: nil),
            Node(id: ids[3], runbookID: runbookID, sequenceIndex: 4, prompt: "Use the vehicle handbook only to identify the displayed warning while remaining parked.", observationKind: .warningIndicator, choiceIDs: ["identified-4", "uncertain-4"], choiceLabels: ["Warning identified", "Meaning remains uncertain"], choiceTargetNodeIDs: [ids[4], ids[6]], endingClass: nil),
            Node(id: ids[4], runbookID: runbookID, sequenceIndex: 5, prompt: "Choose a parked next step. This walk cannot clear the vehicle for departure.", observationKind: .visibleCondition, choiceIDs: ["keep-parked-5", "qualified-service-5"], choiceLabels: ["Keep parked for review", "Contact a qualified local service"], choiceTargetNodeIDs: [ids[5], ids[7]], endingClass: nil),
            Node(id: ids[5], runbookID: runbookID, sequenceIndex: 6, prompt: "The observation walk is complete. Keep the vehicle parked until a qualified local review.", observationKind: .warningIndicator, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .stopAndWaitSafely),
            Node(id: ids[6], runbookID: runbookID, sequenceIndex: 7, prompt: "Stop the walk, keep the vehicle parked, and wait in a stable place.", observationKind: .warningIndicator, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .stopAndWaitSafely),
            Node(id: ids[7], runbookID: runbookID, sequenceIndex: 8, prompt: "Keep clear of heat or moving traffic and contact a qualified local service.", observationKind: .visibleCondition, choiceIDs: [], choiceLabels: [], choiceTargetNodeIDs: [], endingClass: .contactTrustedSupport),
        ]
    }

    static func sessions() -> [RunSession] {
        [
            RunSession(id: "session-001", runbookID: "runbook-01", currentNodeID: "node-01-06", visitedNodeIDs: ["node-01-01", "node-01-02", "node-01-03", "node-01-04", "node-01-05", "node-01-06"], selectedChoiceIDs: ["clear-1", "even-2", "quiet-3", "stable-4", "complete-5"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_000_000), completedAt: Date(timeIntervalSince1970: 1_782_000_480), endingClass: .safeActionComplete, actionPackID: "action-001"),
            RunSession(id: "session-002", runbookID: "runbook-02", currentNodeID: "node-02-07", visitedNodeIDs: ["node-02-01", "node-02-02", "node-02-07"], selectedChoiceIDs: ["clear-1", "uneven-2"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_086_400), completedAt: Date(timeIntervalSince1970: 1_782_086_760), endingClass: .stopAndWaitSafely, actionPackID: "action-002"),
            RunSession(id: "session-003", runbookID: "runbook-05", currentNodeID: "node-05-08", visitedNodeIDs: ["node-05-01", "node-05-08"], selectedChoiceIDs: ["hazard-1"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_172_800), completedAt: Date(timeIntervalSince1970: 1_782_173_040), endingClass: .contactTrustedSupport, actionPackID: "action-003"),
            RunSession(id: "session-004", runbookID: "runbook-07", currentNodeID: "node-07-06", visitedNodeIDs: ["node-07-01", "node-07-02", "node-07-03", "node-07-04", "node-07-05", "node-07-06"], selectedChoiceIDs: ["clear-1", "even-2", "quiet-3", "stable-4", "complete-5"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_259_200), completedAt: Date(timeIntervalSince1970: 1_782_259_680), endingClass: .safeActionComplete, actionPackID: "action-004"),
            RunSession(id: "session-005", runbookID: "runbook-09", currentNodeID: "node-09-07", visitedNodeIDs: ["node-09-01", "node-09-02", "node-09-03", "node-09-04", "node-09-07"], selectedChoiceIDs: ["clear-1", "even-2", "quiet-3", "changed-4"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_345_600), completedAt: Date(timeIntervalSince1970: 1_782_346_080), endingClass: .stopAndWaitSafely, actionPackID: "action-005"),
            RunSession(id: "session-006", runbookID: "runbook-12", currentNodeID: "node-12-08", visitedNodeIDs: ["node-12-01", "node-12-08"], selectedChoiceIDs: ["hazard-1"], status: .completed, startedAt: Date(timeIntervalSince1970: 1_782_432_000), completedAt: Date(timeIntervalSince1970: 1_782_432_180), endingClass: .contactTrustedSupport, actionPackID: "action-006"),
        ]
    }

    static func recoveryCards() -> [RecoveryCard] {
        [
            RecoveryCard(id: "recovery-01", title: "Build a glovebox check kit", trigger: .visibleCondition, preparation: "Keep a flashlight, clean cloth, tire gauge, and note card together.", priority: 1),
            RecoveryCard(id: "recovery-02", title: "Mark handbook pages", trigger: .warningIndicator, preparation: "Flag the tire, brake, and temperature indicator pages for quick reference.", priority: 2),
            RecoveryCard(id: "recovery-03", title: "Practice pressure readings", trigger: .visibleCondition, preparation: "Learn the recommended cold pressure location before it is needed.", priority: 3),
            RecoveryCard(id: "recovery-04", title: "Choose trusted contacts", trigger: .steeringFeel, preparation: "Write down two people or local services you can contact when a drive should wait.", priority: 4),
            RecoveryCard(id: "recovery-05", title: "Learn normal steering feel", trigger: .steeringFeel, preparation: "Record how the vehicle feels on a familiar level route when conditions are normal.", priority: 5),
            RecoveryCard(id: "recovery-06", title: "Learn normal road sounds", trigger: .sound, preparation: "Notice ordinary tire and cabin sounds so a fresh change is easier to describe.", priority: 6),
            RecoveryCard(id: "recovery-07", title: "Check roadside equipment", trigger: .visibleCondition, preparation: "Confirm the spare arrangement and supplied tools listed in the handbook.", priority: 7),
            RecoveryCard(id: "recovery-08", title: "Set a safe waiting plan", trigger: .warningIndicator, preparation: "Choose well-lit places where you can stop away from moving traffic.", priority: 8),
        ]
    }

    static func actionPacks() -> [ActionPack] {
        [
            ActionPack(id: "action-001", sessionID: "session-001", headline: "Observation walk completed", steps: ["Retain the observation path.", "Completion records observations only and does not determine roadworthiness.", "Seek qualified local review if the condition changes."], generatedAt: Date(timeIntervalSince1970: 1_782_000_480)),
            ActionPack(id: "action-002", sessionID: "session-002", headline: "Departure should wait", steps: ["Keep the vehicle parked safely.", "Share the recorded uneven condition.", "Arrange a suitable local review."], generatedAt: Date(timeIntervalSince1970: 1_782_086_760)),
            ActionPack(id: "action-003", sessionID: "session-003", headline: "Trusted support is the next step", steps: ["Keep clear of the affected area.", "Share the visible observation.", "Follow local safety guidance."], generatedAt: Date(timeIntervalSince1970: 1_782_173_040)),
            ActionPack(id: "action-004", sessionID: "session-004", headline: "Observation walk completed", steps: ["Keep the readings.", "Completion records observations only and does not determine roadworthiness.", "Seek qualified local review if the indicator returns."], generatedAt: Date(timeIntervalSince1970: 1_782_259_680)),
            ActionPack(id: "action-005", sessionID: "session-005", headline: "Condition changed during the walk", steps: ["Do not disturb the patch.", "Keep the location notes.", "Arrange a suitable local review."], generatedAt: Date(timeIntervalSince1970: 1_782_346_080)),
            ActionPack(id: "action-006", sessionID: "session-006", headline: "Keep clear and seek support", steps: ["Wait away from heat and moving traffic.", "Share the gauge observation.", "Contact trusted support."], generatedAt: Date(timeIntervalSince1970: 1_782_432_180)),
        ]
    }

    static func glossaryEntries() -> [GlossaryEntry] {
        [
            GlossaryEntry(id: "glossary-01", term: "Steering pull", category: .steeringFeel, definition: "A repeated tendency to drift to one side on a level road.", examples: ["Fresh after an impact", "Different from road slope"]),
            GlossaryEntry(id: "glossary-02", term: "Steering vibration", category: .steeringFeel, definition: "A repeated shake felt through the steering wheel.", examples: ["Appears at a certain speed", "Changes on a smooth road"]),
            GlossaryEntry(id: "glossary-03", term: "Soft steering response", category: .steeringFeel, definition: "A response that feels less direct than the driver's normal reference.", examples: ["More correction needed", "Fresh change"]),
            GlossaryEntry(id: "glossary-04", term: "Rhythmic thump", category: .sound, definition: "A repeating sound that follows wheel rotation.", examples: ["Slow regular beat", "Changes with speed"]),
            GlossaryEntry(id: "glossary-05", term: "Scrape sound", category: .sound, definition: "A continuous rubbing sound rather than a single impact.", examples: ["From one corner", "Present while rolling"]),
            GlossaryEntry(id: "glossary-06", term: "Fresh click", category: .sound, definition: "A newly noticed short sound that repeats or follows movement.", examples: ["During steering", "After a road impact"]),
            GlossaryEntry(id: "glossary-07", term: "Sidewall bulge", category: .visibleCondition, definition: "A raised outward area on the side of a tire.", examples: ["Different from molded lettering", "Visible from the side"]),
            GlossaryEntry(id: "glossary-08", term: "Sidewall cut", category: .visibleCondition, definition: "A split or opening rather than a surface rub mark.", examples: ["Edges visibly separated", "Fresh material exposed"]),
            GlossaryEntry(id: "glossary-09", term: "Panel gap", category: .visibleCondition, definition: "Uneven spacing where exterior panels normally meet.", examples: ["One side wider", "Edge no longer flush"]),
            GlossaryEntry(id: "glossary-10", term: "Fluid patch", category: .visibleCondition, definition: "A fresh wet area beneath the parked vehicle.", examples: ["Location under front", "Color noted without touching"]),
            GlossaryEntry(id: "glossary-11", term: "Wheel edge mark", category: .visibleCondition, definition: "A fresh scrape or deformation at the outer wheel edge.", examples: ["Surface rub", "Edge appears changed"]),
            GlossaryEntry(id: "glossary-12", term: "Warning indicator", category: .visibleCondition, definition: "A dashboard symbol that remains visible after the usual start sequence.", examples: ["Steady symbol", "Freshly appeared"]),
        ]
    }
}
