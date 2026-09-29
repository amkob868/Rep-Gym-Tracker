import Testing
import Foundation
import Amplify
@testable import Rep___Gym_Tracker

@MainActor
struct ExerciseCatalogTests {

    // MARK: - Canonical key

    @Test func canonicalKeyCollapsesCaseWhitespaceAndAliases() {
        let key = ExerciseCatalog.canonicalKey(for: "Bench Press")
        #expect(key == "bench-press")
        #expect(ExerciseCatalog.canonicalKey(for: "bench press") == key)
        #expect(ExerciseCatalog.canonicalKey(for: "  BENCH   PRESS ") == key)
        #expect(ExerciseCatalog.canonicalKey(for: "BP") == key)          // alias
        #expect(ExerciseCatalog.canonicalKey(for: "flat bench") == key)  // alias
    }

    @Test func customExercisesNormalizeConsistently() {
        let a = ExerciseCatalog.canonicalKey(for: "My Custom Thing!")
        let b = ExerciseCatalog.canonicalKey(for: "my  custom   thing")
        #expect(a == b)
        #expect(a == "my custom thing")
        // A custom name shouldn't collide with a catalog id.
        #expect(a != ExerciseCatalog.canonicalKey(for: "Bench Press"))
    }

    // MARK: - Lookup & search

    @Test func lookupResolvesAliases() {
        #expect(ExerciseCatalog.lookup(name: "incline bench")?.id == "incline-bench-press")
        #expect(ExerciseCatalog.lookup(name: "rdl")?.id == "romanian-deadlift")
        #expect(ExerciseCatalog.lookup(name: "totally made up") == nil)
    }

    @Test func searchRanksPrefixMatchesFirst() {
        let results = ExerciseCatalog.search("bench")
        #expect(results.contains { $0.id == "bench-press" })
        #expect(results.first?.name.lowercased().contains("bench") == true)
    }

    // MARK: - Muscle group resolution

    @Test func muscleGroupPrefersCatalog() {
        #expect(MuscleGroup.forExercise(named: "Back Squat") == .legs)
        #expect(MuscleGroup.forExercise(named: "rdl") == .legs)         // alias → catalog
        #expect(MuscleGroup.forExercise(named: "Overhead Press") == .shoulders)
    }

    // MARK: - Integration with PRs

    @Test func personalRecordsGroupAliasesTogether() throws {
        func workout(_ dateString: String, _ name: String, _ weight: Double) throws -> Workout {
            Workout(
                date: try Temporal.Date(iso8601String: dateString),
                name: "W",
                exercises: [CompletedExercise(name: name, emoji: "💪", sets: [CompletedSet(setNumber: 1, weight: weight, reps: 5)])]
            )
        }
        let workouts = [
            try workout("2026-01-01", "Bench Press", 185),
            try workout("2026-02-01", "bench press", 200),
            try workout("2026-03-01", "BP", 225)
        ]
        let prs = WorkoutService.personalRecords(from: workouts)
        // All three variants collapse into a single bench-press record.
        #expect(prs.count == 1)
        #expect(prs.first?.weight == 225)
    }
}
