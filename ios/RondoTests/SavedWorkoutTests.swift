import XCTest
@testable import Rondo

/// Bewaarde trainingen moeten een taalwissel overleven: de naam volgt de taal
/// van nu, en lijsten van vóór het datumveld blijven laden.
final class SavedWorkoutTests: XCTestCase {
    func testOldSavedListWithoutDateStillLoads() throws {
        let entry = SavedWorkout(name: "22 nov 22:32", workout: Workout())
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as! [String: Any]
        json.removeValue(forKey: "savedAt")
        let data = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(SavedWorkout.self, from: data)
        XCTAssertNil(decoded.savedAt)
        XCTAssertEqual(decoded.displayName, "22 nov 22:32")
    }

    func testNameFollowsTheLanguage() {
        var parts = DateComponents()
        (parts.year, parts.month, parts.day, parts.hour, parts.minute) = (2026, 11, 22, 22, 32)
        let date = Calendar(identifier: .gregorian).date(from: parts)!

        let english = SavedWorkout.displayName(for: date, locale: Locale(identifier: "en_US"))
        let dutch = SavedWorkout.displayName(for: date, locale: Locale(identifier: "nl_NL"))
        XCTAssertTrue(english.contains("Nov"), english)
        XCTAssertTrue(dutch.contains("nov"), dutch)
        XCTAssertTrue(english.contains("22:32") && dutch.contains("22:32"))
    }
}
