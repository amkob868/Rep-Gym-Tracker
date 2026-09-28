import Testing
import Foundation
import Amplify
@testable import Rep___Gym_Tracker

@MainActor
struct InsightEngineTests {

    // MARK: - Helpers

    private func workout(daysAgo: Int, _ exercises: [CompletedExercise]) throws -> Workout {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        let dateString = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        return Workout(date: try Temporal.Date(iso8601String: dateString), name: "W", exercises: exercises)
    }

    private func ex(_ name: String, _ weight: Double, reps: Int = 8) -> CompletedExercise {
        CompletedExercise(name: name, emoji: "💪", sets: [CompletedSet(setNumber: 1, weight: weight, reps: reps)])
    }

    // MARK: - Muscle group inference

    @Test func inferMapsExercisesToMuscleGroups() {
        #expect(MuscleGroup.infer(from: "Bench Press") == .chest)
        #expect(MuscleGroup.infer(from: "Incline Bench Press") == .chest)
        #expect(MuscleGroup.infer(from: "Back Squat") == .legs)   // movement wins over "back"
        #expect(MuscleGroup.infer(from: "Leg Press") == .legs)
        #expect(MuscleGroup.infer(from: "Lat Pulldown") == .back)
        #expect(MuscleGroup.infer(from: "Deadlift") == .back)
        #expect(MuscleGroup.infer(from: "Lateral Raise") == .shoulders)
        #expect(MuscleGroup.infer(from: "Bicep Curl") == .arms)
        #expect(MuscleGroup.infer(from: "Plank") == .core)
        #expect(MuscleGroup.infer(from: "Treadmill Run") == .cardio)
    }

    // MARK: - Rest / stale muscle group

    @Test func restInsightFlagsAMuscleGroupNotTrainedInTwoWeeks() throws {
        let workouts = [
            try workout(daysAgo: 21, [ex("Back Squat", 225)]),   // legs, 3 weeks ago
            try workout(daysAgo: 1, [ex("Bench Press", 185)])    // chest, recent
        ]
        let insights = InsightEngine.insights(from: workouts)
        let rest = insights.first { $0.kind == .rest }
        #expect(rest != nil)
        #expect(rest?.message.contains("legs") == true)
    }

    @Test func noRestInsightWhenEverythingIsRecent() throws {
        let workouts = [
            try workout(daysAgo: 2, [ex("Back Squat", 225)]),
            try workout(daysAgo: 1, [ex("Bench Press", 185)])
        ]
        #expect(InsightEngine.insights(from: workouts).contains { $0.kind == .rest } == false)
    }

    // MARK: - Plateau

    @Test func plateauInsightAfterThreeIdenticalSessions() throws {
        let workouts = [
            try workout(daysAgo: 6, [ex("Bench Press", 135, reps: 8)]),
            try workout(daysAgo: 4, [ex("Bench Press", 135, reps: 8)]),
            try workout(daysAgo: 2, [ex("Bench Press", 135, reps: 8)])
        ]
        let plateau = InsightEngine.insights(from: workouts).first { $0.kind == .plateau }
        #expect(plateau != nil)
        #expect(plateau?.message.contains("Bench Press") == true)
        #expect(plateau?.message.contains("140") == true)   // suggested +5 lb
    }

    @Test func noPlateauWhenWeightsVary() throws {
        let workouts = [
            try workout(daysAgo: 6, [ex("Bench Press", 135)]),
            try workout(daysAgo: 4, [ex("Bench Press", 140)]),
            try workout(daysAgo: 2, [ex("Bench Press", 145)])
        ]
        #expect(InsightEngine.insights(from: workouts).contains { $0.kind == .plateau } == false)
    }

    // MARK: - Progress

    @Test func progressInsightWhenWeightClimbs() throws {
        let workouts = [
            try workout(daysAgo: 21, [ex("Overhead Press", 95)]),
            try workout(daysAgo: 1, [ex("Overhead Press", 115)])
        ]
        let progress = InsightEngine.insights(from: workouts).first { $0.kind == .progress }
        #expect(progress != nil)
        #expect(progress?.message.contains("95") == true)
        #expect(progress?.message.contains("115") == true)
    }
}
