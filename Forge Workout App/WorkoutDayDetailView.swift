import SwiftUI

// MARK: - Workout Day Detail View
/// Plan & track a single day's workout.
///
/// Replaces the near-identical `TodayDetailView` and `CalendarDayDetailView`.
/// - `isToday`: adds the ordinal date suffix ("MARCH 31ST") and loads any
///   existing workout for the day on appear / when a workout is saved.
/// - `showsCloseButton`: shows a close button in the header (used when the
///   view is presented directly as a sheet rather than inside a navigator).
struct WorkoutDayDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let date: Date
    var isToday: Bool = false
    var showsCloseButton: Bool = false

    @State private var exercises: [EditableExercise] = []
    @State private var showAddExercise = false
    @State private var showWorkout = false
    @State private var isCompleted = false
    @State private var existingWorkout: Workout? = nil
    @State private var isLoadingWorkout = false

    private var dayColor: Color { ForgeTheme.accentBulk }

    private var formattedDate: String {
        WorkoutService.formattedDayTitle(for: date, withOrdinal: isToday)
    }

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                exerciseScroll
                bottomBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if isToday { loadWorkoutData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            if isToday {
                print("📬 [WorkoutDayDetailView] Received WorkoutSaved notification, refreshing data")
                loadWorkoutData()
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseView(dayColor: dayColor) { newExercise in
                withAnimation(.spring(response: 0.3)) {
                    exercises.append(newExercise)
                }
            }
        }
        .sheet(isPresented: $showWorkout) {
            ActiveWorkoutView(exercises: WorkoutService.exercises(from: exercises), workoutDate: date)
                .environmentObject(appState)
        }
    }

    // MARK: - Header (fixed)
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(ForgeTheme.bebas(48))
                    .foregroundColor(dayColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                Text("PLAN & TRACK YOUR WORKOUT")
                    .font(ForgeTheme.nunito(11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(ForgeTheme.textMuted)
            }
            Spacer(minLength: 0)

            if showsCloseButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ForgeTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Middle scroll
    private var exerciseScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if exercises.isEmpty {
                    emptyState
                } else {
                    completionButton
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseEditorCard(
                            exercise: binding(for: exercise),
                            index: index,
                            dayColor: dayColor,
                            onDelete: {
                                withAnimation(.spring(response: 0.3)) {
                                    exercises.removeAll { $0.id == exercise.id }
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(dayColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundColor(dayColor)
            }
            VStack(spacing: 8) {
                Text("NO EXERCISES YET")
                    .font(ForgeTheme.bebas(32))
                    .foregroundColor(ForgeTheme.textPrimary)
                Text("Tap the button below to add your first exercise")
                    .font(ForgeTheme.nunito(14, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Bottom bar (fixed)
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if !exercises.isEmpty {
                startWorkoutButton
            }
            addExerciseButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .padding(.top, 12)
    }

    private var startWorkoutButton: some View {
        Button {
            isLoadingWorkout = true
            Task {
                do {
                    let fetchedWorkout = try await WorkoutService.fetchWorkout(for: date)
                    await MainActor.run {
                        existingWorkout = fetchedWorkout
                        isLoadingWorkout = false
                        showWorkout = true
                        print(fetchedWorkout != nil ? "📝 Loading existing workout" : "✨ Starting fresh workout")
                    }
                } catch {
                    print("⚠️ Error checking for existing workout: \(error)")
                    await MainActor.run {
                        existingWorkout = nil
                        isLoadingWorkout = false
                        showWorkout = true
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isLoadingWorkout {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("START WORKOUT")
                        .font(ForgeTheme.bebas(22))
                        .tracking(2)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(ForgeTheme.accentBulk)
            .cornerRadius(16)
            .shadow(color: ForgeTheme.accentBulk.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(isLoadingWorkout)
    }

    private var addExerciseButton: some View {
        Button {
            showAddExercise = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("ADD EXERCISE")
                    .font(ForgeTheme.bebas(22))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(dayColor)
            .cornerRadius(16)
            .shadow(color: dayColor.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Completion button
    private var completionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isCompleted.toggle()
            }
        } label: {
            completionButtonContent
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12)
    }

    private var completionButtonContent: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isCompleted ? dayColor : ForgeTheme.textMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(isCompleted ? "WORKOUT COMPLETED! 🎉" : "MARK AS COMPLETE")
                    .font(ForgeTheme.nunito(12, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(isCompleted ? dayColor : .white)
                if isCompleted {
                    Text("Great job! Keep it up.")
                        .font(ForgeTheme.nunito(11, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(completionButtonBackground)
    }

    private var completionButtonBackground: some View {
        let fillColor = isCompleted ? dayColor.opacity(0.15) : ForgeTheme.surface2
        let strokeColor = isCompleted ? dayColor.opacity(0.4) : ForgeTheme.border
        return RoundedRectangle(cornerRadius: 16)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: 1.5)
            )
    }

    // MARK: - Data
    private func loadWorkoutData() {
        Task {
            do {
                if let workout = try await WorkoutService.fetchWorkout(for: date) {
                    print("✅ [WorkoutDayDetailView] Found existing workout")
                    await MainActor.run {
                        self.exercises = WorkoutService.editableExercises(from: workout)
                        self.existingWorkout = workout
                    }
                } else {
                    print("ℹ️ [WorkoutDayDetailView] No workout found for date")
                }
            } catch {
                print("❌ [WorkoutDayDetailView] Error loading workout: \(error)")
            }
        }
    }

    private func binding(for exercise: EditableExercise) -> Binding<EditableExercise> {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return .constant(exercise)
        }
        return $exercises[index]
    }
}
