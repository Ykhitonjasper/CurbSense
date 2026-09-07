import Foundation

enum Timeouts {
    // Shared budgets
    public static let startup: TimeInterval = 5.5
    public static let coldStart: TimeInterval = 8.0
    public static let primingWindow: TimeInterval = 6.0
    public static let decisionDeadline: TimeInterval = 3.0
    public static let minimumReadyWindow: TimeInterval = 1.5
    public static let networkTimeout: TimeInterval = 3.0
    public static let networkProbeTimeout: TimeInterval = 0.4
    public static let networkProbeCacheTTL: TimeInterval = 2.0
    public static let coverFadeOut: TimeInterval = 0.2
    public static let nativeFlashMax: TimeInterval = 0.3

    /// Splash → web dissolve after content is ready (chrome exits, then veil).
    public static let revealCrossfade: TimeInterval = 0.48
    /// Warm dissolve — slightly snappier than cold, still staged.
    public static let warmRevealCrossfade: TimeInterval = 0.36

    public static let minimumContentScore = 9

    public static let coldLoaderMin: TimeInterval = 1.3
    public static let coldLaunchBudget: TimeInterval = 5.2
    public static let coldGracefulFade: TimeInterval = 0.35
    public static let coldSplashFeel: TimeInterval = 1.6

    // Warm launch — cached URL; short overlay, own wall
    public static let warmOverlayMin: TimeInterval = 0.25
    public static let warmLaunchBudget: TimeInterval = 2.8
    public static let warmInstantThreshold: TimeInterval = 0.2
    public static let warmScrimMax: TimeInterval = 0.32

    // Legacy aliases
    public static let coldLoaderMax: TimeInterval = coldLaunchBudget
    public static let warmLoaderMax: TimeInterval = warmLaunchBudget
    public static let minimumWarmup: TimeInterval = warmOverlayMin
    public static let contentProbeWindow: TimeInterval = coldLaunchBudget
    public static let contentProbeMinScore = minimumContentScore
    public static let minimumMediaCount = minimumContentScore
    public static let warm2OverlayMin: TimeInterval = warmOverlayMin
    public static let warm2OverlayMax: TimeInterval = warmLaunchBudget
    public static let warm3LoaderMax: TimeInterval = warmLaunchBudget
    public static let warm3InstantThreshold: TimeInterval = warmInstantThreshold
    public static let warm3ScrimMax: TimeInterval = warmScrimMax
    public static let warm3OverlayFallback: TimeInterval = warmScrimMax
}
