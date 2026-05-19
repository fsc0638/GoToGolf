import SwiftUI
import MapKit
import GolfCore

private extension GeoCoordinate {
    var cl: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct HazardPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

/// 2D vector hole map drawn from the parsed course 圖資 (tee, green,
/// hazards, live position) plus the glance-able distance. MapKit is used so
/// there is no Mapbox token dependency; the renderer can be swapped later.
struct CourseMapView: View {
    @ObservedObject var vm: RoundViewModel
    @State private var camera: MapCameraPosition = .automatic

    private var hazards: [HazardPin] {
        (vm.holeMap?.hazards ?? []).map { HazardPin(coordinate: $0.cl) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                if let m = vm.holeMap {
                    Annotation("發球台", coordinate: m.tee.cl) {
                        Image(systemName: "flag.fill").foregroundStyle(.blue)
                    }
                    Annotation("果嶺", coordinate: m.greenCenter.cl) {
                        Image(systemName: "circle.circle.fill")
                            .foregroundStyle(.green)
                    }
                    MapPolyline(coordinates: [m.tee.cl, m.greenCenter.cl])
                        .stroke(.yellow, lineWidth: 3)
                    ForEach(hazards) { h in
                        Marker("障礙", systemImage: "exclamationmark.triangle.fill",
                               coordinate: h.coordinate)
                            .tint(.red)
                    }
                    if let p = m.player {
                        Annotation("你", coordinate: p.cl) {
                            Image(systemName: "location.circle.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)

            HStack {
                Text("第 \(vm.currentHole) 洞")
                    .accessibilityIdentifier("map.hole")
                Spacer()
                Text("\(vm.distanceToCenter) 碼")
                    .font(.title3.weight(.bold))
                    .accessibilityIdentifier("map.distance")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .onChange(of: vm.holeMap) { _, snapshot in
            recenter(snapshot)
        }
        .onAppear { recenter(vm.holeMap) }
    }

    private func recenter(_ snapshot: HoleMapSnapshot?) {
        guard let m = snapshot else { return }
        let lat = (m.tee.latitude + m.greenCenter.latitude) / 2
        let lon = (m.tee.longitude + m.greenCenter.longitude) / 2
        camera = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)))
    }
}
