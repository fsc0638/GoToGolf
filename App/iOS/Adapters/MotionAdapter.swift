import Foundation
import CoreMotion
import GolfCore

/// Streams accelerometer magnitude as GolfCore `MotionSample`s for the
/// tested `SwingDetector`.
final class MotionAdapter {
    var onSample: ((MotionSample) -> Void)?

    private let mm = CMMotionManager()
    private let queue = OperationQueue()

    func start() {
        guard mm.isAccelerometerAvailable else { return }
        mm.accelerometerUpdateInterval = 1.0 / 50.0
        mm.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let a = data?.acceleration else { return }
            let g = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
            self?.onSample?(MotionSample(g: g, timestamp: data!.timestamp))
        }
    }

    func stop() { mm.stopAccelerometerUpdates() }
}
