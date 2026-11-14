import XCTest
@testable import Rondo

/// De programmaregel is het hart van de app en moet exact blijven:
/// per ronde elke oefening werk + rust, tussen rondes een optionele reset,
/// en **de laatste rust vervalt**.
final class WorkoutProgramTests: XCTestCase {

    /// De maat waar alles aan hangt: 60 s werk / 90 s rust / 1 oefening /
    /// 8 rondes is precies 18:30 — 8 × 60 + 7 × 90 = 1110 s.
    func testDefaultWorkoutIsExactlyEighteenThirty() {
        let workout = Workout(work: 60, rest: 90, exercises: 1, rounds: 8, resetRound: 0)
        XCTAssertEqual(workout.totalDuration, 1110)
        XCTAssertEqual(Workout.clock(workout.totalDuration), "18:30")
    }

    func testStandaardwaardenZijnDieTraining() {
        XCTAssertEqual(Workout().totalDuration, 1110)
    }

    func testFinalRestIsDropped() {
        let workout = Workout(work: 60, rest: 90, exercises: 1, rounds: 8, resetRound: 0)
        let segments = workout.segments
        XCTAssertEqual(segments.count, 15)            // 8 werk + 7 rust
        XCTAssertEqual(segments.first?.phase, .work)
        XCTAssertEqual(segments.last?.phase, .work)
        XCTAssertEqual(segments.filter { $0.phase == .work }.count, 8)
        XCTAssertEqual(segments.filter { $0.phase == .rest }.count, 7)
    }

    func testEveryExerciseGetsWorkAndRestWithinARound() {
        let workout = Workout(work: 30, rest: 15, exercises: 3, rounds: 2, resetRound: 0)
        let segments = workout.segments
        // 2 rondes × 3 oefeningen × (werk + rust) = 12, min de laatste rust.
        XCTAssertEqual(segments.count, 11)
        XCTAssertEqual(segments.filter { $0.phase == .work }.count, 6)
        XCTAssertEqual(segments.filter { $0.phase == .rest }.count, 5)
        XCTAssertEqual(workout.totalDuration, 6 * 30 + 5 * 15)
        XCTAssertEqual(segments.map(\.exercise).prefix(6).map { $0 }, [1, 1, 2, 2, 3, 3])
        XCTAssertEqual(segments.last?.round, 2)
    }

    func testRoundResetSitsBetweenRoundsAndNeverAtTheEnd() {
        let workout = Workout(work: 40, rest: 20, exercises: 1, rounds: 3, resetRound: 60)
        let segments = workout.segments
        // werk rust reset werk rust reset werk  — de reset na de laatste
        // ronde vervalt samen met de laatste rust.
        XCTAssertEqual(segments.map(\.phase), [.work, .rest, .reset, .work, .rest, .reset, .work])
        XCTAssertEqual(workout.totalDuration, 3 * 40 + 2 * 20 + 2 * 60)
        XCTAssertNotEqual(segments.last?.phase, .reset)
    }

    func testZeroRestLeavesOnlyWork() {
        let workout = Workout(work: 45, rest: 0, exercises: 2, rounds: 4, resetRound: 0)
        let segments = workout.segments
        XCTAssertEqual(segments.count, 8)
        XCTAssertTrue(segments.allSatisfy { $0.phase == .work })
        XCTAssertEqual(workout.totalDuration, 8 * 45)
    }

    func testSingleRoundSingleExerciseIsOneWorkInterval() {
        let workout = Workout(work: 90, rest: 30, exercises: 1, rounds: 1, resetRound: 30)
        XCTAssertEqual(workout.segments.map(\.phase), [.work])
        XCTAssertEqual(workout.totalDuration, 90)
    }

    func testFieldsClampToTheirRange() {
        var workout = Workout()
        workout[.rounds] = 500
        XCTAssertEqual(workout.rounds, 99)
        workout[.work] = 0
        XCTAssertEqual(workout.work, 1)
        workout[.rest] = -10
        XCTAssertEqual(workout.rest, 0)
    }

    func testClockFormatting() {
        XCTAssertEqual(Workout.clock(0), "00:00")
        XCTAssertEqual(Workout.clock(59), "00:59")
        XCTAssertEqual(Workout.clock(1110), "18:30")
        XCTAssertEqual(Workout.clock(3600), "1:00:00")
    }

    /// De ring leest het programma uit dezelfde bron; een boog per interval.
    func testSegmentsAndRoundNumbering() {
        let workout = Workout(work: 20, rest: 10, exercises: 2, rounds: 2, resetRound: 0)
        let rounds = workout.segments.map(\.round)
        XCTAssertEqual(rounds.first, 1)
        XCTAssertEqual(rounds.last, 2)
        XCTAssertEqual(Set(rounds), [1, 2])
    }
}
