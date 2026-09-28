import Foundation

// MARK: - Muscle group

/// Coarse muscle groups inferred from an exercise name via keyword heuristics.
/// This is intentionally simple — it doesn't need to be perfect, just good
/// enough to say things like "you haven't trained legs in a while."
enum MuscleGroup: String, CaseIterable {
    case chest, back, legs, shoulders, arms, core, cardio, other

    var display: String {
        switch self {
        case .chest: return "chest"
        case .back: return "back"
        case .legs: return "legs"
        case .shoulders: return "shoulders"
        case .arms: return "arms"
        case .core: return "core"
        case .cardio: return "cardio"
        case .other: return "that muscle group"
        }
    }

    /// Best-guess muscle group for an exercise name. Order matters: more
    /// specific keywords are checked before generic ones.
    static func infer(from exerciseName: String) -> MuscleGroup {
        let name = exerciseName.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { name.contains($0) } }

        if has(["bench", "chest", "pec", "fly", "incline press", "dip", "push up", "pushup"]) { return .chest }
        if has(["shoulder", "delt", "lateral", "overhead", "ohp", "arnold", "military"]) { return .shoulders }
        // Legs before back so "Back Squat" is classified by the movement (squat).
        if has(["squat", "lunge", "leg", "calf", "quad", "hamstring", "glute", "hip thrust", "rdl", "romanian", "step up"]) { return .legs }
        if has(["pull", "row", "lat ", "lat-", "chin", "back", "deadlift"]) { return .back }
        if has(["curl", "bicep", "tricep", "hammer", "pushdown", "extension", "arm"]) { return .arms }
        if has(["plank", "crunch", "ab ", "abs", "core", "russian", "hollow", "sit up", "situp", "leg raise"]) { return .core }
        if has(["run", "jog", "bike", "sprint", "cardio", "elliptical", "rope", "row sprint", "walk"]) { return .cardio }
        return .other
    }
}

// MARK: - Insight

/// A single coaching note derived from the user's workout history.
struct WorkoutInsight: Identifiable, Equatable {
    enum Kind: String { case progress, plateau, rest }

    let kind: Kind
    /// Display-ready message used directly when the AI phrasing layer is
    /// unavailable. Always safe to show as-is.
    let message: String
    /// Compact, factual summary handed to the on-device model to rephrase.
    let facts: String

    var id: String { kind.rawValue + "|" + message }
}

// MARK: - Insight engine

/// Turns raw workout history into a small set of prioritized coaching insights.
/// Pure and deterministic so it can be unit-tested without a backend.
enum InsightEngine {

    /// One "best set" for an exercise on a given day.
    private struct DaySet {
        let day: Date
        let weight: Double
        let reps: Int
    }

    private static let calendar = Calendar.current

    /// Insights ordered for display (celebrate progress, then nudge). The first
    /// element is the best candidate to surface in the bubble.
    static func insights(from workouts: [Workout], now: Date = Date()) -> [WorkoutInsight] {
        let byExercise = topSetsByExercise(workouts)
        var result: [WorkoutInsight] = []
        if let progress = progressInsight(byExercise, now: now) { result.append(progress) }
        if let plateau = plateauInsight(byExercise) { result.append(plateau) }
        if let rest = restInsight(workouts, now: now) { result.append(rest) }
        return result
    }

    // MARK: Aggregation

    /// For each exercise (grouped case-insensitively), the best set per day,
    /// sorted oldest → newest. Also returns a display name.
    private static func topSetsByExercise(_ workouts: [Workout]) -> [String: (display: String, sets: [DaySet])] {
        var byKey: [String: (display: String, byDay: [Date: DaySet])] = [:]

        for workout in workouts {
            let day = calendar.startOfDay(for: WorkoutService.loggedDay(of: workout))
            for exercise in (workout.exercises ?? []).compactMap({ $0 }) {
                let key = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty else { continue }

                // Best set that day = heaviest weight, most reps at that weight.
                let sets = exercise.sets ?? []
                guard let topWeight = sets.map(\.weight).max(), topWeight > 0 else { continue }
                let reps = sets.filter { $0.weight == topWeight }.map(\.reps).max() ?? 0
                let candidate = DaySet(day: day, weight: topWeight, reps: reps)

                var entry = byKey[key] ?? (display: exercise.name, byDay: [:])
                if let existing = entry.byDay[day] {
                    if candidate.weight > existing.weight ||
                        (candidate.weight == existing.weight && candidate.reps > existing.reps) {
                        entry.byDay[day] = candidate
                    }
                } else {
                    entry.byDay[day] = candidate
                }
                byKey[key] = entry
            }
        }

        return byKey.mapValues { value in
            (display: value.display, sets: value.byDay.values.sorted { $0.day < $1.day })
        }
    }

    // MARK: Rules

    /// Muscle group not trained in ≥ 14 days (but trained before that).
    private static func restInsight(_ workouts: [Workout], now: Date) -> WorkoutInsight? {
        var lastTrained: [MuscleGroup: Date] = [:]
        for workout in workouts {
            let day = WorkoutService.loggedDay(of: workout)
            for exercise in (workout.exercises ?? []).compactMap({ $0 }) {
                let group = MuscleGroup.infer(from: exercise.name)
                guard group != .other else { continue }
                if let current = lastTrained[group] {
                    lastTrained[group] = max(current, day)
                } else {
                    lastTrained[group] = day
                }
            }
        }

        // Most-overdue group with a gap of at least two weeks.
        let overdue = lastTrained
            .compactMap { group, date -> (MuscleGroup, Int)? in
                let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
                return days >= 14 ? (group, days) : nil
            }
            .max { $0.1 < $1.1 }

        guard let (group, days) = overdue else { return nil }
        let weeks = days / 7
        return WorkoutInsight(
            kind: .rest,
            message: "You haven't trained \(group.display) in \(weeks) weeks. Time to hit it again 💪",
            facts: "The user hasn't trained \(group.display) in \(weeks) weeks (\(days) days)."
        )
    }

    /// Same top weight & reps for ≥ 3 consecutive sessions of an exercise.
    private static func plateauInsight(_ byExercise: [String: (display: String, sets: [DaySet])]) -> WorkoutInsight? {
        var best: (display: String, weight: Double, reps: Int, streak: Int)?

        for (_, value) in byExercise {
            let sets = value.sets
            guard let last = sets.last else { continue }
            var streak = 0
            for set in sets.reversed() {
                if set.weight == last.weight && set.reps == last.reps { streak += 1 } else { break }
            }
            if streak >= 3 && (best == nil || streak > best!.streak) {
                best = (value.display, last.weight, last.reps, streak)
            }
        }

        guard let plateau = best else { return nil }
        let suggested = plateau.weight + 5
        return WorkoutInsight(
            kind: .plateau,
            message: "You've hit \(plateau.display) at \(format(plateau.weight))×\(plateau.reps) for \(plateau.streak) sessions straight — try \(format(suggested)) lb or add a couple reps.",
            facts: "The user did \(plateau.display) at \(format(plateau.weight)) lb for \(plateau.reps) reps \(plateau.streak) sessions in a row. Suggest progressing to \(format(suggested)) lb or +2 reps."
        )
    }

    /// Meaningful top-weight increase for an exercise over recent weeks.
    private static func progressInsight(_ byExercise: [String: (display: String, sets: [DaySet])], now: Date) -> WorkoutInsight? {
        let windowStart = calendar.date(byAdding: .day, value: -56, to: now) ?? now // ~8 weeks
        var best: (display: String, from: Double, to: Double, weeks: Int, gain: Double)?

        for (_, value) in byExercise {
            let recent = value.sets.filter { $0.day >= windowStart }
            guard let first = recent.first, let last = recent.last, recent.count >= 2 else { continue }
            let gain = last.weight - first.weight
            let spanDays = calendar.dateComponents([.day], from: first.day, to: last.day).day ?? 0
            guard gain >= 5, spanDays >= 7 else { continue }
            if best == nil || gain > best!.gain {
                let weeks = max(1, spanDays / 7)
                best = (value.display, first.weight, last.weight, weeks, gain)
            }
        }

        guard let progress = best else { return nil }
        return WorkoutInsight(
            kind: .progress,
            message: "Great progress on \(progress.display)! You went from \(format(progress.from)) to \(format(progress.to)) lb in \(progress.weeks) weeks. Congrats! 🎉",
            facts: "The user's \(progress.display) went from \(format(progress.from)) lb to \(format(progress.to)) lb over \(progress.weeks) weeks. Congratulate them."
        )
    }

    // MARK: Formatting

    private static func format(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : String(format: "%.1f", weight)
    }
}
