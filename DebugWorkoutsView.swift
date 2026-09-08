import SwiftUI
import Amplify

struct DebugWorkoutsView: View {
    @State private var workouts: [Workout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                ForgeTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView("Loading workouts...")
                                .padding()
                        }
                        
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        if workouts.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Text("No workouts found")
                                    .font(.headline)
                                Text("Complete a workout to see it here")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }
                        
                        ForEach(workouts, id: \.id) { workout in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(workout.name)
                                    .font(.headline)
                                Text("Date: \(workout.date)")
                                    .font(.subheadline)
                                Text("ID: \(workout.id)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if let exercises = workout.exercises {
                                    Text("Exercises: \(exercises.count)")
                                        .font(.caption)
                                    
                                    ForEach(exercises.indices, id: \.self) { index in
                                        if let exercise = exercises[index] {
                                            HStack {
                                                Text(exercise.emoji)
                                                Text(exercise.name)
                                                    .font(.caption)
                                                Text("(\(exercise.sets?.count ?? 0) sets)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.leading)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ForgeTheme.surface)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Debug: Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadWorkouts()
                    }
                }
            }
            .onAppear {
                loadWorkouts()
            }
        }
    }
    
    private func loadWorkouts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                Log.debug("🔍 [Debug] Fetching all workouts...")
                let workoutsArray = try await fetchWorkoutsSafely(limit: 100)
                
                await MainActor.run {
                    self.workouts = workoutsArray
                    self.isLoading = false
                }
                Log.debug("✅ [Debug] Loaded \(workoutsArray.count) workouts")
                for workout in workoutsArray {
                    Log.debug("   - \(workout.name) (\(workout.id))")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                Log.debug("❌ [Debug] Exception: \(error)")
            }
        }
    }
}

#Preview {
    DebugWorkoutsView()
}
