import SwiftUI
import SwiftUI
import Combine
import Amplify
import AWSPluginsCore

// MARK: - Workout Ready
struct WorkoutReadyView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var startWorkout = false

    var exercises: [Exercise] { appState.todayExercises }

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Back
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(ForgeTheme.nunito(13, weight: .bold))
                    .foregroundColor(ForgeTheme.textMuted)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)

                Text(appState.todayName.uppercased())
                    .font(ForgeTheme.nunito(16, weight: .heavy))
                    .tracking(3)
                    .foregroundColor(ForgeTheme.textMuted)

                Text("LET'S GO")
                    .font(ForgeTheme.bebas(52))
                    .foregroundColor(ForgeTheme.accentBulk)

                Text("\(exercises.count) exercises · ~45 min")
                    .font(ForgeTheme.nunito(14, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted)
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(exercises.enumerated()), id: \.1.id) { idx, ex in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(ForgeTheme.accentBulk.opacity(0.08))
                                        .overlay(Circle().stroke(ForgeTheme.accentBulk.opacity(0.2), lineWidth: 1))
                                        .frame(width: 30, height: 30)
                                    Text("\(idx + 1)")
                                        .font(ForgeTheme.nunito(13, weight: .heavy))
                                        .foregroundColor(ForgeTheme.accentBulk)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(ForgeTheme.nunito(15, weight: .heavy))
                                        .foregroundColor(ForgeTheme.textPrimary)
                                    Text("\(ex.sets) sets · \(ex.reps) reps")
                                        .font(ForgeTheme.nunito(12, weight: .semibold))
                                        .foregroundColor(ForgeTheme.textMuted)
                                }
                                Spacer()
                                Text(ex.emoji)
                                    .font(.system(size: 20))
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1)))
                        }
                    }
                    .padding(.top, 16)
                }

                Button {
                    startWorkout = true
                } label: {
                    Text("START WORKOUT")
                        .font(ForgeTheme.bebas(24))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(ForgeTheme.accentBulk)
                        .cornerRadius(20)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .workoutModal(isPresented: $startWorkout) {
            ActiveWorkoutView(exercises: exercises, workoutDate: Date())
                .environmentObject(appState)
        }
    }
}

// MARK: - Active Workout (New Design)
struct ActiveWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let exercises: [Exercise]
    let workoutDate: Date
    
    @StateObject private var trackedExercises: TrackedExercisesContainer
    @State private var showCancelAlert = false
    @State private var showDone = false
    @State private var expandedExerciseId: UUID? = nil
    
    init(exercises: [Exercise], workoutDate: Date = Date()) {
        self.exercises = exercises
        self.workoutDate = workoutDate
        _trackedExercises = StateObject(wrappedValue: TrackedExercisesContainer(exercises: exercises))
    }
    
    var completedSets: Int {
        trackedExercises.exercises.flatMap(\.sets).filter(\.isCompleted).count
    }
    
    var totalSets: Int {
        trackedExercises.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var body: some View {
        ZStack {
            // LIGHT BACKGROUND for easier viewing
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOP BAR - simpler, cleaner
                HStack(spacing: 16) {
                    Button {
                        showCancelAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(width: 54, height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    Button {
                        finishWorkout()
                    } label: {
                        Text("Finish")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // WORKOUT INFO
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(formatDate(Date()))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button {
                                    // Options
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(hex: "0A84FF"))
                                }
                            }
                            
                            HStack(spacing: 16) {
                                Label(formatDate(Date()), systemImage: "calendar")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // EXERCISES - Each fully visible, easy to use
                        ForEach(trackedExercises.exercises.indices, id: \.self) { exerciseIndex in
                            let trackedEx = trackedExercises.exercises[exerciseIndex]
                            VStack(spacing: 0) {
                                // Exercise name with link icon
                                HStack(spacing: 12) {
                                    Text(trackedEx.name)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(Color(hex: "0A84FF"))
                                    
                                    Button {
                                        // Link to exercise details
                                    } label: {
                                        Image(systemName: "link")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "0A84FF"))
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        // Exercise options
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(hex: "0A84FF"))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                
                                // COLUMN HEADERS - bigger, clearer
                                HStack(spacing: 12) {
                                    Text("Set")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.gray)
                                        .frame(width: 45, alignment: .leading)
                                    
                                    Text("Previous")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                    
                                    Text("lbs")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.gray)
                                        .frame(width: 80)
                                    
                                    Text("Reps")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.gray)
                                        .frame(width: 80)
                                    
                                    Text("")
                                        .frame(width: 50)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                
                                // SET ROWS - bigger, easier to tap
                                ForEach(trackedEx.sets.indices, id: \.self) { index in
                                    VStack(spacing: 0) {
                                        HStack(spacing: 12) {
                                            // Set number
                                            Text("\(trackedEx.sets[index].setNumber)")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.black)
                                                .frame(width: 45, alignment: .leading)
                                            
                                            // Previous
                                            if let prevWeight = trackedEx.sets[index].previousWeight,
                                               let prevReps = trackedEx.sets[index].previousReps {
                                                Text("\(Int(prevWeight)) × \(prevReps)")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray)
                                                    .frame(maxWidth: .infinity)
                                            } else {
                                                Text("—")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray.opacity(0.4))
                                                    .frame(maxWidth: .infinity)
                                            }
                                            
                                            // Weight input - BIGGER
                                            TextField("0", value: $trackedExercises.exercises[exerciseIndex].sets[index].weight, format: .number)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .keyboardType(.decimalPad)
                                                .frame(width: 80, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(trackedEx.sets[index].isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.08))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                            
                                            // Reps input - BIGGER
                                            TextField("0", value: $trackedExercises.exercises[exerciseIndex].sets[index].reps, format: .number)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .keyboardType(.numberPad)
                                                .frame(width: 80, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(trackedEx.sets[index].isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.08))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                            
                                            // Checkmark - BIGGER, easier to tap
                                            Button {
                                                withAnimation(.spring(response: 0.3)) {
                                                    trackedExercises.exercises[exerciseIndex].sets[index].isCompleted.toggle()
                                                    if trackedExercises.exercises[exerciseIndex].sets[index].isCompleted && index < trackedExercises.exercises[exerciseIndex].sets.count - 1 {
                                                        // Show rest timer
                                                    }
                                                }
                                            } label: {
                                                Image(systemName: trackedExercises.exercises[exerciseIndex].sets[index].isCompleted ? "checkmark.square.fill" : "square")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(trackedExercises.exercises[exerciseIndex].sets[index].isCompleted ? Color.green : Color.gray.opacity(0.3))
                                            }
                                            .frame(width: 50)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(trackedExercises.exercises[exerciseIndex].sets[index].isCompleted ? Color.green.opacity(0.05) : Color.clear)
                                        
                                        // REST TIMER - Blue bar like Hevy
                                        if trackedExercises.exercises[exerciseIndex].sets[index].isCompleted && index < trackedExercises.exercises[exerciseIndex].sets.count - 1 {
                                            HStack(spacing: 12) {
                                                Text("Rest")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Text("1:30")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                
                                                Button {
                                                    // Skip rest
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .background(Color(hex: "0A84FF"))
                                        }
                                    }
                                }
                                
                                // ADD SET BUTTON - shows recommended rest time
                                Button {
                                    let newSet = WorkoutSet(
                                        setNumber: trackedExercises.exercises[exerciseIndex].sets.count + 1,
                                        weight: trackedExercises.exercises[exerciseIndex].sets.last?.weight ?? 0,
                                        reps: trackedExercises.exercises[exerciseIndex].sets.last?.reps ?? 0
                                    )
                                    trackedExercises.exercises[exerciseIndex].sets.append(newSet)
                                } label: {
                                    Text("+ Add Set (2:00)")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.08))
                                        )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            .padding(.bottom, 24)
                        }
                        
                        Spacer(minLength: 200)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // BOTTOM BUTTONS - cleaner styling
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        showCancelAlert = true
                    } label: {
                        Text("Cancel Workout")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .offset(y: -168)
                )
            }
        }
        .alert("Cancel Workout?", isPresented: $showCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Yes, Cancel", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will be lost.")
        }
        .workoutModal(isPresented: $showDone) {
            WorkoutDoneView(
                setsCompleted: completedSets,
                exerciseCount: exercises.count
            ) {
                dismiss()
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func finishWorkout() {
        // Dismiss keyboard to ensure TextField values are committed
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        
        // Save workout to database with delay
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await saveWorkout()
        }
        
        showDone = true
    }
    
    func saveWorkout() async {
        // Build the models on the main actor (reads TrackedExercise published state).
        let completedExercises = await MainActor.run {
            WorkoutService.makeCompletedExercises(from: trackedExercises.exercises)
        }
        let workoutName = await MainActor.run { appState.todayName }

        do {
            _ = try await WorkoutService.saveWorkout(
                name: workoutName,
                date: workoutDate,
                exercises: completedExercises
            )
            Log.debug("✅ Workout saved successfully!")
            await MainActor.run {
                // Streak is recomputed from workout history when listeners
                // refresh on this notification — no manual increment.
                NotificationCenter.default.post(name: .workoutSaved, object: nil)
            }
        } catch {
            Log.debug("❌ Error saving workout: \(error)")
            await MainActor.run { appState.handleAuthError(error) }
        }
    }
}

// MARK: - Tracked Exercises Container
class TrackedExercisesContainer: ObservableObject {
    @Published var exercises: [TrackedExercise]
    
    init(exercises: [Exercise]) {
        self.exercises = exercises.map { TrackedExercise(from: $0) }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @ObservedObject var trackedExercise: TrackedExercise
    let isExpanded: Bool
    let accentColor: Color
    let onTap: () -> Void
    @State private var showingRestTimer = false
    @State private var restTimeRemaining = 90
    
    var body: some View {
        VStack(spacing: 0) {
            // EXERCISE SECTION - Name as tappable text
            HStack(spacing: 12) {
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Text(trackedExercise.name)
                            .font(ForgeTheme.nunito(17, weight: .bold))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Image(systemName: "link")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    // Options menu
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ForgeTheme.textMuted)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ForgeTheme.surface)
            
            if isExpanded {
                VStack(spacing: 0) {
                    // COLUMN HEADER ROW
                    HStack(spacing: 8) {
                        Text("Set")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("Previous")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("lbs")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(width: 70, alignment: .center)
                        
                        Text("Reps")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(width: 70, alignment: .center)
                        
                        Text("✓")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .foregroundColor(ForgeTheme.textMuted)
                            .frame(width: 40, alignment: .center)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ForgeTheme.background)
                    
                    // SET ROWS
                    ForEach(trackedExercise.sets.indices, id: \.self) { index in
                        VStack(spacing: 0) {
                            SetRow(
                                set: $trackedExercise.sets[index],
                                accentColor: accentColor,
                                onComplete: {
                                    // Show rest timer after completing a set
                                    if index < trackedExercise.sets.count - 1 {
                                        showingRestTimer = true
                                        restTimeRemaining = 90
                                    }
                                }
                            )
                            
                            // REST TIMER BAR
                            if showingRestTimer && trackedExercise.sets[index].isCompleted && index < trackedExercise.sets.count - 1 {
                                RestTimerBar(timeRemaining: $restTimeRemaining, totalTime: 90) {
                                    showingRestTimer = false
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(accentColor.opacity(0.05))
                            }
                        }
                    }
                    
                    // "+ ADD SET" BUTTON
                    Button {
                        let newSet = WorkoutSet(
                            setNumber: trackedExercise.sets.count + 1,
                            weight: trackedExercise.sets.last?.weight ?? 0,
                            reps: trackedExercise.sets.last?.reps ?? 0
                        )
                        trackedExercise.sets.append(newSet)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Add Set")
                                .font(ForgeTheme.nunito(13, weight: .bold))
                        }
                        .foregroundColor(ForgeTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ForgeTheme.background)
                }
                .background(ForgeTheme.surface)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ForgeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ForgeTheme.border, lineWidth: 1)
                )
        )
    }
}
// MARK: - Set Row
struct SetRow: View {
    @Binding var set: WorkoutSet
    let accentColor: Color
    var onComplete: () -> Void
    @FocusState private var weightFieldFocused: Bool
    @FocusState private var repsFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // SET NUMBER
            Text("\(set.setNumber)")
                .font(ForgeTheme.nunito(14, weight: .bold))
                .foregroundColor(ForgeTheme.textPrimary)
                .frame(width: 40, alignment: .leading)
            
            // PREVIOUS (greyed out)
            if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
                Text("\(Int(prevWeight)) × \(prevReps)")
                    .font(ForgeTheme.nunito(12, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("—")
                    .font(ForgeTheme.nunito(12, weight: .semibold))
                    .foregroundColor(ForgeTheme.textMuted.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // LBS INPUT FIELD
            TextField("0", value: $set.weight, format: .number)
                .font(ForgeTheme.nunito(15, weight: .bold))
                .foregroundColor(ForgeTheme.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($weightFieldFocused)
                .frame(width: 70)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ForgeTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(weightFieldFocused ? accentColor : ForgeTheme.border, lineWidth: 1)
                        )
                )
            
            // REPS INPUT FIELD
            TextField("0", value: $set.reps, format: .number)
                .font(ForgeTheme.nunito(15, weight: .bold))
                .foregroundColor(ForgeTheme.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($repsFieldFocused)
                .frame(width: 70)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ForgeTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(repsFieldFocused ? accentColor : ForgeTheme.border, lineWidth: 1)
                        )
                )
            
            // CHECKMARK BUTTON
            Button {
                withAnimation(.spring(response: 0.3)) {
                    set.isCompleted.toggle()
                    if set.isCompleted {
                        onComplete()
                    }
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(set.isCompleted ? Color.green : ForgeTheme.textMuted.opacity(0.3))
            }
            .frame(width: 40, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            // COMPLETED SET HIGHLIGHTED BACKGROUND
            set.isCompleted ?
            accentColor.opacity(0.08) :
            Color.clear
        )
    }
}

// MARK: - Rest Timer Bar
struct RestTimerBar: View {
    @Binding var timeRemaining: Int
    let totalTime: Int
    let onComplete: () -> Void
    @State private var timer: Timer?
    
    var progress: Double {
        Double(timeRemaining) / Double(totalTime)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Rest")
                    .font(ForgeTheme.nunito(12, weight: .bold))
                    .foregroundColor(ForgeTheme.textMuted)
                
                Spacer()
                
                Text("\(timeRemaining)s")
                    .font(ForgeTheme.nunito(12, weight: .bold))
                    .foregroundColor(ForgeTheme.textPrimary)
                
                Button {
                    timer?.invalidate()
                    onComplete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ForgeTheme.textMuted)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ForgeTheme.surface)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onComplete()
            }
        }
    }
}

// MARK: - Workout Done
struct WorkoutDoneView: View {
    let setsCompleted: Int
    let exerciseCount: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🏆").font(.system(size: 64))
                VStack(spacing: 4) {
                    Text("WORKOUT\nCOMPLETE")
                        .font(ForgeTheme.bebas(56))
                        .foregroundColor(ForgeTheme.accentBulk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(0)
                    Text("Crushed it!")
                        .font(ForgeTheme.nunito(15, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                HStack(spacing: 10) {
                    DoneStat(value: "\(setsCompleted)", label: "Sets")
                    DoneStat(value: "\(exerciseCount)", label: "Exercises")
                }
                Button {
                    onDismiss()
                } label: {
                    Text("BACK TO HOME")
                        .font(ForgeTheme.bebas(24))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(ForgeTheme.accentBulk)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct DoneStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(ForgeTheme.bebas(30)).foregroundColor(ForgeTheme.accentBulk)
            Text(label).font(ForgeTheme.nunito(14, weight: .heavy)).tracking(1).foregroundColor(ForgeTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1)))
    }
}

private extension View {
    @ViewBuilder
    func workoutModal<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
#if os(macOS)
        sheet(isPresented: isPresented, content: content)
#else
        fullScreenCover(isPresented: isPresented, content: content)
#endif
    }
}

#Preview {
    WorkoutReadyView()
        .environmentObject(AppState())
}
