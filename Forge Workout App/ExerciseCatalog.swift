import Foundation

/// A known exercise with a stable identity, used to give logged exercises a
/// canonical key so the same lift groups together across dates regardless of
/// how the user typed it.
struct CatalogExercise: Identifiable, Hashable {
    let id: String            // stable slug, e.g. "bench-press"
    let name: String          // canonical display name, e.g. "Bench Press"
    let muscleGroup: MuscleGroup
    let aliases: [String]     // common alternate spellings / abbreviations
}

/// A small bundled catalog of common exercises plus lookup/search helpers.
///
/// The catalog is the source of truth for exercise identity and muscle group.
/// Anything the user types that isn't in the catalog falls back to a
/// normalized version of their text as a custom key.
enum ExerciseCatalog {

    // MARK: Data

    static let all: [CatalogExercise] = [
        // Chest
        CatalogExercise(id: "bench-press", name: "Bench Press", muscleGroup: .chest, aliases: ["bp", "flat bench", "barbell bench press", "flat barbell bench"]),
        CatalogExercise(id: "incline-bench-press", name: "Incline Bench Press", muscleGroup: .chest, aliases: ["incline bench", "incline press"]),
        CatalogExercise(id: "dumbbell-bench-press", name: "Dumbbell Bench Press", muscleGroup: .chest, aliases: ["db bench", "dumbbell press"]),
        CatalogExercise(id: "incline-dumbbell-press", name: "Incline Dumbbell Press", muscleGroup: .chest, aliases: ["incline db press"]),
        CatalogExercise(id: "chest-fly", name: "Chest Fly", muscleGroup: .chest, aliases: ["fly", "flye", "pec fly", "cable fly", "dumbbell fly"]),
        CatalogExercise(id: "push-up", name: "Push Up", muscleGroup: .chest, aliases: ["pushup", "press up"]),
        CatalogExercise(id: "dip", name: "Dip", muscleGroup: .chest, aliases: ["dips", "chest dip"]),

        // Back
        CatalogExercise(id: "deadlift", name: "Deadlift", muscleGroup: .back, aliases: ["dl", "conventional deadlift"]),
        CatalogExercise(id: "pull-up", name: "Pull Up", muscleGroup: .back, aliases: ["pullup", "pull ups", "pullups"]),
        CatalogExercise(id: "chin-up", name: "Chin Up", muscleGroup: .back, aliases: ["chinup", "chin ups"]),
        CatalogExercise(id: "lat-pulldown", name: "Lat Pulldown", muscleGroup: .back, aliases: ["pulldown", "lat pull down"]),
        CatalogExercise(id: "barbell-row", name: "Barbell Row", muscleGroup: .back, aliases: ["bent over row", "bb row", "barbell bent over row"]),
        CatalogExercise(id: "dumbbell-row", name: "Dumbbell Row", muscleGroup: .back, aliases: ["db row", "one arm row", "single arm row"]),
        CatalogExercise(id: "seated-cable-row", name: "Seated Cable Row", muscleGroup: .back, aliases: ["cable row", "seated row"]),
        CatalogExercise(id: "face-pull", name: "Face Pull", muscleGroup: .back, aliases: ["face pulls"]),

        // Legs
        CatalogExercise(id: "back-squat", name: "Back Squat", muscleGroup: .legs, aliases: ["squat", "barbell squat"]),
        CatalogExercise(id: "front-squat", name: "Front Squat", muscleGroup: .legs, aliases: []),
        CatalogExercise(id: "leg-press", name: "Leg Press", muscleGroup: .legs, aliases: []),
        CatalogExercise(id: "romanian-deadlift", name: "Romanian Deadlift", muscleGroup: .legs, aliases: ["rdl", "romanian dl", "stiff leg deadlift"]),
        CatalogExercise(id: "lunge", name: "Lunge", muscleGroup: .legs, aliases: ["lunges", "walking lunge"]),
        CatalogExercise(id: "leg-curl", name: "Leg Curl", muscleGroup: .legs, aliases: ["hamstring curl"]),
        CatalogExercise(id: "leg-extension", name: "Leg Extension", muscleGroup: .legs, aliases: ["leg extensions", "quad extension"]),
        CatalogExercise(id: "calf-raise", name: "Calf Raise", muscleGroup: .legs, aliases: ["calf raises", "standing calf raise"]),
        CatalogExercise(id: "hip-thrust", name: "Hip Thrust", muscleGroup: .legs, aliases: ["glute bridge"]),

        // Shoulders
        CatalogExercise(id: "overhead-press", name: "Overhead Press", muscleGroup: .shoulders, aliases: ["ohp", "shoulder press", "military press", "strict press"]),
        CatalogExercise(id: "dumbbell-shoulder-press", name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, aliases: ["db shoulder press", "seated dumbbell press", "arnold press"]),
        CatalogExercise(id: "lateral-raise", name: "Lateral Raise", muscleGroup: .shoulders, aliases: ["lat raise", "side raise", "lateral raises"]),
        CatalogExercise(id: "rear-delt-fly", name: "Rear Delt Fly", muscleGroup: .shoulders, aliases: ["reverse fly", "rear delt raise"]),

        // Arms
        CatalogExercise(id: "bicep-curl", name: "Bicep Curl", muscleGroup: .arms, aliases: ["curl", "dumbbell curl", "barbell curl", "biceps curl"]),
        CatalogExercise(id: "hammer-curl", name: "Hammer Curl", muscleGroup: .arms, aliases: ["hammer curls"]),
        CatalogExercise(id: "tricep-pushdown", name: "Tricep Pushdown", muscleGroup: .arms, aliases: ["pushdown", "cable pushdown", "triceps pushdown"]),
        CatalogExercise(id: "tricep-extension", name: "Tricep Extension", muscleGroup: .arms, aliases: ["overhead tricep extension", "skullcrusher", "skull crusher", "triceps extension"]),

        // Core
        CatalogExercise(id: "plank", name: "Plank", muscleGroup: .core, aliases: ["planks", "front plank"]),
        CatalogExercise(id: "crunch", name: "Crunch", muscleGroup: .core, aliases: ["crunches", "sit up", "situp"]),
        CatalogExercise(id: "hanging-leg-raise", name: "Hanging Leg Raise", muscleGroup: .core, aliases: ["leg raise", "hanging knee raise"]),
        CatalogExercise(id: "russian-twist", name: "Russian Twist", muscleGroup: .core, aliases: ["russian twists"]),

        // Cardio
        CatalogExercise(id: "running", name: "Running", muscleGroup: .cardio, aliases: ["run", "jog", "treadmill", "treadmill run"]),
        CatalogExercise(id: "cycling", name: "Cycling", muscleGroup: .cardio, aliases: ["bike", "biking", "stationary bike"]),
        CatalogExercise(id: "rowing", name: "Rowing", muscleGroup: .cardio, aliases: ["row machine", "erg", "rower"]),
    ]

    // MARK: Lookup

    /// Normalize a free-text name: lowercase, strip punctuation, collapse spaces.
    static func normalize(_ name: String) -> String {
        let lowered = name.lowercased()
        var scalars = String.UnicodeScalarView()
        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " {
                scalars.append(scalar)
            } else {
                scalars.append(" ")
            }
        }
        return String(scalars).split(separator: " ").joined(separator: " ")
    }

    /// Maps every normalized name and alias to its catalog exercise.
    private static let byKey: [String: CatalogExercise] = {
        var map: [String: CatalogExercise] = [:]
        for exercise in all {
            map[normalize(exercise.name)] = exercise
            for alias in exercise.aliases {
                map[normalize(alias)] = exercise
            }
        }
        return map
    }()

    /// The catalog entry for a typed name (matching canonical name or alias).
    static func lookup(name: String) -> CatalogExercise? {
        byKey[normalize(name)]
    }

    /// A stable identity key for a name: the catalog id when known, otherwise
    /// the normalized text (so custom exercises still group with themselves).
    static func canonicalKey(for name: String) -> String {
        lookup(name: name)?.id ?? normalize(name)
    }

    /// Ranked catalog suggestions for an autocomplete query.
    static func search(_ query: String, limit: Int = 8) -> [CatalogExercise] {
        let q = normalize(query)
        guard !q.isEmpty else { return [] }

        func rank(_ exercise: CatalogExercise) -> Int? {
            let name = normalize(exercise.name)
            if name == q { return 0 }
            if name.hasPrefix(q) { return 1 }
            if name.contains(q) { return 2 }
            if exercise.aliases.contains(where: { normalize($0).hasPrefix(q) }) { return 3 }
            if exercise.aliases.contains(where: { normalize($0).contains(q) }) { return 4 }
            return nil
        }

        return all
            .compactMap { exercise in rank(exercise).map { (exercise, $0) } }
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.name < $1.0.name }
            .prefix(limit)
            .map { $0.0 }
    }
}
