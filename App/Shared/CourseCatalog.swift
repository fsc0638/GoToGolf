import Foundation
import GolfCore

/// Scoring-only catalog: bundled Taiwan seed + user-created courses stored
/// locally. Both share the same `ScoringCatalogParser` schema so user
/// additions read identically to seeded ones.
enum CourseCatalog {
    private static let bundleResource = "courses_taiwan"
    private static let userDefaultsKey = "GoToGolf.userCatalog.v1"

    // MARK: - Combined listing

    static func entries() -> [CourseListing] {
        bundled() + userAdded()
    }

    // MARK: - Bundled (read-only)

    private static func bundled() -> [CourseListing] {
        guard let url = Bundle.main.url(forResource: bundleResource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? ScoringCatalogParser.catalog(fromCatalogJSON: data)
        else { return [] }
        return list
    }

    // MARK: - User-added (persisted to UserDefaults)

    private static func userAdded() -> [CourseListing] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let list = try? ScoringCatalogParser.catalog(fromCatalogJSON: data)
        else { return [] }
        return list
    }

    /// Add a user-created course to the local catalog.
    @discardableResult
    static func addUserCourse(name: String, region: String?,
                              pars: [Int]) -> CourseListing? {
        let id = "USER-\(UUID().uuidString.prefix(8))"
        let holesJSON = pars.enumerated()
            .map { #"{ "number": \#($0.offset + 1), "par": \#($0.element) }"# }
            .joined(separator: ",")
        let entry = """
        { "id": "\(id)", "name": "\(name)",
          "region": \(region.map { "\"\($0)\"" } ?? "null"),
          "holes": [\(holesJSON)],
          "ratings": { "white": { "courseRating": \(Double(pars.reduce(0, +))), "slopeRating": 113 } }
        }
        """
        guard let courseListing = try? ScoringCatalogParser.listing(
            fromCourseJSON: Data(entry.utf8)) else { return nil }

        var current = userAdded()
        current.append(courseListing)
        if let encoded = encode(current) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        return courseListing
    }

    /// Whether a given course ID came from the user-added catalog (vs. the
    /// bundled seed). Used by the picker to gate destructive actions.
    static func isUserAdded(_ courseID: String) -> Bool {
        courseID.hasPrefix("USER-")
    }

    /// Remove a user-added course by id. No-op for bundled seed courses.
    @discardableResult
    static func deleteUserCourse(id: String) -> Bool {
        guard isUserAdded(id) else { return false }
        var current = userAdded()
        guard let idx = current.firstIndex(where: { $0.course.id == id })
        else { return false }
        current.remove(at: idx)
        if let encoded = encode(current) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            return true
        }
        return false
    }

    private static func encode(_ list: [CourseListing]) -> Data? {
        // Re-serialise back to the catalog schema for persistence.
        let dicts = list.map { l -> [String: Any] in
            var d: [String: Any] = [
                "id": l.course.id,
                "name": l.course.name,
                "holes": l.course.holes.map { ["number": $0.id, "par": $0.par] }
            ]
            if let r = l.region { d["region"] = r }
            var ratings: [String: Any] = [:]
            for (tee, r) in l.course.ratings {
                ratings[tee.rawValue] = [
                    "courseRating": r.courseRating,
                    "slopeRating": r.slopeRating
                ]
            }
            if !ratings.isEmpty { d["ratings"] = ratings }
            return d
        }
        return try? JSONSerialization.data(withJSONObject: dicts)
    }
}
