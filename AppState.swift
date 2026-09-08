import SwiftUI
import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    @Published var goal: Goal {
        didSet { UserDefaults.standard.set(goal.rawValue, forKey: "goal") }
    }
    
    @Published var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "streak") }
    }
    
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    @Published var weight: Int {
        didSet { UserDefaults.standard.set(weight, forKey: "weight") }
    }
    
    @Published var height: Int {
        didSet { UserDefaults.standard.set(height, forKey: "height") }
    }
    
    @Published var desiredWeight: Int {
        didSet { UserDefaults.standard.set(desiredWeight, forKey: "desiredWeight") }
    }

    /// Whether there's an active Cognito session. Source of truth for auth,
    /// set from the session check at launch and on sign in / sign out.
    /// Intentionally not persisted — the Cognito session is the real record.
    @Published var isSignedIn: Bool = false

    init() {
        // Load from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.streak = UserDefaults.standard.integer(forKey: "streak")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Champ"
        self.weight = UserDefaults.standard.integer(forKey: "weight") != 0 
            ? UserDefaults.standard.integer(forKey: "weight") 
            : 180
        self.height = UserDefaults.standard.integer(forKey: "height") != 0 
            ? UserDefaults.standard.integer(forKey: "height") 
            : 70
        self.desiredWeight = UserDefaults.standard.integer(forKey: "desiredWeight") != 0 
            ? UserDefaults.standard.integer(forKey: "desiredWeight") 
            : 170
        
        // Load goal
        if let goalString = UserDefaults.standard.string(forKey: "goal"),
           let savedGoal = Goal(rawValue: goalString) {
            self.goal = savedGoal
        } else {
            self.goal = .bulk
        }

        // `streak` is recomputed from real workout history (see
        // WorkoutService.currentStreak); the persisted value is just the
        // last-known number shown until the first fetch completes.
    }

    private let workoutPlans: [Goal: [WorkoutDay]] = [
        .bulk: WorkoutDay.bulkPlan,
        .cut: WorkoutDay.cutPlan,
        .recomp: WorkoutDay.recompPlan
    ]

    var todayName: String {
        currentWorkoutDay.name
    }

    var todayExercises: [Exercise] {
        currentWorkoutDay.exercises
    }

    private var currentWorkoutDay: WorkoutDay {
        let plan = workoutPlans[goal] ?? WorkoutDay.bulkPlan
        let dayIndex = Calendar.current.component(.weekday, from: .now)
        let normalizedIndex = (dayIndex + 5) % 7
        return plan[normalizedIndex]
    }
}

enum Goal: String, CaseIterable {
    case bulk = "Bulk"
    case cut = "Cut"
    case recomp = "Recomp"

    var description: String {
        switch self {
        case .bulk:
            return "Build muscle with a strength-first split."
        case .cut:
            return "Keep intensity high while trimming body fat."
        case .recomp:
            return "Balance strength and conditioning for lean gains."
        }
    }

    var color: Color {
        switch self {
        case .bulk:
            return ForgeTheme.accentBulk
        case .cut:
            return ForgeTheme.accentCut
        case .recomp:
            return ForgeTheme.accentRecomp
        }
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let emoji: String
}

// MARK: - Workout Set (for tracking)
struct WorkoutSet: Identifiable {
    let id = UUID()
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool = false
    var previousWeight: Double? = nil
    var previousReps: Int? = nil
}

// MARK: - Tracked Exercise
class TrackedExercise: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let emoji: String
    @Published var sets: [WorkoutSet]
    
    init(from exercise: Exercise) {
        self.name = exercise.name
        self.emoji = exercise.emoji
        self.sets = (1...exercise.sets).map { setNum in
            WorkoutSet(setNumber: setNum, weight: 0, reps: exercise.reps)
        }
    }
    
    // Initialize from a completed exercise (loading existing workout)
    init(from completedExercise: CompletedExercise) {
        self.name = completedExercise.name
        self.emoji = completedExercise.emoji
        self.sets = completedExercise.sets?.map { completedSet in
            WorkoutSet(
                setNumber: completedSet.setNumber,
                weight: completedSet.weight,
                reps: completedSet.reps,
                isCompleted: false, // Start fresh, not pre-completed
                previousWeight: completedSet.weight,
                previousReps: completedSet.reps
            )
        } ?? []
    }
}

private struct WorkoutDay {
    let name: String
    let exercises: [Exercise]

    static let bulkPlan: [WorkoutDay] = [
        WorkoutDay(name: "Push", exercises: [
            Exercise(name: "Bench Press", sets: 4, reps: 8, emoji: "🏋️"),
            Exercise(name: "Incline DB Press", sets: 3, reps: 10, emoji: "💪"),
            Exercise(name: "Shoulder Press", sets: 3, reps: 10, emoji: "🔥"),
            Exercise(name: "Cable Fly", sets: 3, reps: 12, emoji: "⚡")
        ]),
        WorkoutDay(name: "Pull", exercises: [
            Exercise(name: "Deadlift", sets: 4, reps: 5, emoji: "🦍"),
            Exercise(name: "Lat Pulldown", sets: 3, reps: 10, emoji: "🎯"),
            Exercise(name: "Barbell Row", sets: 3, reps: 8, emoji: "🚀"),
            Exercise(name: "Hammer Curl", sets: 3, reps: 12, emoji: "💥")
        ]),
        WorkoutDay(name: "Legs", exercises: [
            Exercise(name: "Back Squat", sets: 4, reps: 6, emoji: "🦵"),
            Exercise(name: "Romanian Deadlift", sets: 3, reps: 8, emoji: "⚙️"),
            Exercise(name: "Leg Press", sets: 3, reps: 12, emoji: "🔩"),
            Exercise(name: "Calf Raise", sets: 4, reps: 15, emoji: "📈")
        ]),
        WorkoutDay(name: "Upper", exercises: [
            Exercise(name: "Weighted Pull Up", sets: 4, reps: 6, emoji: "🧲"),
            Exercise(name: "Dips", sets: 3, reps: 10, emoji: "🏆"),
            Exercise(name: "Chest Supported Row", sets: 3, reps: 10, emoji: "🛡️"),
            Exercise(name: "Lateral Raise", sets: 3, reps: 15, emoji: "✨")
        ]),
        WorkoutDay(name: "Lower", exercises: [
            Exercise(name: "Front Squat", sets: 4, reps: 6, emoji: "🏗️"),
            Exercise(name: "Walking Lunge", sets: 3, reps: 12, emoji: "🚶"),
            Exercise(name: "Leg Curl", sets: 3, reps: 12, emoji: "🔁"),
            Exercise(name: "Seated Calf Raise", sets: 4, reps: 15, emoji: "📏")
        ]),
        WorkoutDay(name: "Recovery", exercises: [
            Exercise(name: "Light Cardio", sets: 1, reps: 20, emoji: "🫀"),
            Exercise(name: "Mobility Flow", sets: 2, reps: 10, emoji: "🧘"),
            Exercise(name: "Core Circuit", sets: 3, reps: 12, emoji: "🪨")
        ]),
        WorkoutDay(name: "Rest", exercises: [
            Exercise(name: "Walk", sets: 1, reps: 30, emoji: "🚶"),
            Exercise(name: "Stretch", sets: 2, reps: 10, emoji: "🤸")
        ])
    ]

    static let cutPlan: [WorkoutDay] = [
        WorkoutDay(name: "Metabolic Push", exercises: [
            Exercise(name: "Incline Bench", sets: 4, reps: 10, emoji: "🔥"),
            Exercise(name: "Arnold Press", sets: 3, reps: 12, emoji: "⚡"),
            Exercise(name: "Push Up", sets: 3, reps: 15, emoji: "💥"),
            Exercise(name: "Battle Rope", sets: 4, reps: 20, emoji: "🌪️")
        ]),
        WorkoutDay(name: "Conditioning Pull", exercises: [
            Exercise(name: "Trap Bar Deadlift", sets: 4, reps: 6, emoji: "🦍"),
            Exercise(name: "Assault Row", sets: 4, reps: 15, emoji: "🚣"),
            Exercise(name: "Single Arm Row", sets: 3, reps: 12, emoji: "🎯"),
            Exercise(name: "Face Pull", sets: 3, reps: 15, emoji: "🪝")
        ]),
        WorkoutDay(name: "Leg Circuit", exercises: [
            Exercise(name: "Goblet Squat", sets: 4, reps: 12, emoji: "🦵"),
            Exercise(name: "Step Up", sets: 3, reps: 12, emoji: "📶"),
            Exercise(name: "Kettlebell Swing", sets: 4, reps: 20, emoji: "🔔"),
            Exercise(name: "Bike Sprint", sets: 6, reps: 30, emoji: "🚴")
        ]),
        WorkoutDay(name: "HIIT Core", exercises: [
            Exercise(name: "Burpee", sets: 4, reps: 12, emoji: "🚨"),
            Exercise(name: "Mountain Climber", sets: 4, reps: 20, emoji: "⛰️"),
            Exercise(name: "Russian Twist", sets: 3, reps: 20, emoji: "🌀"),
            Exercise(name: "Plank", sets: 3, reps: 45, emoji: "🧱")
        ]),
        WorkoutDay(name: "Full Body", exercises: [
            Exercise(name: "Thruster", sets: 4, reps: 10, emoji: "🚀"),
            Exercise(name: "Pull Up", sets: 3, reps: 8, emoji: "🧲"),
            Exercise(name: "Walking Lunge", sets: 3, reps: 14, emoji: "🚶"),
            Exercise(name: "Sled Push", sets: 5, reps: 20, emoji: "🛷")
        ]),
        WorkoutDay(name: "Active Recovery", exercises: [
            Exercise(name: "Jog", sets: 1, reps: 25, emoji: "🏃"),
            Exercise(name: "Mobility", sets: 2, reps: 12, emoji: "🧘"),
            Exercise(name: "Band Pull Apart", sets: 3, reps: 20, emoji: "📏")
        ]),
        WorkoutDay(name: "Rest", exercises: [
            Exercise(name: "Walk", sets: 1, reps: 30, emoji: "🌤️"),
            Exercise(name: "Stretch", sets: 2, reps: 10, emoji: "🤸")
        ])
    ]

    static let recompPlan: [WorkoutDay] = [
        WorkoutDay(name: "Upper Strength", exercises: [
            Exercise(name: "Bench Press", sets: 4, reps: 6, emoji: "🏋️"),
            Exercise(name: "Pull Up", sets: 4, reps: 8, emoji: "🧲"),
            Exercise(name: "Seated Press", sets: 3, reps: 10, emoji: "🎯"),
            Exercise(name: "Cable Row", sets: 3, reps: 10, emoji: "🔗")
        ]),
        WorkoutDay(name: "Lower Strength", exercises: [
            Exercise(name: "Back Squat", sets: 4, reps: 6, emoji: "🦵"),
            Exercise(name: "Romanian Deadlift", sets: 3, reps: 8, emoji: "⚙️"),
            Exercise(name: "Split Squat", sets: 3, reps: 10, emoji: "⚔️"),
            Exercise(name: "Leg Curl", sets: 3, reps: 12, emoji: "🔁")
        ]),
        WorkoutDay(name: "Conditioning", exercises: [
            Exercise(name: "Row Sprint", sets: 6, reps: 30, emoji: "🚣"),
            Exercise(name: "Box Jump", sets: 4, reps: 10, emoji: "📦"),
            Exercise(name: "Med Ball Slam", sets: 4, reps: 12, emoji: "💣"),
            Exercise(name: "Hollow Hold", sets: 3, reps: 30, emoji: "🪨")
        ]),
        WorkoutDay(name: "Upper Hypertrophy", exercises: [
            Exercise(name: "Incline DB Press", sets: 4, reps: 10, emoji: "💪"),
            Exercise(name: "Chest Supported Row", sets: 4, reps: 10, emoji: "🛡️"),
            Exercise(name: "Lateral Raise", sets: 3, reps: 15, emoji: "✨"),
            Exercise(name: "Cable Curl", sets: 3, reps: 12, emoji: "🌀")
        ]),
        WorkoutDay(name: "Lower Hypertrophy", exercises: [
            Exercise(name: "Front Squat", sets: 4, reps: 8, emoji: "🏗️"),
            Exercise(name: "Hip Thrust", sets: 4, reps: 10, emoji: "🔋"),
            Exercise(name: "Leg Extension", sets: 3, reps: 15, emoji: "📈"),
            Exercise(name: "Calf Raise", sets: 4, reps: 15, emoji: "📏")
        ]),
        WorkoutDay(name: "Mobility", exercises: [
            Exercise(name: "Zone 2 Cardio", sets: 1, reps: 30, emoji: "🫀"),
            Exercise(name: "Mobility Flow", sets: 2, reps: 12, emoji: "🧘"),
            Exercise(name: "Farmer Carry", sets: 4, reps: 20, emoji: "🧰")
        ]),
        WorkoutDay(name: "Rest", exercises: [
            Exercise(name: "Walk", sets: 1, reps: 30, emoji: "🚶"),
            Exercise(name: "Breathing Drill", sets: 2, reps: 10, emoji: "🌬️")
        ])
    ]
}
