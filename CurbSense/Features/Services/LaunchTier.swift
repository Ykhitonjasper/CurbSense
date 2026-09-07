import Foundation

/// Cold branded splash (no cached URL) vs warm overlay (cached URL).
enum LaunchTier: Equatable {
    case cold
    case warm

    var showsBrandedSplash: Bool {
        if case .cold = self { return true }
        return false
    }

    var showsWarmOverlay: Bool {
        if case .warm = self { return true }
        return false
    }

    var loaderMin: TimeInterval {
        switch self {
        case .cold: Timeouts.coldLoaderMin
        case .warm: Timeouts.warmOverlayMin
        }
    }

    var launchBudget: TimeInterval {
        switch self {
        case .cold: Timeouts.coldLaunchBudget
        case .warm: Timeouts.warmLaunchBudget
        }
    }

    var loaderMax: TimeInterval { launchBudget }

    static func resolve(cachedURL: String?, launchCount: Int = 0) -> LaunchTier {
        cachedURL != nil ? .warm : .cold
    }
}

/// Internal milestones only — UI copy must NOT mirror network steps.
enum LaunchLoaderStage: String, Equatable {
    case idle
    case starting
    case loadingRoute
    case preparingContent
    case finishing
    case complete
}

enum LaunchSplashCopy {
    static func message(for progress: Double) -> String {
        switch progress {
        case ..<0.40:
            return "Opening observation rail..."
        case ..<0.78:
            return "Staging runbook steps..."
        case ..<1.0:
            return "Almost ready..."
        default:
            return "Ready"
        }
    }
}
