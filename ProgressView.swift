import SwiftUI
import Charts
import Amplify
import AWSPluginsCore
import class Amplify.List

struct ProgressTrackingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedExercise: String = "Bench Press"
    @State private var workoutHistory: [WorkoutHistoryItem] = []
    @State private var isLoadingWorkouts = false
    @State private var allWorkouts: [Workout] = []

    private let defaultExercises = ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull Ups"]

    // Exercises the user has actually logged (most frequent first); falls back
    // to a starter list before any workouts exist.
    private var exerciseOptions: [String] {
        let names = WorkoutService.exerciseNames(from: allWorkouts)
        return names.isEmpty ? defaultExercises : names
    }

    // Real weight progression for the selected exercise + time range.
    private var selectedProgression: [WorkoutDataPoint] {
        getDataForExercise(selectedExercise, range: selectedTimeRange)
    }
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROGRESS")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Track your gains")
                            .font(ForgeTheme.nunito(15, weight: .light))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    
                    // Stats Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("OVERVIEW")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        HStack(spacing: 12) {
                            StatCard(
                                title: "WORKOUTS",
                                value: "\(WorkoutService.monthlyWorkoutCount(in: allWorkouts, reference: Date()))",
                                subtitle: "This month",
                                color: ForgeTheme.accentBulk
                            )

                            StatCard(
                                title: "STREAK",
                                value: "\(appState.streak)",
                                subtitle: "Days",
                                color: ForgeTheme.accentCut
                            )
                        }

                        HStack(spacing: 12) {
                            StatCard(
                                title: "TOTAL SETS",
                                value: "\(WorkoutService.totalSets(in: allWorkouts))",
                                subtitle: "All time",
                                color: ForgeTheme.accentRecomp
                            )

                            StatCard(
                                title: "PR's HIT",
                                value: "\(WorkoutService.personalRecordCount(in: allWorkouts, reference: Date()))",
                                subtitle: "This month",
                                color: ForgeTheme.dayColors[4]
                            )
                        }
                    }
                    
                    // Exercise Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TRACK EXERCISE")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(exerciseOptions, id: \.self) { exercise in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedExercise = exercise
                                        }
                                    } label: {
                                        Text(exercise.uppercased())
                                            .font(ForgeTheme.nunito(16, weight: .bold))
                                            .foregroundColor(selectedExercise == exercise ? .black : ForgeTheme.textPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedExercise == exercise ? appState.goal.color : ForgeTheme.surface)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedExercise == exercise ? appState.goal.color : ForgeTheme.border, lineWidth: 1.5)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Time Range Selector
                    HStack(spacing: 8) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTimeRange = range
                                }
                            } label: {
                                Text(range.rawValue)
                                    .font(ForgeTheme.nunito(15, weight: .heavy))
                                    .tracking(1)
                                    .foregroundColor(selectedTimeRange == range ? .black : ForgeTheme.textMuted)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedTimeRange == range ? appState.goal.color : ForgeTheme.surface)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    // Progress Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedExercise.uppercased())
                                    .font(ForgeTheme.bebas(28))
                                    .foregroundColor(ForgeTheme.textPrimary)

                                chartHeaderStats
                            }

                            Spacer()
                        }

                        // Chart
                        Chart {
                            ForEach(selectedProgression) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Weight", dataPoint.weight)
                                )
                                .foregroundStyle(appState.goal.color)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                
                                AreaMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Weight", dataPoint.weight)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [appState.goal.color.opacity(0.3), appState.goal.color.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                PointMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Weight", dataPoint.weight)
                                )
                                .foregroundStyle(appState.goal.color)
                                .symbolSize(60)
                            }
                        }
                        .frame(height: 220)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(ForgeTheme.textMuted)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(ForgeTheme.textMuted)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    // Recent PRs
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TOP PR'S")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)

                        let records = WorkoutService.personalRecords(from: allWorkouts)
                        if records.isEmpty {
                            Text("No records yet — finish a workout to set your first PR.")
                                .font(ForgeTheme.nunito(14, weight: .semibold))
                                .foregroundColor(ForgeTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(ForgeTheme.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                                )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(records.prefix(5).enumerated()), id: \.element.id) { index, record in
                                    PRCard(
                                        exercise: record.exercise,
                                        weight: record.weightLabel,
                                        date: relativeDateString(record.date),
                                        detail: "\(record.reps) reps",
                                        color: prColor(index)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Workout History Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("WORKOUT HISTORY")
                                .font(ForgeTheme.nunito(15, weight: .heavy))
                                .tracking(3)
                                .foregroundColor(ForgeTheme.textMuted)
                            
                            Spacer()
                            
                            if isLoadingWorkouts {
                                ProgressView()
                                    .tint(appState.goal.color)
                            }
                        }
                        
                        if workoutHistory.isEmpty && !isLoadingWorkouts {
                            VStack(spacing: 12) {
                                Text("💪")
                                    .font(.system(size: 48))
                                Text("No workouts yet")
                                    .font(ForgeTheme.nunito(16, weight: .bold))
                                    .foregroundColor(ForgeTheme.textMuted)
                                Text("Complete your first workout to see it here!")
                                    .font(ForgeTheme.nunito(14, weight: .semibold))
                                    .foregroundColor(ForgeTheme.textMuted.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ForgeTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(workoutHistory, id: \.id) { workout in
                                    WorkoutHistoryCard(workout: workout, color: appState.goal.color)
                                }
                            }
                        }
                    }
                    
                    // Volume Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEKLY VOLUME")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        Chart {
                            ForEach(getWeeklyVolumeData()) { dataPoint in
                                BarMark(
                                    x: .value("Day", dataPoint.day),
                                    y: .value("Sets", dataPoint.sets)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [appState.goal.color, appState.goal.color.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(8)
                            }
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(ForgeTheme.textMuted)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(ForgeTheme.textMuted)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            loadWorkouts()
        }
        .refreshable {
            loadWorkouts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            print("📊 ProgressView received workout saved notification, refreshing...")
            loadWorkouts()
        }
    }
    
    // Load workouts from AWS
    func loadWorkouts() {
        isLoadingWorkouts = true

        Task { @MainActor in
            do {
                let workouts = try await WorkoutService.fetchAllWorkouts(limit: 100)

                self.allWorkouts = workouts
                self.workoutHistory = workouts
                    .map(WorkoutHistoryItem.init)
                    .sorted { $0.date > $1.date }

                // Keep the selected exercise valid against real data.
                let options = self.exerciseOptions
                if !options.contains(self.selectedExercise), let first = options.first {
                    self.selectedExercise = first
                }

                self.isLoadingWorkouts = false
                print("✅ Loaded \(workouts.count) workouts")

            } catch {
                self.isLoadingWorkouts = false
                print("❌ Error loading workouts: \(error)")
            }
        }
    }

    // Real weight progression for an exercise over the chosen time range.
    func getDataForExercise(_ exercise: String, range: TimeRange) -> [WorkoutDataPoint] {
        let calendar = Calendar.current
        let since: Date? = {
            switch range {
            case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
            case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
            case .year: return calendar.date(byAdding: .year, value: -1, to: Date())
            }
        }()

        return WorkoutService.weightProgression(for: exercise, in: allWorkouts, since: since)
            .map { WorkoutDataPoint(date: $0.date, weight: $0.weight) }
    }

    // Real sets-per-day for the current week.
    func getWeeklyVolumeData() -> [VolumeDataPoint] {
        WorkoutService.weeklyVolume(in: allWorkouts, reference: Date())
            .map { VolumeDataPoint(day: $0.day, sets: $0.sets) }
    }

    // MARK: - Chart header

    @ViewBuilder
    private var chartHeaderStats: some View {
        let points = selectedProgression
        if let last = points.last {
            HStack(spacing: 8) {
                Text(formatWeight(last.weight))
                    .font(ForgeTheme.nunito(14, weight: .bold))
                    .foregroundColor(appState.goal.color)

                if let first = points.first, points.count > 1, first.weight != last.weight {
                    let delta = last.weight - first.weight
                    HStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(delta >= 0 ? "+" : "")\(formatWeight(delta))")
                            .font(ForgeTheme.nunito(15, weight: .bold))
                    }
                    .foregroundColor(appState.goal.color)
                }
            }
        } else {
            Text("NO DATA YET")
                .font(ForgeTheme.nunito(14, weight: .bold))
                .foregroundColor(ForgeTheme.textMuted)
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight)) LB"
            : String(format: "%.1f LB", weight)
    }

    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func prColor(_ index: Int) -> Color {
        let palette = [ForgeTheme.accentBulk, ForgeTheme.accentCut, ForgeTheme.accentRecomp]
        return palette[index % palette.count]
    }
}

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable {
    case week = "WEEK"
    case month = "MONTH"
    case year = "YEAR"
}

// MARK: - Data Models
struct WorkoutDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let sets: Int
}

struct WorkoutHistoryItem: Identifiable {
    let id: String
    let name: String
    let date: Date
    let totalSets: Int
    let exercises: [WorkoutHistoryExercise]
    
    init(workout: Workout) {
        id = workout.id
        name = workout.name
        date = workout.date.foundationDate
        
        let mappedExercises = workout.exercises?.compactMap { exercise -> WorkoutHistoryExercise? in
            guard let exercise else { return nil }
            return WorkoutHistoryExercise(
                name: exercise.name,
                emoji: exercise.emoji,
                setCount: exercise.sets?.count ?? 0
            )
        } ?? []
        
        exercises = mappedExercises
        totalSets = mappedExercises.reduce(0) { $0 + $1.setCount }
    }
}

struct WorkoutHistoryExercise: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let setCount: Int
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ForgeTheme.nunito(14, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(ForgeTheme.textMuted)
            
            Text(value)
                .font(ForgeTheme.bebas(40))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(ForgeTheme.nunito(15, weight: .semibold))
                .foregroundColor(ForgeTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }
}

// MARK: - PR Card
struct PRCard: View {
    let exercise: String
    let weight: String
    let date: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .overlay(
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.uppercased())
                    .font(ForgeTheme.nunito(13, weight: .heavy))
                    .foregroundColor(ForgeTheme.textPrimary)

                Text(date)
                    .font(ForgeTheme.nunito(11, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(weight)
                    .font(ForgeTheme.bebas(24))
                    .foregroundColor(color)

                Text(detail)
                    .font(ForgeTheme.nunito(14, weight: .bold))
                    .foregroundColor(ForgeTheme.textMuted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: WorkoutHistoryItem
    let color: Color
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name.uppercased())
                        .font(ForgeTheme.bebas(24))
                        .foregroundColor(ForgeTheme.textPrimary)
                    
                    Text(formattedDate)
                        .font(ForgeTheme.nunito(12, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.totalSets)")
                        .font(ForgeTheme.bebas(28))
                        .foregroundColor(color)
                    Text("SETS")
                        .font(ForgeTheme.nunito(11, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(ForgeTheme.textMuted)
                }
            }
            
            // Exercise list
            if !workout.exercises.isEmpty {
                VStack(spacing: 6) {
                    ForEach(workout.exercises.prefix(3)) { exercise in
                        HStack(spacing: 8) {
                            Text(exercise.emoji)
                                .font(.system(size: 14))
                            
                            Text(exercise.name)
                                .font(ForgeTheme.nunito(13, weight: .bold))
                                .foregroundColor(ForgeTheme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(exercise.setCount) sets")
                                .font(ForgeTheme.nunito(12, weight: .semibold))
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                    }
                    
                    if workout.exercises.count > 3 {
                        Text("+ \(workout.exercises.count - 3) more exercises")
                            .font(ForgeTheme.nunito(12, weight: .semibold))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }
}

#Preview {
    ProgressView()
        .environmentObject(AppState())
}
