import Foundation

/// Shared DTO used by the bundled / fetched scoring catalog. Geometry DTOs
/// were removed with the GPS layer — the MVP only needs scoring data.
struct TeeRatingDTO: Decodable {
    let courseRating: Double
    let slopeRating: Int
    var domain: TeeRating {
        TeeRating(courseRating: courseRating, slopeRating: slopeRating)
    }
}
