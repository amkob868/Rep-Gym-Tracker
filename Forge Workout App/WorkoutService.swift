import Amplify
import AWSPluginsCore
import Foundation

// MARK: - Workout Cache
/// Thread-safe cache of workouts keyed by "yyyy-MM-dd".
actor WorkoutCache {
    static let shared = WorkoutCache()

    private var cache: [String: Workout] = [:]

    private init() {}

    func getCachedWorkout(for dateString: String) -> Workout? {
        cache[dateString]
    }

    func cacheWorkout(_ workout: Workout, for dateString: String) {
        cache[dateString] = workout
    }

    func cacheWorkouts(_ workouts: [Workout]) {
        // Stored dates are anchored to UTC midnight — read the key back in UTC
        // so it matches the "yyyy-MM-dd" the workout was saved under.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        for workout in workouts {
            let dateString = formatter.string(from: workout.date.foundationDate)
            cache[dateString] = workout
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Workout Service
/// Single source of truth for workout persistence, retrieval, and model conversion.
/// Keeps Amplify/GraphQL access and date/exercise mapping out of the views.
enum WorkoutService {

    // MARK: Date helpers

    /// The canonical "yyyy-MM-dd" key used for caching and day comparisons.
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    /// The calendar day a workout was logged for, as a **local** midnight `Date`.
    ///
    /// Amplify stores the date anchored to UTC midnight, so reading it with the
    /// local calendar shifts it a day (e.g. Sep 5 00:00 UTC → Sep 4 in the US).
    /// We read the y/m/d back in UTC and rebuild it in the local calendar so all
    /// comparisons and display line up with the day the user actually picked.
    static func loggedDay(of workout: Workout) -> Date {
        let utc = utcCalendar.dateComponents([.year, .month, .day], from: workout.date.foundationDate)
        return Calendar.current.date(
            from: DateComponents(year: utc.year, month: utc.month, day: utc.day)
        ) ?? workout.date.foundationDate
    }

    /// True when `workout` falls on `date` in the user's local calendar.
    static func workout(_ workout: Workout, matches date: Date) -> Bool {
        let calendar = Calendar.current
        let target = calendar.dateComponents([.year, .month, .day], from: date)
        let actual = calendar.dateComponents([.year, .month, .day], from: workout.date.foundationDate)
        return target.year == actual.year && target.month == actual.month && target.day == actual.day
    }

    /// "MARCH 31" or, when `withOrdinal` is true, "MARCH 31ST".
    static func formattedDayTitle(for date: Date, withOrdinal: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let base = formatter.string(from: date).uppercased()
        guard withOrdinal else { return base }

        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "ST"
        case 2, 22: suffix = "ND"
        case 3, 23: suffix = "RD"
        default: suffix = "TH"
        }
        return base + suffix
    }

    // MARK: Fetching

    /// Fetch all workouts (unfiltered).
    static func fetchAllWorkouts(limit: Int = 1000) async throws -> [Workout] {
        let request = GraphQLRequest<Workout>.list(Workout.self, limit: limit)
        let result = try await Amplify.API.query(request: request)
        switch result {
        case .success(let workouts):
            return workouts.elements
        case .failure(let error):
            throw error
        }
    }

    /// Fetch the workout logged for a specific day.
    /// Cache-aware by default; pass `useCache: false` to always hit the API.
    ///
    /// Uses a server-side date predicate so only the matching record is
    /// transferred, rather than listing everything and filtering in memory.
    static func fetchWorkout(for date: Date, useCache: Bool = true) async throws -> Workout? {
        let key = dateKey(for: date)

        if useCache, let cached = await WorkoutCache.shared.getCachedWorkout(for: key) {
            return cached
        }

        let temporalDate = try Temporal.Date(iso8601String: key)
        let request = GraphQLRequest<Workout>.list(
            Workout.self,
            where: Workout.keys.date == temporalDate,
            limit: 1
        )
        let result = try await Amplify.API.query(request: request)
        switch result {
        case .success(let workouts):
            let workout = workouts.elements.first
            if let workout {
                await WorkoutCache.shared.cacheWorkout(workout, for: key)
            }
            return workout
        case .failure(let error):
            throw error
        }
    }

    // MARK: Persistence

    /// Build the Amplify `CompletedExercise` models from tracked exercises.
    /// Call on the main actor since it reads `TrackedExercise` published state.
    static func makeCompletedExercises(from tracked: [TrackedExercise]) -> [CompletedExercise] {
        tracked.map { exercise in
            let sets = exercise.sets.map { set in
                CompletedSet(setNumber: set.setNumber, weight: set.weight, reps: set.reps)
            }
            return CompletedExercise(name: exercise.name, emoji: exercise.emoji, sets: sets)
        }
    }

    /// Persist a workout for a date and return the saved record.
    ///
    /// Upserts: if a workout already exists for that day it is updated in place,
    /// so re-saving a day never creates duplicate calendar entries.
    static func saveWorkout(name: String, date: Date, exercises: [CompletedExercise]) async throws -> Workout {
        let key = dateKey(for: date)
        let temporalDate = try Temporal.Date(iso8601String: key)

        let request: GraphQLRequest<Workout>
        if var existing = try await fetchWorkout(for: date, useCache: false) {
            existing.name = name
            existing.exercises = exercises
            existing.date = temporalDate
            request = .update(existing)
        } else {
            request = .create(Workout(date: temporalDate, name: name, exercises: exercises))
        }

        let result = try await Amplify.API.mutate(request: request)
        switch result {
        case .success(let saved):
            // Refresh the cache so subsequent reads see the change immediately.
            await WorkoutCache.shared.cacheWorkout(saved, for: key)
            return saved
        case .failure(let error):
            throw error
        }
    }

    // MARK: Exercise conversion

    /// Build `CompletedExercise` models from the day's editable exercises,
    /// expanding per-set custom reps/weights.
    static func completedExercises(from editables: [EditableExercise]) -> [CompletedExercise] {
        editables.map { editable in
            let sets = (0..<max(editable.sets, 0)).map { index in
                CompletedSet(
                    setNumber: index + 1,
                    weight: editable.weightForSet(index),
                    reps: editable.repsForSet(index)
                )
            }
            return CompletedExercise(name: editable.name, emoji: "💪", sets: sets)
        }
    }

    /// Convert planning models into the `Exercise` type an active workout expects.
    static func exercises(from editables: [EditableExercise]) -> [Exercise] {
        editables.map { editable in
            Exercise(name: editable.name, sets: editable.sets, reps: editable.reps, emoji: "💪")
        }
    }

    /// Convert a saved workout's exercises back into editable planning models.
    static func editableExercises(from workout: Workout) -> [EditableExercise] {
        (workout.exercises ?? []).compactMap { $0 }.map { exercise in
            let firstSet = exercise.sets?.first
            return EditableExercise(
                name: exercise.name,
                sets: exercise.sets?.count ?? 3,
                reps: firstSet?.reps ?? 10,
                weight: firstSet?.weight ?? 50.0
            )
        }
    }

    // MARK: - Analytics
    // Derived entirely from the user's saved workouts — no hardcoded values.

    /// Every non-nil exercise across the given workouts, paired with its date.
    private static func loggedExercises(in workouts: [Workout]) -> [(exercise: CompletedExercise, date: Date)] {
        workouts.flatMap { workout in
            (workout.exercises ?? []).compactMap { $0 }.map { (exercise: $0, date: loggedDay(of: workout)) }
        }
    }

    /// Best (heaviest) set recorded per exercise, sorted heaviest first.
    ///
    /// Exercises are grouped case-insensitively and ignoring surrounding
    /// whitespace, so "Pull Ups" and "pull ups" collapse into a single record
    /// keeping only the highest weight.
    static func personalRecords(from workouts: [Workout]) -> [PersonalRecord] {
        var best: [String: PersonalRecord] = [:]
        for (exercise, date) in loggedExercises(in: workouts) {
            let key = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty else { continue }
            for set in exercise.sets ?? [] {
                guard set.weight > 0 else { continue }
                if let current = best[key],
                   !(set.weight > current.weight || (set.weight == current.weight && date > current.date)) {
                    continue
                }
                best[key] = PersonalRecord(
                    exercise: exercise.name,
                    weight: set.weight,
                    reps: set.reps,
                    date: date
                )
            }
        }
        return best.values.sorted { $0.weight > $1.weight }
    }

    /// Total number of sets logged across all the given workouts.
    static func totalSets(in workouts: [Workout]) -> Int {
        loggedExercises(in: workouts).reduce(0) { $0 + ($1.exercise.sets?.count ?? 0) }
    }

    /// Number of workouts logged in the same month/year as `reference`.
    static func monthlyWorkoutCount(in workouts: [Workout], reference: Date) -> Int {
        let calendar = Calendar.current
        let ref = calendar.dateComponents([.year, .month], from: reference)
        return workouts.filter {
            let c = calendar.dateComponents([.year, .month], from: loggedDay(of: $0))
            return c.year == ref.year && c.month == ref.month
        }.count
    }

    /// Number of all-time PRs that were achieved during `reference`'s month.
    static func personalRecordCount(in workouts: [Workout], reference: Date) -> Int {
        let calendar = Calendar.current
        let ref = calendar.dateComponents([.year, .month], from: reference)
        return personalRecords(from: workouts).filter {
            let c = calendar.dateComponents([.year, .month], from: $0.date)
            return c.year == ref.year && c.month == ref.month
        }.count
    }

    /// Consecutive-day workout streak ending today (or yesterday if today is
    /// still empty), computed from the workout dates. 0 when there's no
    /// current streak.
    static func currentStreak(from workouts: [Workout]) -> Int {
        let calendar = Calendar.current
        let days = Set(workouts.map { calendar.startOfDay(for: loggedDay(of: $0)) })
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        var cursor = today

        // A streak is still "alive" if you worked out today or yesterday.
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Distinct exercise names, most frequently logged first.
    static func exerciseNames(from workouts: [Workout]) -> [String] {
        var counts: [String: Int] = [:]
        for (exercise, _) in loggedExercises(in: workouts) {
            counts[exercise.name, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.map { $0.key }
    }

    /// Top-set weight per workout for a single exercise, oldest first.
    /// Pass `since` to limit to a time window (nil = all time).
    static func weightProgression(for exerciseName: String, in workouts: [Workout], since: Date? = nil) -> [(date: Date, weight: Double)] {
        workouts
            .sorted { loggedDay(of: $0) < loggedDay(of: $1) }
            .compactMap { workout -> (date: Date, weight: Double)? in
                let date = loggedDay(of: workout)
                if let since, date < since { return nil }
                let topSet = (workout.exercises ?? [])
                    .compactMap { $0 }
                    .filter { $0.name == exerciseName }
                    .flatMap { $0.sets ?? [] }
                    .map(\.weight)
                    .max()
                guard let topSet, topSet > 0 else { return nil }
                return (date, topSet)
            }
    }

    /// Sets logged per weekday (Mon…Sun) for the week containing `reference`.
    static func weeklyVolume(in workouts: [Workout], reference: Date) -> [(day: String, sets: Int)] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let labels = ["M", "T", "W", "T", "F", "S", "S"]

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: reference) else {
            return labels.map { ($0, 0) }
        }

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) ?? weekInterval.start
            let sets = workouts
                .filter { calendar.isDate(loggedDay(of: $0), inSameDayAs: day) }
                .reduce(0) { total, workout in
                    total + (workout.exercises ?? []).compactMap { $0 }.reduce(0) { $0 + ($1.sets?.count ?? 0) }
                }
            return (labels[offset], sets)
        }
    }
}

// MARK: - Personal Record
struct PersonalRecord: Identifiable {
    var id: String { exercise }
    let exercise: String
    let weight: Double
    let reps: Int
    let date: Date

    /// "225 LB" / "22.5 LB"
    var weightLabel: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) LB"
            : String(format: "%.1f LB", weight)
    }
}
