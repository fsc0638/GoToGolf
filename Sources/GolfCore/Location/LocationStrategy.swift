import Foundation

/// Which device should own GPS during the round.
public enum LocationStrategy: String, Equatable, Sendable {
    /// Watch GPS off; iPhone fixes location and pushes it over WCSession.
    /// Saves the watch ~60% of its location power budget.
    case bluetoothProxy
    /// iPhone out of Bluetooth range; the watch must use its own GPS chip.
    case watchGPS
}

/// Decides whether the watch can delegate positioning to the phone.
public struct ProxyLocationDecider: Sendable {
    /// RSSI at or above this (dBm) means the phone is close enough
    /// (e.g. in a pocket) to trust as a stable proxy. Hysteresis avoids
    /// flapping at the boundary.
    public let connectThreshold: Int
    public let disconnectThreshold: Int

    public init(connectThreshold: Int = -70, disconnectThreshold: Int = -80) {
        self.connectThreshold = connectThreshold
        self.disconnectThreshold = disconnectThreshold
    }

    /// - Parameters:
    ///   - rssi: latest watch↔phone RSSI in dBm (nil = no link).
    ///   - current: the strategy currently in effect (for hysteresis).
    public func strategy(rssi: Int?, current: LocationStrategy) -> LocationStrategy {
        guard let rssi else { return .watchGPS }
        switch current {
        case .watchGPS:
            return rssi >= connectThreshold ? .bluetoothProxy : .watchGPS
        case .bluetoothProxy:
            return rssi <= disconnectThreshold ? .watchGPS : .bluetoothProxy
        }
    }
}
