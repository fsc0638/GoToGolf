import Foundation

/// Planning model for Apple Watch battery over a round. Coefficients are
/// engineering estimates (NOT device-measured) chosen to match the spec's
/// stated savings — bluetooth proxy cuts location power ~60%, the AOD
/// minimal layer cuts screen power ~20%. Its job is to turn the Phase-1
/// KPI ("GPS mode, 4.5 h, > 45% remaining") into an automated regression
/// guard; it does not replace on-device measurement.
public struct PowerBudgetEstimator: Sendable {

    // %/hour drain components.
    public var idlePerHour: Double = 3.0
    public var screenNormalPerHour: Double = 4.5
    public var aodScreenFactor: Double = 0.8          // AOD minimal layer −20%
    public var watchGPSPerHour: Double = 10.0
    public var proxyLocationFactor: Double = 0.4      // bluetooth proxy −60%
    public var precisePremiumPerHour: Double = 3.0    // best-accuracy near green

    public init() {}

    public func drainPerHour(
        strategy: LocationStrategy,
        aodOptimized: Bool,
        preciseFraction: Double
    ) -> Double {
        let screen = screenNormalPerHour * (aodOptimized ? aodScreenFactor : 1.0)
        let locationBase = watchGPSPerHour
            * (strategy == .bluetoothProxy ? proxyLocationFactor : 1.0)
        let precise = precisePremiumPerHour * max(0, min(1, preciseFraction))
        return idlePerHour + screen + locationBase + precise
    }

    /// Estimated remaining battery %, clamped to [0, start].
    public func remainingPercent(
        durationHours: Double,
        strategy: LocationStrategy,
        aodOptimized: Bool,
        preciseFraction: Double,
        startPercent: Double = 100
    ) -> Double {
        let used = drainPerHour(
            strategy: strategy,
            aodOptimized: aodOptimized,
            preciseFraction: preciseFraction
        ) * max(0, durationHours)
        return max(0, min(startPercent, startPercent - used))
    }

    /// Phase-1 acceptance: a full 4.5 h round must leave > 45%.
    public func meetsPhase1KPI(
        strategy: LocationStrategy,
        aodOptimized: Bool,
        preciseFraction: Double
    ) -> Bool {
        remainingPercent(
            durationHours: 4.5,
            strategy: strategy,
            aodOptimized: aodOptimized,
            preciseFraction: preciseFraction
        ) > 45
    }
}
