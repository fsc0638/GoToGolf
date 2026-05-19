import GolfCore

// Placeholder course for the skeleton; real builds load via IGolfClient.
extension Course {
    static var demo: Course {
        let holes = (1...18).map { n -> Hole in
            let tee = GeoCoordinate(latitude: 25.0 + Double(n) * 0.001, longitude: 121.0)
            let green = GreenPoints(
                front:  GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0013),
                center: GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0015),
                back:   GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0017)
            )
            return Hole(id: n, par: 4, strokeIndex: n, tee: tee, green: green)
        }
        return Course(
            id: "DEMO", name: "Demo Golf Club", holes: holes,
            ratings: [.white: TeeRating(courseRating: 70.0, slopeRating: 120)]
        )
    }
}
