import SwiftUI

// MARK: - Workout Day Detail View
/// Add, edit, and save the workout logged for a single day. Saved workouts
/// show up on the calendar so users can track their history there.
///
/// - `isToday`: adds the ordinal date suffix ("MARCH 31ST").
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
    @State private var isSaving = false
    /// Name of an existing workout for this day, if one was already saved.
    @State private var loadedWorkoutName: String?

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
        .onAppear { loadWorkoutData() }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            loadWorkoutData()
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseView(dayColor: dayColor) { newExercise in
                withAnimation(.spring(response: 0.3)) {
                    exercises.append(newExercise)
                }
            }
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
                Text("TRACK YOUR WORKOUT")
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
                saveWorkoutButton
            }
            addExerciseButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .padding(.top, 12)
    }

    private var saveWorkoutButton: some View {
        Button {
            Task { await saveWorkout() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("SAVE WORKOUT")
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
        .disabled(isSaving)
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

    // MARK: - Data
    private func loadWorkoutData() {
        Task {
            do {
                if let workout = try await WorkoutService.fetchWorkout(for: date) {
                    await MainActor.run {
                        self.exercises = WorkoutService.editableExercises(from: workout)
                        self.loadedWorkoutName = workout.name
                    }
                }
            } catch {
                Log.debug("❌ [WorkoutDayDetailView] Error loading workout: \(error)")
                await MainActor.run { appState.handleAuthError(error) }
            }
        }
    }

    private func saveWorkout() async {
        isSaving = true
        let name = loadedWorkoutName ?? appState.todayName
        let completed = WorkoutService.completedExercises(from: exercises)

        do {
            _ = try await WorkoutService.saveWorkout(name: name, date: date, exercises: completed)
            NotificationCenter.default.post(name: .workoutSaved, object: nil)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            Log.debug("❌ [WorkoutDayDetailView] Error saving workout: \(error)")
            await MainActor.run {
                isSaving = false
                appState.handleAuthError(error)
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
