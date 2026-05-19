import Foundation

public struct MotionSample: Sendable {
    /// Total acceleration magnitude in g (1 g ≈ 9.81 m/s²).
    public let g: Double
    public let timestamp: TimeInterval

    public init(g: Double, timestamp: TimeInterval) {
        self.g = g
        self.timestamp = timestamp
    }
}

public struct SwingEvent: Equatable, Sendable {
    public let timestamp: TimeInterval
    /// 0...1 — how cleanly the peak/trough/displacement pattern matched.
    public let confidence: Double
}

/// Detects a real golf stroke and rejects the false positives that plague
/// competitors (idle hand movement while waiting, practice swings).
///
/// Three gates, all required:
///   1. Acceleration peak above `peakG` (downswing into impact).
///   2. A sharp trough below `troughG` within `swingWindow` (follow-through).
///   3. GPS displacement over `minDisplacement` m afterward — the ball (and
///      player) actually moved. A practice swing fails this gate.
public final class SwingDetector {
    public let peakG: Double
    public let troughG: Double
    public let swingWindow: TimeInterval
    public let confirmWindow: TimeInterval
    public let minDisplacementMeters: Double

    private enum Phase {
        case idle
        case peaked(peakG: Double, at: TimeInterval)
        case awaitingDisplacement(at: TimeInterval, quality: Double)
    }
    private var phase: Phase = .idle

    public init(
        peakG: Double = 3.5,
        troughG: Double = 0.5,
        swingWindow: TimeInterval = 1.0,
        confirmWindow: TimeInterval = 6.0,
        minDisplacementMeters: Double = 5.0
    ) {
        self.peakG = peakG
        self.troughG = troughG
        self.swingWindow = swingWindow
        self.confirmWindow = confirmWindow
        self.minDisplacementMeters = minDisplacementMeters
    }

    public var isAwaitingDisplacementConfirmation: Bool {
        if case .awaitingDisplacement = phase { return true }
        return false
    }

    /// Feed one accelerometer sample. Returns a *tentative* swing the moment
    /// the peak→trough pattern completes; it still needs `confirm(...)`.
    @discardableResult
    public func feed(_ sample: MotionSample) -> SwingEvent? {
        switch phase {
        case .idle:
            if sample.g >= peakG {
                phase = .peaked(peakG: sample.g, at: sample.timestamp)
            }
        case .peaked(let peak, let at):
            if sample.timestamp - at > swingWindow {
                phase = .idle                       // window expired, reset
            } else if sample.g <= troughG {
                // Cleaner if the peak was strong and the trough is deep.
                let peakQuality = min(1.0, (peak - peakG) / peakG + 0.5)
                let troughQuality = min(1.0, (troughG - sample.g) / troughG + 0.5)
                let quality = (peakQuality + troughQuality) / 2
                phase = .awaitingDisplacement(at: sample.timestamp, quality: quality)
                return SwingEvent(timestamp: sample.timestamp, confidence: quality * 0.6)
            }
        case .awaitingDisplacement(let at, _):
            if sample.timestamp - at > confirmWindow {
                phase = .idle                       // never confirmed, drop it
            }
        }
        return nil
    }

    /// Confirm with GPS displacement observed after the tentative swing.
    /// Only a confirmed event should increment the scorecard.
    public func confirm(displacementMeters: Double, at timestamp: TimeInterval) -> SwingEvent? {
        guard case .awaitingDisplacement(let at, let quality) = phase else { return nil }
        guard timestamp - at <= confirmWindow else { phase = .idle; return nil }
        guard displacementMeters >= minDisplacementMeters else { return nil }

        // More displacement = more confidence the ball was actually struck.
        let displacementBoost = min(0.4, displacementMeters / 100)
        phase = .idle
        return SwingEvent(timestamp: timestamp, confidence: min(1.0, quality * 0.6 + displacementBoost))
    }

    public func reset() { phase = .idle }
}
