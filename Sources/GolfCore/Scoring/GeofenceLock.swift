import Foundation

/// The safe-gesture payload required to override the lock manually
/// (two-finger long-press + swipe). The UI only constructs this when both
/// conditions are genuinely met.
public struct SafeGesture: Sendable {
    public let twoFingerLongPress: Bool
    public let swipe: Bool
    public init(twoFingerLongPress: Bool, swipe: Bool) {
        self.twoFingerLongPress = twoFingerLongPress
        self.swipe = swipe
    }
    public var isValid: Bool { twoFingerLongPress && swipe }
}

public enum AdvanceResult: Equatable, Sendable {
    case advanced(toHole: Int)
    case blockedStillLocked
    case rejectedInvalidGesture
    case noNextHole
}

/// Stops the scorecard from auto-jumping holes (the iCaddie bug).
///
/// The hole only auto-advances after the player is inside the *next* tee's
/// geofence continuously for `dwellRequirement` seconds. A brush of the
/// screen or a rain drop can't change holes. Manual change demands a valid
/// two-finger long-press + swipe.
public final class GeofenceLock {
    public let radiusMeters: Double
    public let dwellRequirement: TimeInterval

    public private(set) var currentHole: Int
    private let teeByHole: [Int: GeoCoordinate]
    private let holeNumbers: [Int]

    private var dwellStart: TimeInterval?

    public init(
        currentHole: Int = 1,
        tees: [Int: GeoCoordinate],
        radiusMeters: Double = 30,
        dwellRequirement: TimeInterval = 30
    ) {
        self.currentHole = currentHole
        self.teeByHole = tees
        self.holeNumbers = tees.keys.sorted()
        self.radiusMeters = radiusMeters
        self.dwellRequirement = dwellRequirement
    }

    private var nextHole: Int? {
        guard let idx = holeNumbers.firstIndex(of: currentHole),
              idx + 1 < holeNumbers.count else { return nil }
        return holeNumbers[idx + 1]
    }

    /// `true` while the player has not satisfied the dwell requirement
    /// inside the next tee's geofence.
    public var isLocked: Bool { dwellStart == nil }

    /// Feed the latest position. Tracks continuous dwell in the next tee box.
    public func update(coordinate: GeoCoordinate, now: TimeInterval) {
        guard let next = nextHole, let nextTee = teeByHole[next] else {
            dwellStart = nil
            return
        }
        let inside = coordinate.distanceMeters(to: nextTee) <= radiusMeters
        if inside {
            if dwellStart == nil { dwellStart = now }
        } else {
            dwellStart = nil                    // left the zone, restart dwell
        }
    }

    private func dwellSatisfied(now: TimeInterval) -> Bool {
        guard let start = dwellStart else { return false }
        return now - start >= dwellRequirement
    }

    /// Auto-advance: only when the geofence dwell is satisfied.
    @discardableResult
    public func tryAutoAdvance(now: TimeInterval) -> AdvanceResult {
        guard let next = nextHole else { return .noNextHole }
        guard dwellSatisfied(now: now) else { return .blockedStillLocked }
        currentHole = next
        dwellStart = nil
        return .advanced(toHole: next)
    }

    /// Manual override via the safe gesture, bypassing the geofence.
    @discardableResult
    public func manualAdvance(gesture: SafeGesture) -> AdvanceResult {
        guard gesture.isValid else { return .rejectedInvalidGesture }
        guard let next = nextHole else { return .noNextHole }
        currentHole = next
        dwellStart = nil
        return .advanced(toHole: next)
    }

    /// Manual jump to an arbitrary hole (e.g. correcting a mistake) — still
    /// gated by the safe gesture.
    @discardableResult
    public func manualJump(to hole: Int, gesture: SafeGesture) -> AdvanceResult {
        guard gesture.isValid else { return .rejectedInvalidGesture }
        guard teeByHole[hole] != nil else { return .noNextHole }
        currentHole = hole
        dwellStart = nil
        return .advanced(toHole: hole)
    }
}
