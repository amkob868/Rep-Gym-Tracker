import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGoal: Goal? = nil
    @State private var animate = false
    @State private var userName = ""

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("LET'S GET STARTED")
                        .font(ForgeTheme.nunito(11, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(ForgeTheme.textMuted)

                    Text("WHAT'S YOUR\nNAME?")
                        .font(ForgeTheme.bebas(52))
                        .foregroundColor(ForgeTheme.textPrimary)
                        .lineSpacing(-4)

                    TextField("Enter your name", text: $userName)
                        .font(ForgeTheme.nunito(18, weight: .bold))
                        .foregroundColor(ForgeTheme.textPrimary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ForgeTheme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                        )
                        .padding(.top, 8)
                        .submitLabel(.done)
                    
                    Text("I AM PLANNING\nTO")
                        .font(ForgeTheme.bebas(38))
                        .foregroundColor(ForgeTheme.textPrimary)
                        .lineSpacing(-4)
                        .padding(.top, 24)

                    Text("We'll build your program around this.")
                        .font(ForgeTheme.nunito(15, weight: .light))
                        .foregroundColor(ForgeTheme.textMuted)
                        .padding(.top, 4)
                }
                .padding(.top, 20)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : -20)

                Spacer()

                // Goal cards
                VStack(spacing: 12) {
                    ForEach(Goal.allCases, id: \.self) { goal in
                        GoalCard(goal: goal, isSelected: selectedGoal == goal) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = goal
                            }
                        }
                    }
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)

                Spacer()

                // Continue button
                Button {
                    if let goal = selectedGoal, !userName.trimmingCharacters(in: .whitespaces).isEmpty {
                        appState.userName = userName.trimmingCharacters(in: .whitespaces)
                        appState.goal = goal
                        withAnimation {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    Text("LET'S BUILD IT →")
                        .font(ForgeTheme.bebas(24))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background((selectedGoal != nil && !userName.trimmingCharacters(in: .whitespaces).isEmpty) ? ForgeTheme.accentBulk : ForgeTheme.accentBulk.opacity(0.3))
                        .cornerRadius(20)
                }
                .disabled(selectedGoal == nil || userName.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: selectedGoal)
                .animation(.easeInOut(duration: 0.2), value: userName)

                Text("STEP 1 OF 1")
                    .font(ForgeTheme.nunito(11, weight: .heavy))
                    .tracking(3)
                    .foregroundColor(ForgeTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .dismissKeyboardOnTap()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: Goal
    let isSelected: Bool
    let onTap: () -> Void

    private var cardFill: Color {
        if isSelected {
            return goal.color
        }

        return ForgeTheme.surface
    }

    private var titleColor: Color {
        if isSelected {
            // When selected, the card has a colored background
            return .black
        }
        
        // When not selected, use the goal color
        return goal.color
    }

    private var subtextColor: Color {
        if isSelected {
            return .black.opacity(0.72)
        }

        return ForgeTheme.textMuted
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 16) {
                    // Dot
                    Circle()
                        .fill(goal.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: goal.color.opacity(0.8), radius: 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.rawValue.uppercased())
                            .font(ForgeTheme.bebas(30))
                            .foregroundColor(titleColor)
                        Text(goal.description)
                            .font(ForgeTheme.nunito(12, weight: .semibold))
                            .foregroundColor(subtextColor)
                    }
                }
                Spacer()
                Text("→")
                    .foregroundColor(ForgeTheme.textMuted)
                    .font(.system(size: 18))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? goal.color.opacity(0.4) : ForgeTheme.border, lineWidth: 1.5)
                    )
            )
            .offset(x: isSelected ? 4 : 0)
        }
        .buttonStyle(.plain)
    }
}
#Preview {
    OnboardingView()
        .environmentObject(AppState())
}

