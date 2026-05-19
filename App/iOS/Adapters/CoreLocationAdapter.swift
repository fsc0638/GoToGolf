import Foundation
import CoreLocation
import GolfCore

/// Turns CLLocation into GolfCore's framework-free `GeoCoordinate`, and
/// applies the tier chosen by `DynamicAccuracyController`.
final class CoreLocationAdapter: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((GeoCoordinate) -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.activityType = .fitness
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() { manager.stopUpdatingLocation() }

    func apply(tier: LocationAccuracyTier) {
        switch tier {
        case .coarse:   manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        case .standard: manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        case .precise:  manager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        onUpdate?(GeoCoordinate(latitude: l.coordinate.latitude,
                                longitude: l.coordinate.longitude))
    }
}
