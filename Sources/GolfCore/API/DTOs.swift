import Foundation

// MARK: - Shared geometry

struct CoordinateDTO: Decodable {
    let lat: Double
    let lng: Double
    var domain: GeoCoordinate { GeoCoordinate(latitude: lat, longitude: lng) }
}

extension Array where Element == CoordinateDTO {
    /// Approximate hazard marker: arithmetic mean of the polygon vertices.
    /// Good enough for a "there's a bunker here" pin; the renderer keeps the
    /// full polygon for drawing.
    var centroid: GeoCoordinate? {
        guard !isEmpty else { return nil }
        let n = Double(count)
        let lat = reduce(0) { $0 + $1.lat } / n
        let lng = reduce(0) { $0 + $1.lng } / n
        return GeoCoordinate(latitude: lat, longitude: lng)
    }
}

struct GreenDTO: Decodable {
    let front: CoordinateDTO
    let center: CoordinateDTO
    let back: CoordinateDTO
    var domain: GreenPoints {
        GreenPoints(front: front.domain, center: center.domain, back: back.domain)
    }
}

struct TeeRatingDTO: Decodable {
    let courseRating: Double
    let slopeRating: Int
    var domain: TeeRating {
        TeeRating(courseRating: courseRating, slopeRating: slopeRating)
    }
}

// MARK: - iGolf Connect: full course layout

struct HazardDTO: Decodable {
    let type: String
    let polygon: [CoordinateDTO]
}

struct HoleLayoutDTO: Decodable {
    let number: Int
    let par: Int
    let strokeIndex: Int
    let tee: CoordinateDTO
    let green: GreenDTO
    let hazards: [HazardDTO]?
    let fairwayPolygon: [CoordinateDTO]?
    let cartPath: [CoordinateDTO]?

    var domain: Hole {
        let hazardPoints = (hazards ?? []).compactMap { $0.polygon.centroid }
        return Hole(
            id: number,
            par: par,
            strokeIndex: strokeIndex,
            tee: tee.domain,
            green: green.domain,
            hazards: hazardPoints
        )
    }
}

struct CourseLayoutDTO: Decodable {
    let courseId: String
    let name: String
    let ratings: [String: TeeRatingDTO]
    let holes: [HoleLayoutDTO]

    func toDomain() -> Course {
        var mapped: [TeeBox: TeeRating] = [:]
        for (key, value) in ratings {
            if let box = TeeBox(rawValue: key) { mapped[box] = value.domain }
        }
        return Course(
            id: courseId,
            name: name,
            holes: holes.map(\.domain).sorted { $0.id < $1.id },
            ratings: mapped
        )
    }
}

// MARK: - iGolf Simple GPS: lightweight key points (watch / offline)

struct SimpleHoleDTO: Decodable {
    let number: Int
    let par: Int
    let strokeIndex: Int
    let tee: CoordinateDTO
    let green: GreenDTO
    /// Up to 4 key hazard centers — already points, no polygons.
    let hazards: [CoordinateDTO]?

    var domain: Hole {
        Hole(
            id: number,
            par: par,
            strokeIndex: strokeIndex,
            tee: tee.domain,
            green: green.domain,
            hazards: (hazards ?? []).map(\.domain)
        )
    }
}

struct SimpleGPSCourseDTO: Decodable {
    let courseId: String
    let name: String
    let ratings: [String: TeeRatingDTO]
    let holes: [SimpleHoleDTO]

    func toDomain() -> Course {
        var mapped: [TeeBox: TeeRating] = [:]
        for (key, value) in ratings {
            if let box = TeeBox(rawValue: key) { mapped[box] = value.domain }
        }
        return Course(
            id: courseId,
            name: name,
            holes: holes.map(\.domain).sorted { $0.id < $1.id },
            ratings: mapped
        )
    }
}

// MARK: - OpenWeatherMap (units=metric)

struct OWMWindDTO: Decodable {
    let speed: Double
    let deg: Double
    let gust: Double?
}

struct OWMMainDTO: Decodable {
    let temp: Double
    let humidity: Int
    let pressure: Int
}

struct OWMResponseDTO: Decodable {
    let wind: OWMWindDTO
    let main: OWMMainDTO
    let name: String?

    var domain: WeatherSnapshot {
        WeatherSnapshot(
            windSpeedMS: wind.speed,
            windFromDegrees: wind.deg,
            gustMS: wind.gust,
            temperatureC: main.temp,
            humidity: main.humidity,
            pressureHPa: main.pressure
        )
    }
}
