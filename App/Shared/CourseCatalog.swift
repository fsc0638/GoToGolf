import Foundation
import GolfCore

struct CatalogEntry: Identifiable {
    let summary: CourseSummary
    let resource: String
    var id: String { summary.id }
}

/// Bundled course 圖資 (offline / no API key). Same JSON contract as
/// `IGolfClient`, decoded via `CourseLayoutParser`, so swapping to the live
/// iGolf feed later changes nothing downstream.
enum CourseCatalog {
    private static let resources = ["course_pinehill", "course_lakeside"]

    private static func data(for resource: String) -> Data? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json")
        else { return nil }
        return try? Data(contentsOf: url)
    }

    static func entries() -> [CatalogEntry] {
        resources.compactMap { name in
            guard let data = data(for: name),
                  let summary = try? CourseLayoutParser.summary(fromLayoutJSON: data)
            else { return nil }
            return CatalogEntry(summary: summary, resource: name)
        }
    }

    static func course(resource: String) -> Course? {
        guard let data = data(for: resource) else { return nil }
        return try? CourseLayoutParser.course(fromLayoutJSON: data)
    }
}
