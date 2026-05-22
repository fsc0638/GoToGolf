import Foundation
import GolfCore

/// Scoring-only catalog: bundled Taiwan seed + user-created courses stored
/// locally. Both share the same `ScoringCatalogParser` schema so user
/// additions read identically to seeded ones.
enum CourseCatalog {
    private static let bundleResource = "courses_taiwan"
    private static let userDefaultsKey = "GoToGolf.userCatalog.v1"
    private static let parOverridesKey = "GoToGolf.courseParOverrides.v1"

    // MARK: - Combined listing

    static func entries() -> [CourseListing] {
        let overrides = parOverrides()
        return (bundled() + userAdded()).map { applyOverride(overrides, to: $0) }
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
        clearParOverride(courseID: id)   // drop the now-orphaned override
        if let encoded = encode(current) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            return true
        }
        return false
    }

    // MARK: - Per-hole par overrides
    //
    // The bundled seed ships a STANDARD par template (see
    // tools/gen_courses_taiwan.py) because Taiwan clubs don't publish full
    // scorecards. Players correct a course against the real card here; the
    // override is keyed by course id and layered on top in `entries()`.

    private static func parOverrides() -> [String: [Int]] {
        guard let data = UserDefaults.standard.data(forKey: parOverridesKey),
              let dict = try? JSONDecoder().decode([String: [Int]].self, from: data)
        else { return [:] }
        return dict
    }

    /// Corrected per-hole pars for a course, if the player has edited it.
    static func parOverride(for courseID: String) -> [Int]? {
        parOverrides()[courseID]
    }

    /// Save corrected per-hole pars for any course (bundled or user-added).
    /// `pars.count` must match the course's hole count to take effect.
    static func updatePars(courseID: String, pars: [Int]) {
        var all = parOverrides()
        all[courseID] = pars
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: parOverridesKey)
        }
    }

    private static func clearParOverride(courseID: String) {
        var all = parOverrides()
        guard all.removeValue(forKey: courseID) != nil else { return }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: parOverridesKey)
        }
    }

    /// Rebuild a listing's course with overridden pars when one exists and
    /// its hole count lines up; otherwise return the listing untouched.
    private static func applyOverride(_ overrides: [String: [Int]],
                                      to listing: CourseListing) -> CourseListing {
        guard let pars = overrides[listing.course.id],
              pars.count == listing.course.holes.count
        else { return listing }
        let c = listing.course
        let holes = zip(c.holes, pars).map { hole, par in
            Hole(id: hole.id, par: par, strokeIndex: hole.strokeIndex)
        }
        return CourseListing(
            course: Course(id: c.id, name: c.name, holes: holes, ratings: c.ratings),
            region: listing.region)
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
