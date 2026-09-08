import Testing
import Foundation
import Amplify
@testable import Rep___Gym_Tracker

/// Unit tests for the pure, deterministic logic in `WorkoutService`.
@MainActor
struct WorkoutServiceTests {

    // MARK: - Helpers

    /// A workout stored on a specific "yyyy-MM-dd" (as Amplify stores it).
    private func workout(_ dateString: String, _ exercises: [CompletedExercise] = []) throws -> Workout {
        Workout(date: try Temporal.Date(iso8601String: dateString), name: "Test", exercises: exercises)
    }

    /// A workout `daysAgo` days before today (local calendar).
    private func workout(daysAgo: Int) throws -> Workout {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        let dateString = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        return try workout(dateString)
    }

    private func exercise(_ name: String, weight: Double, reps: Int = 5) -> CompletedExercise {
        CompletedExercise(name: name, emoji: "💪", sets: [CompletedSet(setNumber: 1, weight: weight, reps: reps)])
    }

    // MARK: - Personal records

    @Test func personalRecordsDedupeByNameCaseInsensitivelyKeepingHighest() throws {
        let workouts = [
            try workout("2026-09-01", [exercise("Pull Ups", weight: 100), exercise("Bench Press", weight: 200)]),
            try workout("2026-09-03", [exercise("pull ups", weight: 150)]) // same exercise, different casing
        ]

        let prs = WorkoutService.personalRecords(from: workouts)

        // "Pull Ups" / "pull ups" collapse into one record.
        #expect(prs.count == 2)
        let pullUps = prs.first { $0.exercise.lowercased() == "pull ups" }
        #expect(pullUps?.weight == 150)
        // Sorted heaviest first.
        #expect(prs.first?.exercise == "Bench Press")
    }

    @Test func personalRecordsIgnoreZeroWeightSets() throws {
        let prs = WorkoutService.personalRecords(from: [try workout("2026-09-01", [exercise("Plank", weight: 0)])])
        #expect(prs.isEmpty)
    }

    // MARK: - Timezone-safe day

    @Test func loggedDayReturnsTheStoredCalendarDay() throws {
        // Regression test: stored dates are UTC-anchored; loggedDay must report
        // the day the user picked regardless of the device timezone.
        let day = WorkoutService.loggedDay(of: try workout("2026-09-05"))
        let c = Calendar.current.dateComponents([.year, .month, .day], from: day)
        #expect(c.year == 2026)
        #expect(c.month == 9)
        #expect(c.day == 5)
    }

    // MARK: - Streak

    @Test func currentStreakCountsConsecutiveDays() throws {
        #expect(WorkoutService.currentStreak(from: []) == 0)

        // Today, yesterday, day before → 3.
        let threeInARow = [try workout(daysAgo: 0), try workout(daysAgo: 1), try workout(daysAgo: 2)]
        #expect(WorkoutService.currentStreak(from: threeInARow) == 3)

        // Today and two days ago, with a gap yesterday → only today counts.
        let withGap = [try workout(daysAgo: 0), try workout(daysAgo: 2)]
        #expect(WorkoutService.currentStreak(from: withGap) == 1)

        // No workout today but yesterday + the day before → streak is still alive.
        let endingYesterday = [try workout(daysAgo: 1), try workout(daysAgo: 2)]
        #expect(WorkoutService.currentStreak(from: endingYesterday) == 2)
    }

    // MARK: - Editable → completed conversion

    @Test func completedExercisesExpandPerSetCustomValues() {
        var editable = EditableExercise(name: "Squat", sets: 3, reps: 5, weight: 100)
        editable.customWeights = [100, 110, 120]
        editable.customReps = [5, 5, 3]

        let completed = WorkoutService.completedExercises(from: [editable])

        #expect(completed.count == 1)
        let sets = completed[0].sets ?? []
        #expect(sets.count == 3)
        #expect(sets[1].weight == 110)
        #expect(sets[2].reps == 3)
    }
}
