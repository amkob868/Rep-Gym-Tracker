import SwiftUI
import Combine
import Amplify
import AWSPluginsCore
import class Amplify.List

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDayDetail = false
    @State private var selectedDayIndex = 0
    @State private var completedWorkoutDates: Set<String> = []
    @State private var todaysWorkout: Workout?
    @State private var isLoadingTodaysWorkout = false
    @State private var personalRecords: [PersonalRecord] = []

    let weekDays = ["M","T","W","T","F","S","S"]
    let weekDayNames = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    let completedDays = [true, true, false, true, false, false, false]
    let restDays = [false, false, true, false, false, true, false]
    let todayIndex = 3
    
    // Get current date info
    private var currentDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: Date())
    }
    
    private var currentMonthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d" // Month and day
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back, \(appState.userName)")
                            .font(ForgeTheme.bebas(28))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }

                    // Date display
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(currentDayOfWeek.uppercased()), \(currentMonthDay.uppercased())")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 4)

                    // Today's workout
                    sectionTitle("Today · \(currentMonthDay)")

                    todayWorkoutCard

                    // Calendar
                    sectionTitle("Workout History")
                    
                    WorkoutCalendarView()
                    
                    // PRs
                    sectionTitle("Personal Records")

                    personalRecordsSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
            }
        }
        .sheet(isPresented: $showDayDetail) {
            TodayWorkoutNavigator()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.hidden)
        }
        .onAppear {
            loadTodaysWorkout()
            loadHomeStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            // The save updates the cache directly, so we can read it back
            // immediately instead of sleeping to wait for eventual consistency.
            Task {
                await fetchTodaysWorkout(useCache: true)
            }
            loadHomeStats()
        }
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(ForgeTheme.nunito(11, weight: .heavy))
            .tracking(2)
            .foregroundColor(ForgeTheme.textMuted)
    }
    
    // MARK: - Today's Workout Card
    @ViewBuilder
    private var todayWorkoutCard: some View {
        let _ = print("🎨 [HomeView] Rendering workout card - isLoading: \(isLoadingTodaysWorkout), workout exists: \(todaysWorkout != nil), exercises: \(todaysWorkout?.exercises?.count ?? 0)")
        
        if isLoadingTodaysWorkout {
            // Loading state
            VStack(alignment: .center, spacing: 16) {
                ProgressView()
                    .tint(ForgeTheme.dayColors[3])
                Text("LOADING TODAY'S WORKOUT...")
                    .font(ForgeTheme.nunito(11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(ForgeTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 20).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5)))
        } else if let workout = todaysWorkout, let exercises = workout.exercises, !exercises.isEmpty {
            // Workout exists - show logged exercises
            let exerciseCount = exercises.compactMap({ $0 }).count
            
            Button {
                showDayDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name.uppercased())
                                .font(ForgeTheme.bebas(36))
                                .foregroundColor(ForgeTheme.dayColors[3])
                            
                            Text("\(exerciseCount) EXERCISES LOGGED")
                                .font(ForgeTheme.nunito(11, weight: .heavy))
                                .tracking(1.5)
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ForgeTheme.dayColors[3])
                    }

                    exerciseListView(exercises: exercises)

                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("TAP TO ADD MORE EXERCISES")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(1.5)
                    }
                    .foregroundColor(ForgeTheme.dayColors[3])
                    .padding(.top, 4)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5)))
            }
            .buttonStyle(.plain)
        } else {
            // Empty state - no workout logged yet
            Button {
                showDayDetail = true
            } label: {
                VStack(spacing: 20) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(ForgeTheme.textMuted.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("NO WORKOUT LOGGED YET")
                            .font(ForgeTheme.bebas(24))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Start tracking today's session")
                            .font(ForgeTheme.nunito(14, weight: .semibold))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("START TODAY'S WORKOUT")
                            .font(ForgeTheme.nunito(13, weight: .heavy))
                            .tracking(1.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ForgeTheme.dayColors[3])
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(RoundedRectangle(cornerRadius: 20).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5)))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func exerciseListView(exercises: [CompletedExercise?]) -> some View {
        let nonNilExercises = exercises.compactMap { $0 }
        
        VStack(spacing: 10) {
            ForEach(Array(nonNilExercises.prefix(4).enumerated()), id: \.offset) { index, exercise in
                HStack(spacing: 12) {
                    Circle()
                        .fill(ForgeTheme.dayColors[3])
                        .frame(width: 8, height: 8)
                    Text(exercise.name.uppercased())
                        .font(ForgeTheme.nunito(16, weight: .bold))
                        .foregroundColor(ForgeTheme.textPrimary)
                    Spacer()
                    if let sets = exercise.sets, !sets.isEmpty {
                        Text("\(sets.count)×\(sets[0].reps)")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                }
            }
            
            if nonNilExercises.count > 4 {
                HStack {
                    Text("+ \(nonNilExercises.count - 4) more")
                        .font(ForgeTheme.nunito(14, weight: .bold))
                        .foregroundColor(ForgeTheme.textMuted)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    private func loadTodaysWorkout() {
        Task {
            await fetchTodaysWorkout()
        }
    }
    
    private func fetchTodaysWorkout(useCache: Bool = false) async {
        isLoadingTodaysWorkout = true
        defer { isLoadingTodaysWorkout = false }

        do {
            let workout = try await WorkoutService.fetchWorkout(for: Date(), useCache: useCache)
            await MainActor.run {
                self.todaysWorkout = workout
            }
        } catch {
            print("❌ [HomeView] Error fetching today's workout: \(error)")
            await MainActor.run {
                self.todaysWorkout = nil
            }
        }
    }

    // MARK: - Personal Records
    @ViewBuilder
    private var personalRecordsSection: some View {
        if personalRecords.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "trophy")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(ForgeTheme.textMuted.opacity(0.6))
                Text("NO RECORDS YET")
                    .font(ForgeTheme.bebas(22))
                    .foregroundColor(ForgeTheme.textPrimary)
                Text("Log some weight to start setting PRs")
                    .font(ForgeTheme.nunito(13, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 16).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5)))
        } else {
            let top = Array(personalRecords.prefix(4))
            let rows = stride(from: 0, to: top.count, by: 2).map { Array(top[$0..<min($0 + 2, top.count)]) }
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 10) {
                        ForEach(row) { record in
                            prCard(record)
                        }
                        if row.count == 1 {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func prCard(_ record: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.weightLabel)
                .font(ForgeTheme.bebas(32))
                .foregroundColor(ForgeTheme.accentBulk)
            Text(record.exercise.uppercased())
                .font(ForgeTheme.nunito(10, weight: .heavy))
                .tracking(1)
                .foregroundColor(ForgeTheme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5)))
    }

    private func loadHomeStats() {
        Task {
            do {
                let workouts = try await WorkoutService.fetchAllWorkouts(limit: 100)
                let records = WorkoutService.personalRecords(from: workouts)
                let streak = WorkoutService.currentStreak(from: workouts)
                await MainActor.run {
                    self.personalRecords = records
                    appState.streak = streak
                }
            } catch {
                print("❌ [HomeView] Error loading home stats: \(error)")
            }
        }
    }
}

// MARK: - Today Workout Navigator
struct TodayWorkoutNavigator: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Just show today's workout detail
            WorkoutDayDetailView(date: Date(), isToday: true)
                .environmentObject(appState)
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 24)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Exercise Editor Card
struct ExerciseEditorCard: View {
    @Binding var exercise: EditableExercise
    let index: Int
    let dayColor: Color
    let onDelete: () -> Void
    @State private var showCustomRepsSheet = false
    @State private var showQuickEditSheet = false
    @State private var selectedSetIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(dayColor.opacity(0.15))
                            .overlay(Circle().stroke(dayColor.opacity(0.3), lineWidth: 1.5))
                            .frame(width: 36, height: 36)
                        Text("\(index + 1)")
                            .font(ForgeTheme.bebas(20))
                            .foregroundColor(dayColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name.uppercased())
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }
                }
                
                Spacer()
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ForgeTheme.accentCut)
                        .padding(8)
                        .background(Circle().fill(ForgeTheme.accentCut.opacity(0.1)))
                }
            }
            
            HStack(spacing: 8) {
                // Sets picker
                VStack(spacing: 4) {
                    Text("SETS")
                        .font(ForgeTheme.nunito(10, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    HStack(spacing: 6) {
                        Button {
                            if exercise.sets > 1 {
                                exercise.sets -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.sets > 1 ? dayColor : ForgeTheme.textMuted)
                        }
                        
                        Text("\(exercise.sets)")
                            .font(ForgeTheme.bebas(28))
                            .foregroundColor(dayColor)
                            .frame(minWidth: 30)
                        
                        Button {
                            if exercise.sets < 10 {
                                exercise.sets += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.sets < 10 ? dayColor : ForgeTheme.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(ForgeTheme.surface2))
                
                // Reps picker
                VStack(spacing: 4) {
                    Text("REPS")
                        .font(ForgeTheme.nunito(10, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    HStack(spacing: 6) {
                        Button {
                            if exercise.reps > 1 {
                                exercise.reps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.reps > 1 ? dayColor : ForgeTheme.textMuted)
                        }
                        
                        Text("\(exercise.reps)")
                            .font(ForgeTheme.bebas(28))
                            .foregroundColor(dayColor)
                            .frame(minWidth: 30)
                        
                        Button {
                            if exercise.reps < 50 {
                                exercise.reps += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.reps < 50 ? dayColor : ForgeTheme.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(ForgeTheme.surface2))
                
                // Weight picker
                VStack(spacing: 4) {
                    Text("WEIGHT")
                        .font(ForgeTheme.nunito(10, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    HStack(spacing: 6) {
                        Button {
                            if exercise.weight > 0 {
                                exercise.weight -= 2.5
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.weight > 0 ? dayColor : ForgeTheme.textMuted)
                        }
                        
                        Text(exercise.weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(exercise.weight))" : String(format: "%.1f", exercise.weight))
                            .font(ForgeTheme.bebas(28))
                            .foregroundColor(dayColor)
                            .frame(minWidth: 30)
                        
                        Button {
                            if exercise.weight < 500 {
                                exercise.weight += 2.5
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(exercise.weight < 500 ? dayColor : ForgeTheme.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(ForgeTheme.surface2))
            }
            
            // Show custom reps if they exist and are different
            if !exercise.customReps.isEmpty && exercise.customReps.count == exercise.sets {
                let allSame = Set(exercise.customReps).count == 1
                if !allSame {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CUSTOM REPS PER SET")
                            .font(ForgeTheme.nunito(10, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        HStack(spacing: 6) {
                            ForEach(0..<exercise.sets, id: \.self) { setIndex in
                                Button {
                                    selectedSetIndex = setIndex
                                    showQuickEditSheet = true
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(setIndex + 1)")
                                            .font(ForgeTheme.nunito(9, weight: .bold))
                                            .foregroundColor(ForgeTheme.textMuted)
                                        Text("\(exercise.repsForSet(setIndex))")
                                            .font(ForgeTheme.bebas(18))
                                            .foregroundColor(dayColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(ForgeTheme.surface2)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(dayColor.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // Custom reps per set button
            Button {
                showCustomRepsSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.number")
                        .font(.system(size: 12, weight: .bold))
                    Text("CUSTOMIZE REPS PER SET")
                        .font(ForgeTheme.nunito(12, weight: .heavy))
                        .tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(dayColor)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(exerciseCardBackground)
        .sheet(isPresented: $showCustomRepsSheet) {
            CustomRepsEditorView(exercise: $exercise, dayColor: dayColor)
        }
        .sheet(isPresented: $showQuickEditSheet) {
            QuickEditRepSheet(
                exercise: $exercise,
                setIndex: selectedSetIndex,
                dayColor: dayColor
            )
        }
    }
    
    private var exerciseCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(ForgeTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ForgeTheme.border, lineWidth: 1.5)
            )
    }
}

// MARK: - Quick Edit Rep Sheet
struct QuickEditRepSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercise: EditableExercise
    let setIndex: Int
    let dayColor: Color
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Text("SET \(setIndex + 1)")
                        .font(ForgeTheme.bebas(32))
                        .foregroundColor(dayColor)
                    
                    Text(exercise.name.uppercased())
                        .font(ForgeTheme.nunito(14, weight: .bold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                // Rep counter
                VStack(spacing: 24) {
                    Text("\(exercise.repsForSet(setIndex))")
                        .font(ForgeTheme.bebas(96))
                        .foregroundColor(dayColor)
                    
                    Text("REPS")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                // Increment/Decrement buttons
                HStack(spacing: 20) {
                    Button {
                        if exercise.customReps.count != exercise.sets {
                            // Initialize custom reps if not set
                            exercise.customReps = Array(repeating: exercise.reps, count: exercise.sets)
                        }
                        if exercise.customReps[setIndex] > 1 {
                            exercise.customReps[setIndex] -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(exercise.repsForSet(setIndex) > 1 ? dayColor : ForgeTheme.textMuted)
                    }
                    
                    Button {
                        if exercise.customReps.count != exercise.sets {
                            // Initialize custom reps if not set
                            exercise.customReps = Array(repeating: exercise.reps, count: exercise.sets)
                        }
                        if exercise.customReps[setIndex] < 50 {
                            exercise.customReps[setIndex] += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(exercise.repsForSet(setIndex) < 50 ? dayColor : ForgeTheme.textMuted)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("DONE")
                        .font(ForgeTheme.bebas(22))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(dayColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Custom Reps Editor View Model
class CustomRepsViewModel: ObservableObject {
    @Published var customReps: [Int]
    let exerciseName: String
    let sets: Int
    let defaultReps: Int
    
    init(exercise: EditableExercise) {
        self.exerciseName = exercise.name
        self.sets = exercise.sets
        self.defaultReps = exercise.reps
        
        if exercise.customReps.count == exercise.sets {
            self.customReps = exercise.customReps
        } else {
            self.customReps = Array(repeating: exercise.reps, count: exercise.sets)
        }
    }
    
    func updateRep(at index: Int, to value: Int) {
        guard index < customReps.count else { return }
        customReps[index] = value
    }
    
    func resetToDefaults() {
        customReps = Array(repeating: defaultReps, count: sets)
    }
}

// MARK: - Custom Reps Editor View
struct CustomRepsEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercise: EditableExercise
    let dayColor: Color
    
    @StateObject private var viewModel: CustomRepsViewModel
    
    init(exercise: Binding<EditableExercise>, dayColor: Color) {
        self._exercise = exercise
        self.dayColor = dayColor
        self._viewModel = StateObject(wrappedValue: CustomRepsViewModel(exercise: exercise.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ForgeTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CUSTOM REPS")
                                .font(ForgeTheme.bebas(40))
                                .foregroundColor(dayColor)
                            Text("SET REPS FOR EACH SET")
                                .font(ForgeTheme.nunito(15, weight: .heavy))
                                .tracking(1.5)
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        .padding(.top, 20)
                        
                        // Exercise info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.exerciseName.uppercased())
                                .font(ForgeTheme.bebas(28))
                                .foregroundColor(ForgeTheme.textPrimary)
                            Text("\(viewModel.sets) SETS")
                                .font(ForgeTheme.nunito(12, weight: .bold))
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ForgeTheme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                        )
                        
                        // Custom reps list
                        VStack(spacing: 12) {
                            ForEach(0..<viewModel.customReps.count, id: \.self) { index in
                                CustomRepRow(
                                    setNumber: index + 1,
                                    reps: $viewModel.customReps[index],
                                    dayColor: dayColor
                                )
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Floating buttons
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button {
                            // Save custom reps
                            exercise.customReps = viewModel.customReps
                            dismiss()
                        } label: {
                            Text("SAVE CUSTOM REPS")
                                .font(ForgeTheme.bebas(22))
                                .tracking(2)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(dayColor)
                                .cornerRadius(16)
                        }
                        
                        Button {
                            viewModel.resetToDefaults()
                        } label: {
                            Text("Reset to Default")
                                .font(ForgeTheme.nunito(14, weight: .bold))
                                .foregroundColor(ForgeTheme.textMuted)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #else
            .toolbar(.hidden)
            #endif
        }
    }
}

// MARK: - Custom Rep Row (Isolated Component)
struct CustomRepRow: View {
    let setNumber: Int
    @Binding var reps: Int
    let dayColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(dayColor.opacity(0.15))
                    .overlay(Circle().stroke(dayColor.opacity(0.3), lineWidth: 1.5))
                    .frame(width: 36, height: 36)
                Text("\(setNumber)")
                    .font(ForgeTheme.bebas(18))
                    .foregroundColor(dayColor)
            }
            
            Text("Set \(setNumber)")
                .font(ForgeTheme.nunito(14, weight: .bold))
                .foregroundColor(ForgeTheme.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    if reps > 1 {
                        reps -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(reps > 1 ? dayColor : ForgeTheme.textMuted)
                }
                
                Text("\(reps)")
                    .font(ForgeTheme.bebas(40))
                    .foregroundColor(dayColor)
                    .frame(minWidth: 50)
                
                Button {
                    if reps < 50 {
                        reps += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(reps < 50 ? dayColor : ForgeTheme.textMuted)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface2)
        )
    }
}

// MARK: - Set Configuration
struct SetConfiguration: Identifiable {
    let id = UUID()
    var weight: Double
    var reps: Int
}

// MARK: - Add Exercise View
struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let dayColor: Color
    let onAdd: (EditableExercise) -> Void
    
    @State private var exerciseName = ""
    @State private var sets = 3
    @State private var defaultReps = 10
    @State private var defaultWeight: Double = 50.0
    @State private var setConfigurations: [SetConfiguration] = []
    @State private var completedSets: Set<Int> = []
    @State private var showWeightSlider = false
    @State private var showRepsSlider = false
    @State private var editingSetIndex = 0
    @State private var showCancelConfirmation = false
    
    init(dayColor: Color, onAdd: @escaping (EditableExercise) -> Void) {
        self.dayColor = dayColor
        self.onAdd = onAdd
        // Initialize with 3 sets using default values
        _setConfigurations = State(initialValue: [
            SetConfiguration(weight: 50.0, reps: 10),
            SetConfiguration(weight: 50.0, reps: 10),
            SetConfiguration(weight: 50.0, reps: 10)
        ])
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        workoutInfoSection
                        configureSetsSection
                        cancelButton
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .sheet(isPresented: $showWeightSlider) {
            SliderEditorSheet(
                title: "SET \(editingSetIndex + 1) - WEIGHT",
                value: Binding(
                    get: { setConfigurations[editingSetIndex].weight },
                    set: { setConfigurations[editingSetIndex].weight = $0 }
                ),
                range: 0...500,
                step: 2.5,
                unit: "LBS",
                color: dayColor
            )
        }
        .sheet(isPresented: $showRepsSlider) {
            SliderEditorSheet(
                title: "SET \(editingSetIndex + 1) - REPS",
                value: Binding(
                    get: { Double(setConfigurations[editingSetIndex].reps) },
                    set: { setConfigurations[editingSetIndex].reps = Int($0) }
                ),
                range: 1...50,
                step: 1,
                unit: "REPS",
                color: dayColor
            )
        }
        .alert("Discard Exercise?", isPresented: $showCancelConfirmation) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to discard this exercise? All changes will be lost.")
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                showCancelConfirmation = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
            }

            Spacer()

            Button {
                var newExercise = EditableExercise(
                    name: exerciseName.isEmpty ? "Untitled Exercise" : exerciseName,
                    sets: sets,
                    reps: defaultReps,
                    weight: defaultWeight
                )
                // Apply per-set custom configurations
                newExercise.customReps = setConfigurations.map { $0.reps }
                newExercise.customWeights = setConfigurations.map { $0.weight }
                onAdd(newExercise)
                dismiss()
            } label: {
                Text("ADD EXERCISE")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(dayColor)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Workout info summary
    private var workoutInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack(alignment: .leading) {
                    if exerciseName.isEmpty {
                        Text("Exercise Name")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    TextField("", text: $exerciseName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                Spacer()

                Button {
                    // Options
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(dayColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                Text("Sets: \(sets)")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Image(systemName: "repeat")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                Text("Default Reps: \(defaultReps)")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                Text("Default Weight: \(defaultWeight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(defaultWeight))" : String(format: "%.1f", defaultWeight)) lbs")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Configure sets
    private var configureSetsSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 12) {
                Text("Configure Sets")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(dayColor)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Column headers
            HStack(spacing: 12) {
                Text("SET")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 45, alignment: .leading)

                Text("TARGET")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)

                Text("LBS")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 100)

                Text("REPS")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 100)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Info banner
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(dayColor)
                Text("Tap any weight or reps cell to customize individual sets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(dayColor.opacity(0.1))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Set rows
            ForEach(0..<sets, id: \.self) { setIndex in
                setConfigurationRow(setIndex)
            }

            adjustControls
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

            resetAllButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
        .padding(.bottom, 24)
    }

    private func setConfigurationRow(_ setIndex: Int) -> some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setIndex + 1)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 45, alignment: .leading)

            // Target
            let config = setConfigurations[setIndex]
            Text("\(config.weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(config.weight))" : String(format: "%.1f", config.weight)) × \(config.reps)")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)

            // Weight display - tappable
            Button {
                editingSetIndex = setIndex
                showWeightSlider = true
            } label: {
                Text(config.weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(config.weight))" : String(format: "%.1f", config.weight))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 100, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            // Reps display - tappable
            Button {
                editingSetIndex = setIndex
                showRepsSlider = true
            } label: {
                Text("\(config.reps)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 100, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var adjustControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("SETS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                    HStack(spacing: 12) {
                        Button {
                            if sets > 1 {
                                sets -= 1
                                setConfigurations.removeLast()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(sets > 1 ? dayColor : .gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Text("\(sets)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(dayColor)
                            .frame(minWidth: 40)

                        Button {
                            if sets < 10 {
                                sets += 1
                                setConfigurations.append(SetConfiguration(weight: defaultWeight, reps: defaultReps))
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(sets < 10 ? dayColor : .gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text("DEFAULT REPS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                    HStack(spacing: 12) {
                        Button {
                            if defaultReps > 1 {
                                defaultReps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(defaultReps > 1 ? dayColor : .gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Text("\(defaultReps)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(dayColor)
                            .frame(minWidth: 40)

                        Button {
                            if defaultReps < 50 {
                                defaultReps += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(defaultReps < 50 ? dayColor : .gray.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 8) {
                Text("DEFAULT WEIGHT (LBS)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    Button {
                        if defaultWeight > 0 {
                            defaultWeight -= 2.5
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(defaultWeight > 0 ? dayColor : .gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text(defaultWeight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(defaultWeight))" : String(format: "%.1f", defaultWeight))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(dayColor)
                        .frame(minWidth: 60)

                    Button {
                        if defaultWeight < 500 {
                            defaultWeight += 2.5
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(defaultWeight < 500 ? dayColor : .gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resetAllButton: some View {
        Button {
            for i in 0..<setConfigurations.count {
                setConfigurations[i].weight = defaultWeight
                setConfigurations[i].reps = defaultReps
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                Text("RESET ALL SETS TO DEFAULTS")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(dayColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(dayColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(dayColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    private var cancelButton: some View {
        Button {
            showCancelConfirmation = true
        } label: {
            Text("CANCEL")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.red.opacity(0.1))
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 40)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Editable Exercise Model
struct EditableExercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double = 50.0 // Default weight in lbs or kg with 2.5 increments
    var customReps: [Int] = [] // Custom reps per set
    var customWeights: [Double] = [] // Custom weights per set
    
    // Get reps for a specific set (0-indexed)
    func repsForSet(_ setIndex: Int) -> Int {
        if setIndex < customReps.count {
            return customReps[setIndex]
        }
        return reps
    }
    
    // Get weight for a specific set (0-indexed)
    func weightForSet(_ setIndex: Int) -> Double {
        if setIndex < customWeights.count {
            return customWeights[setIndex]
        }
        return weight
    }
    
    // Update custom reps array when sets count changes
    mutating func updateSets(_ newSets: Int) {
        if newSets > sets {
            // Adding sets - fill with default reps and weights
            customReps.append(contentsOf: Array(repeating: reps, count: newSets - sets))
            customWeights.append(contentsOf: Array(repeating: weight, count: newSets - sets))
        } else if newSets < sets {
            // Removing sets - truncate arrays
            customReps = Array(customReps.prefix(newSets))
            customWeights = Array(customWeights.prefix(newSets))
        }
        sets = newSets
    }
}

// MARK: - Swipe Direction
enum SwipeDirection {
    case left
    case right
}

// MARK: - Workout Calendar View
struct WorkoutCalendarView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedMonth = Date()
    @State private var workoutDates: Set<DateComponents> = []
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var didDrag = false  // Track if user actually dragged
    @State private var isLoading = false
    @State private var showCalendarDayDetail = false
    @State private var selectedCalendarDate: Date?
    @State private var showCompletedWorkout = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekDaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    // Starting from January 2025
    private var startDate: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private var previousMonth: Date? {
        guard canGoToPreviousMonth() else { return nil }
        return Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)
    }
    
    private var nextMonth: Date? {
        guard canGoToNextMonth() else { return nil }
        return Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func daysInMonth(for month: Date) -> [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: month),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while dates.count < 42 { // 6 weeks max
            if Calendar.current.isDate(currentDate, equalTo: month, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func isWorkoutDay(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(components)
    }
    
    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    private func isFutureDate(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return date > Date()
    }
    
    private func canGoToPreviousMonth() -> Bool {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return false
        }
        return previousMonth >= startDate
    }
    
    private func canGoToNextMonth() -> Bool {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) else {
            return false
        }
        return nextMonth <= Date()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                monthNavigationHeader
                weekDayHeader
                calendarGrids(geometry: geometry)
                    .frame(height: 280)
                    .clipped()
                    .contentShape(Rectangle())
                    .simultaneousGesture(monthSwipeGesture(geometry: geometry))
            }
        }
        .frame(height: 380)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
        .onAppear {
            loadWorkoutData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            loadWorkoutData()
        }
        .sheet(isPresented: $showCalendarDayDetail) {
            if let date = selectedCalendarDate {
                WorkoutDayDetailView(date: date, showsCloseButton: true)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showCompletedWorkout) {
            if let date = selectedCalendarDate {
                CompletedWorkoutView(workoutDate: date)
            }
        }
    }

    // MARK: - Month navigation header
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                if canGoToPreviousMonth() {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(canGoToPreviousMonth() ? ForgeTheme.textPrimary : ForgeTheme.textMuted.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(ForgeTheme.surface2))
            }
            .disabled(!canGoToPreviousMonth())

            Spacer()

            Text(monthYearString(for: selectedMonth))
                .font(ForgeTheme.bebas(24))
                .foregroundColor(ForgeTheme.textPrimary)
                .id(selectedMonth)

            Spacer()

            Button {
                if canGoToNextMonth() {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(canGoToNextMonth() ? ForgeTheme.textPrimary : ForgeTheme.textMuted.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(ForgeTheme.surface2))
            }
            .disabled(!canGoToNextMonth())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Week day header
    private var weekDayHeader: some View {
        HStack(spacing: 8) {
            ForEach(weekDaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(ForgeTheme.nunito(10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(ForgeTheme.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Swipeable month grids
    private func calendarGrids(geometry: GeometryProxy) -> some View {
        ZStack {
            // Previous month (left)
            if let prevMonth = previousMonth {
                CalendarGridView(
                    month: prevMonth,
                    daysInMonth: daysInMonth(for: prevMonth),
                    isWorkoutDay: isWorkoutDay,
                    isToday: isToday,
                    isFutureDate: isFutureDate,
                    toggleWorkoutDay: toggleWorkoutDay
                )
                .frame(width: geometry.size.width - 32)
                .offset(x: -geometry.size.width + dragOffset)
                .opacity(isDragging && dragOffset > 0 ? 1 : 0)
                .allowsHitTesting(false)
            }

            // Current month (center)
            CalendarGridView(
                month: selectedMonth,
                daysInMonth: daysInMonth(for: selectedMonth),
                isWorkoutDay: isWorkoutDay,
                isToday: isToday,
                isFutureDate: isFutureDate,
                toggleWorkoutDay: toggleWorkoutDay
            )
            .frame(width: geometry.size.width - 32)
            .offset(x: dragOffset)
            .id(selectedMonth)
            .allowsHitTesting(!isDragging)

            // Next month (right)
            if let next = nextMonth {
                CalendarGridView(
                    month: next,
                    daysInMonth: daysInMonth(for: next),
                    isWorkoutDay: isWorkoutDay,
                    isToday: isToday,
                    isFutureDate: isFutureDate,
                    toggleWorkoutDay: toggleWorkoutDay
                )
                .frame(width: geometry.size.width - 32)
                .offset(x: geometry.size.width + dragOffset)
                .opacity(isDragging && dragOffset < 0 ? 1 : 0)
                .allowsHitTesting(false)
            }
        }
    }

    private func monthSwipeGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                isDragging = true
                didDrag = true  // Mark that a drag occurred
                dragOffset = value.translation.width
            }
            .onEnded { value in
                handleMonthSwipeEnd(value: value, screenWidth: geometry.size.width)
            }
    }

    private func handleMonthSwipeEnd(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = 60
        let velocity = value.predictedEndLocation.x - value.location.x

        // Check both distance and velocity for more responsive swipes
        let shouldGoToPrevious = (value.translation.width > threshold || velocity > 100) && canGoToPreviousMonth()
        let shouldGoToNext = (value.translation.width < -threshold || velocity < -100) && canGoToNextMonth()

        if shouldGoToPrevious {
            // Animate to previous month - slide current month off to the right
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dragOffset = screenWidth
            }

            // After animation completes, update the month and reset offset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                dragOffset = 0
                // Delay re-enabling hit testing to prevent accidental taps
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isDragging = false
                    // Reset didDrag after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        didDrag = false
                    }
                }
            }
        } else if shouldGoToNext {
            // Animate to next month - slide current month off to the left
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dragOffset = -screenWidth
            }

            // After animation completes, update the month and reset offset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                dragOffset = 0
                // Delay re-enabling hit testing to prevent accidental taps
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isDragging = false
                    // Reset didDrag after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        didDrag = false
                    }
                }
            }
        } else {
            // Bounce back to current month
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                dragOffset = 0
            }
            // Small delay to prevent tap during bounce animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isDragging = false
                // Reset didDrag after bounce completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    didDrag = false
                }
            }
        }
    }

    private func loadWorkoutData() {
        isLoading = true
        
        Task {
            do {
                let workouts = try await WorkoutService.fetchAllWorkouts(limit: 100)

                // Cache all workouts immediately
                await WorkoutCache.shared.cacheWorkouts(workouts)

                var dates: Set<DateComponents> = []
                for workout in workouts {
                    let workoutDate = workout.date.foundationDate
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: workoutDate)
                    dates.insert(components)
                }
                
                await MainActor.run {
                    self.workoutDates = dates
                    self.isLoading = false
                }
                print("✅ Loaded and cached \(workouts.count) workouts for calendar")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ Error loading workouts for calendar: \(error)")
            }
        }
    }
    
    private func toggleWorkoutDay(_ date: Date) {
        // Ignore tap if user just dragged
        guard !didDrag else {
            didDrag = false  // Reset the flag
            return
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        
        if workoutDates.contains(components) {
            // Already completed - show completed workout view
            selectedCalendarDate = date
            showCompletedWorkout = true
        } else if !isFutureDate(date) {
            // Not completed and not future - show calendar day detail
            selectedCalendarDate = date
            showCalendarDayDetail = true
        }
        // Future dates do nothing
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let month: Date
    let daysInMonth: [Date?]
    let isWorkoutDay: (Date?) -> Bool
    let isToday: (Date?) -> Bool
    let isFutureDate: (Date?) -> Bool
    let toggleWorkoutDay: (Date) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isWorkoutDay: isWorkoutDay(date),
                        isToday: isToday(date),
                        isFuture: isFutureDate(date),
                        onToggle: {
                            toggleWorkoutDay(date)
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isWorkoutDay: Bool
    let isToday: Bool
    let isFuture: Bool
    let onToggle: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button {
            if !isFuture {
                onToggle()
            }
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(cellBorderColor, lineWidth: isToday ? 2 : 1)
                    )
                
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(ForgeTheme.nunito(14, weight: .bold))
                        .foregroundColor(textColor)
                    
                    if isWorkoutDay && !isFuture {
                        Circle()
                            .fill(ForgeTheme.accentBulk)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.3 : 1.0)
    }
    
    private var cellBackgroundColor: Color {
        if isToday {
            return ForgeTheme.accentBulk.opacity(0.15)
        } else if isWorkoutDay {
            return ForgeTheme.accentBulk.opacity(0.08)
        } else {
            return ForgeTheme.surface2
        }
    }
    
    private var cellBorderColor: Color {
        if isToday {
            return ForgeTheme.accentBulk
        } else if isWorkoutDay {
            return ForgeTheme.accentBulk.opacity(0.3)
        } else {
            return ForgeTheme.border
        }
    }
    
    private var textColor: Color {
        if isToday {
            return ForgeTheme.accentBulk
        } else if isFuture {
            return ForgeTheme.textMuted.opacity(0.3)
        } else {
            return ForgeTheme.textPrimary
        }
    }
}

// MARK: - Week Carousel View
struct WeekCarouselView: View {
    @Binding var selectedDayIndex: Int
    @Binding var showDayDetail: Bool
    
    @State private var currentWeekOffset = 0 // 0 = current week, -1 = last week, 1 = next week (future, disabled)
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var completedDates: Set<String> = []
    @State private var restDates: Set<String> = []
    @State private var showCompletedWorkout = false
    @State private var selectedWorkoutDate: Date?
    
    private let weekDays = ["M","T","W","T","F","S","S"]
    
    // Get the start of the current week (Monday)
    private var currentWeekStart: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2
        let today = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        return calendar.date(from: components) ?? today
    }
    
    // Get week start for any offset
    private func weekStart(offset: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func loadCompletedDates() {
        Task {
            do {
                let workouts = try await WorkoutService.fetchAllWorkouts(limit: 100)

                // Cache all workouts immediately
                await WorkoutCache.shared.cacheWorkouts(workouts)

                var dates: Set<String> = []
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                for workout in workouts {
                    let dateString = formatter.string(from: workout.date.foundationDate)
                    dates.insert(dateString)
                }
                
                await MainActor.run {
                    self.completedDates = dates
                }
                print("✅ Loaded and cached \(workouts.count) workouts")
            } catch {
                print("❌ Failed to load completed dates: \(error)")
            }
        }
    }
    
    // Get dates for a specific week
    private func datesForWeek(offset: Int) -> [Date] {
        let start = weekStart(offset: offset)
        return (0..<7).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: dayOffset, to: start)
        }
    }
    
    // Helper to create stable date identifier
    private func dateIdentifier(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Check if a date is completed (stable data)
    private func isCompleted(_ date: Date) -> Bool {
        // TODO: Replace with actual data from your app state
        return completedDates.contains(dateIdentifier(date))
    }
    
    // Check if a date is a rest day (stable data)
    private func isRestDay(_ date: Date) -> Bool {
        // TODO: Replace with actual data
        return restDates.contains(dateIdentifier(date))
    }
    
    // Check if a date is today
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Check if a date is in the future
    private func isFuture(_ date: Date) -> Bool {
        date > Date()
    }
    
    // Get week label
    private func weekLabel(offset: Int) -> String {
        if offset == 0 {
            return "This Week"
        } else if offset == -1 {
            return "Last Week"
        } else if offset == -2 {
            return "2 Weeks Ago"
        } else if offset < -2 {
            return "\(-offset) Weeks Ago"
        } else {
            return "Next Week"
        }
    }
    
    // Get date range string
    private func dateRangeString(offset: Int) -> String {
        let dates = datesForWeek(offset: offset)
        guard let first = dates.first, let last = dates.last else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let firstStr = formatter.string(from: first)
        let lastStr = formatter.string(from: last)
        
        return "\(firstStr) - \(lastStr)"
    }
    
    // Initialize sample data on appear
    private func loadSampleData() {
        var completed: Set<String> = []
        var rest: Set<String> = []
        
        let calendar = Calendar.current
        let today = Date()
        
        // Generate stable sample data for past 4 weeks
        for weekOffset in -3...0 {
            let weekStart = self.weekStart(offset: weekOffset)
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                
                // Only mark past dates
                if date < today {
                    let weekday = calendar.component(.weekday, from: date)
                    let dayOfMonth = calendar.component(.day, from: date)
                    
                    // Mark Wednesday (4) and Saturday (7) as rest days
                    if weekday == 4 || weekday == 7 {
                        rest.insert(dateIdentifier(date))
                    }
                    // Mark some days as completed (stable based on day of month)
                    else if dayOfMonth % 3 != 0 {
                        completed.insert(dateIdentifier(date))
                    }
                }
            }
        }
        
        completedDates = completed
        restDates = rest
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                weekNavigationHeader
                weekGrids(geometry: geometry)
                    .padding(.horizontal, 8)
                    .frame(height: 90)
                    .mask(
                        Rectangle()
                            .padding(.horizontal, -20)
                    )
                    .contentShape(Rectangle())
                    .simultaneousGesture(weekSwipeGesture(geometry: geometry))
            }
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
        .onAppear {
            loadCompletedDates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            loadCompletedDates()
        }
        .sheet(isPresented: $showCompletedWorkout) {
            if let date = selectedWorkoutDate {
                CompletedWorkoutView(workoutDate: date)
            }
        }
    }

    // MARK: - Week navigation header
    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    currentWeekOffset -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForgeTheme.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(ForgeTheme.surface2))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(weekLabel(offset: currentWeekOffset))
                    .font(ForgeTheme.bebas(18))
                    .foregroundColor(ForgeTheme.textPrimary)
                Text(dateRangeString(offset: currentWeekOffset))
                    .font(ForgeTheme.nunito(10, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
            }
            .id(currentWeekOffset)

            Spacer()

            Button {
                if currentWeekOffset < 0 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentWeekOffset += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(currentWeekOffset < 0 ? ForgeTheme.textPrimary : ForgeTheme.textMuted.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(ForgeTheme.surface2))
            }
            .disabled(currentWeekOffset >= 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Swipeable week grids
    private func weekGrids(geometry: GeometryProxy) -> some View {
        ZStack {
            // Previous week (left)
            WeekGridView(
                dates: datesForWeek(offset: currentWeekOffset - 1),
                weekDays: weekDays,
                isCompleted: isCompleted,
                isRestDay: isRestDay,
                isToday: isToday,
                isFuture: isFuture,
                onDayTap: { index, date, completed in
                    handleDayTap(index: index, date: date, isCompleted: completed)
                }
            )
            .frame(width: geometry.size.width - 40)
            .offset(x: -geometry.size.width + 40 + dragOffset)
            .opacity(isDragging && dragOffset > 0 ? 1 : 0)
            .allowsHitTesting(false)

            // Current week (center)
            WeekGridView(
                dates: datesForWeek(offset: currentWeekOffset),
                weekDays: weekDays,
                isCompleted: isCompleted,
                isRestDay: isRestDay,
                isToday: isToday,
                isFuture: isFuture,
                onDayTap: { index, date, completed in
                    handleDayTap(index: index, date: date, isCompleted: completed)
                }
            )
            .frame(width: geometry.size.width - 40)
            .offset(x: dragOffset)
            .id(currentWeekOffset)
            .allowsHitTesting(!isDragging)

            // Next week (right) - only show if not current week
            if currentWeekOffset < 0 {
                WeekGridView(
                    dates: datesForWeek(offset: currentWeekOffset + 1),
                    weekDays: weekDays,
                    isCompleted: isCompleted,
                    isRestDay: isRestDay,
                    isToday: isToday,
                    isFuture: isFuture,
                    onDayTap: { index, date, completed in
                        handleDayTap(index: index, date: date, isCompleted: completed)
                    }
                )
                .frame(width: geometry.size.width - 40)
                .offset(x: geometry.size.width - 40 + dragOffset)
                .opacity(isDragging && dragOffset < 0 ? 1 : 0)
                .allowsHitTesting(false)
            }
        }
    }

    private func weekSwipeGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.width
            }
            .onEnded { value in
                handleWeekSwipeEnd(value: value, screenWidth: geometry.size.width - 40)
            }
    }

    private func handleWeekSwipeEnd(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = 60
        let velocity = value.predictedEndLocation.x - value.location.x

        let shouldGoToPrevious = (value.translation.width > threshold || velocity > 100)
        let shouldGoToNext = (value.translation.width < -threshold || velocity < -100) && currentWeekOffset < 0

        if shouldGoToPrevious {
            // Animate to previous week
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dragOffset = screenWidth
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentWeekOffset -= 1
                dragOffset = 0
                isDragging = false
            }
        } else if shouldGoToNext {
            // Animate to next week
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dragOffset = -screenWidth
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentWeekOffset += 1
                dragOffset = 0
                isDragging = false
            }
        } else {
            // Bounce back
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                dragOffset = 0
                isDragging = false
            }
        }
    }

    private func handleDayTap(index: Int, date: Date, isCompleted: Bool) {
        if isCompleted {
            // Show completed workout viewer
            selectedWorkoutDate = date
            showCompletedWorkout = true
        } else {
            // Show day detail for planning
            selectedDayIndex = index
            showDayDetail = true
        }
    }
}

// MARK: - Week Grid View
struct WeekGridView: View {
    let dates: [Date]
    let weekDays: [String]
    let isCompleted: (Date) -> Bool
    let isRestDay: (Date) -> Bool
    let isToday: (Date) -> Bool
    let isFuture: (Date) -> Bool
    let onDayTap: (Int, Date, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(dates.enumerated()), id: \.element) { index, date in
                VStack(spacing: 8) {
                    Text(weekDays[index])
                        .font(ForgeTheme.nunito(10, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(circleFill(for: date))
                            .frame(width: 44, height: 44)
                        
                        // Border
                        Circle()
                            .stroke(circleStroke(for: date), lineWidth: 2)
                            .frame(width: 44, height: 44)
                        
                        // Shadow
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .shadow(color: isToday(date) ? ForgeTheme.accentBulk.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                        
                        // Content overlay
                        Group {
                            if isToday(date) {
                                Text("T")
                                    .font(ForgeTheme.bebas(20))
                                    .foregroundColor(.black)
                                    .transition(.identity)
                            } else if isCompleted(date) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForgeTheme.accentBulk)
                                    .transition(.identity)
                            } else if isRestDay(date) {
                                Text("—")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(ForgeTheme.textMuted)
                                    .transition(.identity)
                            }
                        }
                        .id(dateIdentifier(for: date))
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onDayTap(index, date, isCompleted(date))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
    
    private func dateIdentifier(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func circleFill(for date: Date) -> Color {
        if isToday(date) {
            return ForgeTheme.accentBulk
        } else if isCompleted(date) {
            return ForgeTheme.accentBulk.opacity(0.15)
        } else {
            return ForgeTheme.surface
        }
    }
    
    private func circleStroke(for date: Date) -> Color {
        if isToday(date) {
            return ForgeTheme.accentBulk
        } else if isCompleted(date) {
            return ForgeTheme.accentBulk.opacity(0.4)
        } else {
            return ForgeTheme.border
        }
    }
}

// MARK: - Completed Workout View
struct CompletedWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    let workoutDate: Date
    
    @State private var loadingState: LoadingState = .loading
    @State private var workout: Workout?
    
    enum LoadingState {
        case loading
        case loaded
        case error(String)
        case empty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ForgeTheme.background.ignoresSafeArea()
                
                switch loadingState {
                case .loading:
                    loadingView
                case .loaded:
                    if let workout = workout {
                        workoutContentView(workout: workout)
                    }
                case .error(let message):
                    errorView(message: message)
                case .empty:
                    emptyView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                }
            }
        }
        .onAppear {
            loadWorkout()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ForgeTheme.accentBulk)
            
            Text("LOADING WORKOUT...")
                .font(ForgeTheme.nunito(14, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(ForgeTheme.textMuted)
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(ForgeTheme.accentCut)
            
            VStack(spacing: 8) {
                Text("ERROR")
                    .font(ForgeTheme.bebas(32))
                    .foregroundColor(ForgeTheme.textPrimary)
                
                Text(message)
                    .font(ForgeTheme.nunito(14, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                loadWorkout()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("RETRY")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(1.5)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(ForgeTheme.accentBulk)
                .cornerRadius(12)
            }
        }
        .padding(24)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(ForgeTheme.textMuted)
            
            VStack(spacing: 8) {
                Text("NO WORKOUT FOUND")
                    .font(ForgeTheme.bebas(32))
                    .foregroundColor(ForgeTheme.textPrimary)
                
                Text("No workout was recorded for this date.")
                    .font(ForgeTheme.nunito(14, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }
    
    // MARK: - Workout Content View
    private func workoutContentView(workout: Workout) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.name.uppercased())
                        .font(ForgeTheme.bebas(48))
                        .foregroundColor(ForgeTheme.accentBulk)
                        .lineLimit(2)
                    
                    Text(formatDate(workoutDate))
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(ForgeTheme.textMuted)
                }
                .padding(.top, 20)
                
                // Workout Stats
                HStack(spacing: 12) {
                    statCard(
                        value: "\(workout.exercises?.count ?? 0)",
                        label: "Exercises"
                    )
                    
                    statCard(
                        value: "\(totalSets(workout: workout))",
                        label: "Total Sets"
                    )
                }
                
                // Section Title
                Text("EXERCISES")
                    .font(ForgeTheme.nunito(11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(ForgeTheme.textMuted)
                    .padding(.top, 8)
                
                // Exercises List
                if let exercises = workout.exercises {
                    ForEach(Array(exercises.compactMap { $0 }.enumerated()), id: \.offset) { index, exercise in
                        completedExerciseCard(exercise: exercise, index: index)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Stat Card
    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(ForgeTheme.bebas(32))
                .foregroundColor(ForgeTheme.accentBulk)
            Text(label.uppercased())
                .font(ForgeTheme.nunito(10, weight: .heavy))
                .tracking(1)
                .foregroundColor(ForgeTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ForgeTheme.border, lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Completed Exercise Card
    private func completedExerciseCard(exercise: CompletedExercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ForgeTheme.accentBulk.opacity(0.15))
                        .overlay(Circle().stroke(ForgeTheme.accentBulk.opacity(0.3), lineWidth: 1.5))
                        .frame(width: 36, height: 36)
                    Text("\(index + 1)")
                        .font(ForgeTheme.bebas(20))
                        .foregroundColor(ForgeTheme.accentBulk)
                }
                
                Text(exercise.name.uppercased())
                    .font(ForgeTheme.nunito(14, weight: .heavy))
                    .foregroundColor(ForgeTheme.textPrimary)
                
                Spacer()
            }
            
            // Sets table
            if let sets = exercise.sets, !sets.isEmpty {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 12) {
                        Text("SET")
                            .font(ForgeTheme.nunito(10, weight: .heavy))
                            .tracking(0.5)
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("WEIGHT")
                            .font(ForgeTheme.nunito(10, weight: .heavy))
                            .tracking(0.5)
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("REPS")
                            .font(ForgeTheme.nunito(10, weight: .heavy))
                            .tracking(0.5)
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 8)
                    
                    // Set rows
                    ForEach(sets, id: \.setNumber) { set in
                        HStack(spacing: 12) {
                            Text("\(set.setNumber)")
                                .font(ForgeTheme.nunito(14, weight: .bold))
                                .foregroundColor(ForgeTheme.textPrimary)
                                .frame(width: 40, alignment: .leading)
                            
                            Text(formatWeight(set.weight))
                                .font(ForgeTheme.bebas(24))
                                .foregroundColor(ForgeTheme.accentBulk)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Text("\(set.reps)")
                                .font(ForgeTheme.bebas(24))
                                .foregroundColor(ForgeTheme.accentBulk)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ForgeTheme.surface2)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ForgeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ForgeTheme.border, lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) LBS"
        } else {
            return String(format: "%.1f LBS", weight)
        }
    }
    
    private func totalSets(workout: Workout) -> Int {
        guard let exercises = workout.exercises else { return 0 }
        return exercises.compactMap { $0 }.reduce(0) { total, exercise in
            total + (exercise.sets?.count ?? 0)
        }
    }
    
    // MARK: - Load Workout
    private func loadWorkout() {
        loadingState = .loading
        let date = workoutDate
        
        Task.detached {
            do {
                let workout = try await WorkoutService.fetchWorkout(for: date)

                await MainActor.run {
                    if let workout = workout {
                        self.workout = workout
                        self.loadingState = .loaded
                        print("✅ Loaded workout: \(workout.name)")
                    } else {
                        self.loadingState = .empty
                        print("⚠️ No workout found for date")
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error("Failed to load workout. Check your connection.")
                    print("❌ Error loading workout: \(error)")
                }
            }
        }
    }
}

// MARK: - Hand-Drawn Shapes
struct HandDrawnRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a slightly imperfect rectangle with hand-drawn look
        let w = rect.width
        let h = rect.height
        
        // Top line (with slight wobble)
        path.move(to: CGPoint(x: 0, y: 2))
        path.addCurve(
            to: CGPoint(x: w * 0.33, y: 1),
            control1: CGPoint(x: w * 0.15, y: 3),
            control2: CGPoint(x: w * 0.25, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.66, y: 2),
            control1: CGPoint(x: w * 0.45, y: 0), 
            control2: CGPoint(x: w * 0.55, y: 3)
        )
        path.addCurve(
            to: CGPoint(x: w - 2, y: 1),
            control1: CGPoint(x: w * 0.8, y: 0),
            control2: CGPoint(x: w * 0.9, y: 2)
        )
        
        // Right line
        path.addCurve(
            to: CGPoint(x: w - 1, y: h * 0.33),
            control1: CGPoint(x: w, y: h * 0.15),
            control2: CGPoint(x: w - 2, y: h * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: w - 2, y: h * 0.66),
            control1: CGPoint(x: w, y: h * 0.45),
            control2: CGPoint(x: w - 3, y: h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w - 1, y: h - 2),
            control1: CGPoint(x: w - 2, y: h * 0.8),
            control2: CGPoint(x: w, y: h * 0.9)
        )
        
        // Bottom line
        path.addCurve(
            to: CGPoint(x: w * 0.66, y: h - 1),
            control1: CGPoint(x: w * 0.85, y: h),
            control2: CGPoint(x: w * 0.75, y: h - 2)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.33, y: h - 2),
            control1: CGPoint(x: w * 0.55, y: h),
            control2: CGPoint(x: w * 0.45, y: h - 3)
        )
        path.addCurve(
            to: CGPoint(x: 2, y: h - 1),
            control1: CGPoint(x: w * 0.2, y: h),
            control2: CGPoint(x: w * 0.1, y: h - 2)
        )
        
        // Left line
        path.addCurve(
            to: CGPoint(x: 1, y: h * 0.66),
            control1: CGPoint(x: 0, y: h * 0.85),
            control2: CGPoint(x: 2, y: h * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: 2, y: h * 0.33),
            control1: CGPoint(x: 0, y: h * 0.55),
            control2: CGPoint(x: 3, y: h * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: 2),
            control1: CGPoint(x: 2, y: h * 0.2),
            control2: CGPoint(x: 0, y: h * 0.1)
        )
        
        return path
    }
}
struct HandDrawnCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Start at top
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        
        // Create a circle with 8 curve segments for hand-drawn look
        for i in 0..<8 {
            let angle1 = Double(i) * .pi / 4
            let angle2 = Double(i + 1) * .pi / 4
            
            let point2 = CGPoint(
                x: center.x + radius * CGFloat(sin(angle2)),
                y: center.y - radius * CGFloat(cos(angle2))
            )
            
            // Add slight wobble to control points
            let wobble1 = CGFloat.random(in: -2...2)
            let wobble2 = CGFloat.random(in: -2...2)
            
            let control1 = CGPoint(
                x: center.x + (radius + wobble1) * CGFloat(sin(angle1 + .pi / 8)),
                y: center.y - (radius + wobble1) * CGFloat(cos(angle1 + .pi / 8))
            )
            let control2 = CGPoint(
                x: center.x + (radius + wobble2) * CGFloat(sin(angle2 - .pi / 8)),
                y: center.y - (radius + wobble2) * CGFloat(cos(angle2 - .pi / 8))
            )
            
            path.addCurve(to: point2, control1: control1, control2: control2)
        }
        
        return path
    }
}

// MARK: - Slider Editor Sheet
struct SliderEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                // Large value display
                Text(value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value))
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(color)
                    .animation(.spring(response: 0.3), value: value)
                
                // Slider
                VStack(spacing: 16) {
                    Slider(value: $value, in: range, step: step)
                        .tint(color)
                        .padding(.horizontal, 40)
                    
                    // Range labels
                    HStack {
                        Text("\(Int(range.lowerBound))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(range.upperBound))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
                
                // Quick adjustment buttons
                HStack(spacing: 20) {
                    Button {
                        let newValue = value - step
                        if newValue >= range.lowerBound {
                            value = newValue
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(value > range.lowerBound ? color : .gray.opacity(0.3))
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Button {
                        let newValue = value + step
                        if newValue <= range.upperBound {
                            value = newValue
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(value < range.upperBound ? color : .gray.opacity(0.3))
                    }
                    .disabled(value >= range.upperBound)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("DONE")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(color)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
