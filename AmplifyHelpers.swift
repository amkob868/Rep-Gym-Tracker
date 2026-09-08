import Amplify
import AWSPluginsCore
import Foundation

// Helper functions to work around Sendable issues with Amplify models

// Wrapper to fetch workouts without Sendable issues
@available(iOS 13.0, *)
nonisolated func fetchWorkoutsSafely(limit: Int) async throws -> [Workout] {
    let request = GraphQLRequest<Workout>.list(Workout.self, limit: limit)
    let result = try await Amplify.API.query(request: request)
    
    switch result {
    case .success(let workouts):
        return Array(workouts)
    case .failure(let error):
        throw error
    }
}

// Wrapper to save workouts without Sendable issues
@available(iOS 13.0, *)
nonisolated func saveWorkoutSafely(_ workout: Workout) async throws -> Workout {
    let result = try await Amplify.API.mutate(request: .create(workout))
    
    switch result {
    case .success(let savedWorkout):
        return savedWorkout
    case .failure(let error):
        throw error
    }
}
