import SwiftUI
import Amplify

struct SocialView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: FeedFilter = .all
    @State private var searchText = ""
    @State private var activities: [Activity] = []
    @State private var isLoading = false

    // Only the "All" tab has data today — friends/following need a social
    // backend that doesn't exist yet, so those tabs show an honest empty state.
    private var displayedActivities: [Activity] {
        guard selectedFilter == .all else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return activities }
        return activities.filter { $0.workout.lowercased().contains(query) }
    }

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SOCIAL")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Connect with your crew")
                            .font(ForgeTheme.nunito(15, weight: .light))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        TextField("Search your workouts...", text: $searchText)
                            .font(ForgeTheme.nunito(15, weight: .semibold))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(ForgeTheme.textMuted)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    // Filter tabs
                    HStack(spacing: 8) {
                        ForEach(FeedFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(ForgeTheme.nunito(15, weight: .heavy))
                                    .tracking(1)
                                    .foregroundColor(selectedFilter == filter ? .black : ForgeTheme.textMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedFilter == filter ? appState.goal.color : ForgeTheme.surface)
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
                    
                    // Your Stats Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR STATS TODAY")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WORKOUT")
                                    .font(ForgeTheme.nunito(12, weight: .heavy))
                                    .tracking(1.5)
                                    .foregroundColor(ForgeTheme.textMuted)
                                
                                Text(appState.todayName)
                                    .font(ForgeTheme.bebas(24))
                                    .foregroundColor(appState.goal.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ForgeTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STREAK")
                                    .font(ForgeTheme.nunito(12, weight: .heavy))
                                    .tracking(1.5)
                                    .foregroundColor(ForgeTheme.textMuted)
                                
                                HStack(spacing: 4) {
                                    Text("\(appState.streak)")
                                        .font(ForgeTheme.bebas(24))
                                        .foregroundColor(ForgeTheme.accentCut)
                                    
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(ForgeTheme.accentCut)
                                }
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
                    
                    // Activity Feed
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVITY FEED")
                            .font(ForgeTheme.nunito(13, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)

                        activityFeed
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .dismissKeyboardOnTap()
        .onAppear { loadActivity() }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            loadActivity()
        }
    }

    @ViewBuilder
    private var activityFeed: some View {
        if selectedFilter != .all {
            emptyState(
                icon: "person.2",
                title: "COMING SOON",
                message: "Friends & following aren't available yet."
            )
        } else if isLoading {
            ProgressView()
                .tint(appState.goal.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if displayedActivities.isEmpty {
            emptyState(
                icon: searchText.isEmpty ? "figure.strengthtraining.traditional" : "magnifyingglass",
                title: searchText.isEmpty ? "NO ACTIVITY YET" : "NO MATCHES",
                message: searchText.isEmpty
                    ? "Complete a workout and it'll show up here."
                    : "No workouts match your search."
            )
        } else {
            VStack(spacing: 12) {
                ForEach(displayedActivities) { activity in
                    ActivityCard(activity: activity, currentGoalColor: appState.goal.color)
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ForgeTheme.textMuted.opacity(0.6))
            Text(title)
                .font(ForgeTheme.bebas(22))
                .foregroundColor(ForgeTheme.textPrimary)
            Text(message)
                .font(ForgeTheme.nunito(13, weight: .semibold))
                .foregroundColor(ForgeTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }

    // Builds the feed from the user's own real workouts.
    private func loadActivity() {
        isLoading = true
        let userName = appState.userName
        let initial = String(userName.prefix(1)).uppercased()
        let goalColor = appState.goal.color

        Task {
            do {
                let workouts = try await WorkoutService.fetchAllWorkouts(limit: 50)
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full

                let mapped = workouts
                    .sorted { WorkoutService.loggedDay(of: $0) > WorkoutService.loggedDay(of: $1) }
                    .map { workout -> Activity in
                        let exercises = (workout.exercises ?? []).compactMap { $0 }
                        let sets = exercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }
                        let volume = exercises.reduce(0.0) { total, exercise in
                            total + (exercise.sets ?? []).reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                        }
                        return Activity(
                            userName: userName,
                            userInitial: initial,
                            action: "completed",
                            workout: workout.name,
                            timeAgo: formatter.localizedString(for: WorkoutService.loggedDay(of: workout), relativeTo: Date()),
                            stats: ActivityStats(sets: sets, weight: Int(volume)),
                            goalColor: goalColor
                        )
                    }

                await MainActor.run {
                    self.activities = mapped
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    appState.handleAuthError(error)
                }
                Log.debug("❌ [SocialView] Error loading activity: \(error)")
            }
        }
    }
}

// MARK: - Feed Filter
enum FeedFilter: String, CaseIterable {
    case all = "ALL"
    case friends = "FRIENDS"
    case following = "FOLLOWING"
}

// MARK: - Activity Model
struct Activity: Identifiable {
    let id = UUID()
    let userName: String
    let userInitial: String
    let action: String
    let workout: String
    let timeAgo: String
    let stats: ActivityStats?
    let goalColor: Color
}

struct ActivityStats {
    let sets: Int?
    let weight: Int?
    let duration: Int?
    let reps: Int?
    
    init(sets: Int? = nil, weight: Int? = nil, duration: Int? = nil, reps: Int? = nil) {
        self.sets = sets
        self.weight = weight
        self.duration = duration
        self.reps = reps
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: Activity
    let currentGoalColor: Color
    @State private var isPropped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info and action
            HStack(spacing: 12) {
                Circle()
                    .fill(activity.goalColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(activity.userInitial)
                            .font(ForgeTheme.bebas(20))
                            .foregroundColor(activity.goalColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(activity.userName)
                            .font(ForgeTheme.nunito(14, weight: .bold))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text(activity.action)
                            .font(ForgeTheme.nunito(14, weight: .semibold))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    
                    Text(activity.workout.uppercased())
                        .font(ForgeTheme.bebas(18))
                        .foregroundColor(activity.goalColor)
                    
                    Text(activity.timeAgo)
                        .font(ForgeTheme.nunito(13, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                Spacer()
            }
            
            // Stats if available
            if let stats = activity.stats {
                HStack(spacing: 12) {
                    if let sets = stats.sets {
                        StatBadge(icon: "square.stack.3d.up.fill", value: "\(sets)", label: "sets")
                    }
                    
                    if let weight = stats.weight {
                        StatBadge(icon: "scalemass.fill", value: "\(weight)", label: "lb")
                    }
                    
                    if let duration = stats.duration {
                        StatBadge(icon: "clock.fill", value: "\(duration)", label: "min")
                    }
                    
                    if let reps = stats.reps {
                        StatBadge(icon: "repeat", value: "\(reps)", label: "reps")
                    }
                }
                .padding(.top, 4)
            }
            
            // Action button
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isPropped.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPropped ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 12))

                        Text(isPropped ? "PROPPED" : "PROPS")
                            .font(ForgeTheme.nunito(13, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(isPropped ? currentGoalColor : ForgeTheme.textMuted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isPropped ? currentGoalColor.opacity(0.15) : ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isPropped ? currentGoalColor.opacity(0.4) : ForgeTheme.border, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ForgeTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
        )
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(ForgeTheme.textMuted)
            
            Text(value)
                .font(ForgeTheme.nunito(14, weight: .bold))
                .foregroundColor(ForgeTheme.textPrimary)
            
            Text(label)
                .font(ForgeTheme.nunito(10, weight: .semibold))
                .foregroundColor(ForgeTheme.textMuted)
        }
    }
}
#Preview {
    SocialView()
        .environmentObject(AppState())
}

