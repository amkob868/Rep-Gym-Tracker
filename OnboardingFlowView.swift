import SwiftUI

// MARK: - Onboarding Flow Coordinator
struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var selectedGoal: Goal = .bulk
    @State private var height: Int = 70 // in inches (5'10")
    @State private var weight: Int = 180 // in pounds
    @State private var desiredWeight: Int = 170 // goal weight
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            TabView(selection: $currentStep) {
                NameEntryView(
                    userName: $userName,
                    onContinue: {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep = 1
                        }
                    }
                )
                .tag(0)
                
                GoalSelectionView(
                    selectedGoal: $selectedGoal,
                    userName: userName,
                    onComplete: {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep = 2
                        }
                    }
                )
                .tag(1)
                
                HeightEntryView(
                    height: $height,
                    onContinue: {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep = 3
                        }
                    }
                )
                .tag(2)
                
                CurrentWeightEntryView(
                    weight: $weight,
                    onContinue: {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep = 4
                        }
                    }
                )
                .tag(3)
                
                GoalWeightEntryView(
                    currentWeight: weight,
                    desiredWeight: $desiredWeight,
                    onComplete: {
                        appState.userName = userName
                        appState.goal = selectedGoal
                        appState.height = height
                        appState.weight = weight
                        appState.desiredWeight = desiredWeight
                        withAnimation(.spring(response: 0.3)) {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Step indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? Color(hex: "0A84FF") : ForgeTheme.textMuted.opacity(0.3))
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Name Entry View
struct NameEntryView: View {
    @Binding var userName: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("LET'S GET STARTED")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    Text("WHAT'S YOUR\nNAME?")
                        .font(ForgeTheme.bebas(64))
                        .foregroundColor(ForgeTheme.textPrimary)
                        .lineSpacing(4)
                }
                .padding(.top, 100)
                
                // Input field
                VStack(alignment: .leading, spacing: 12) {
                    TextField("ENTER YOUR NAME", text: $userName)
                        .font(ForgeTheme.nunito(20, weight: .bold))
                        .foregroundColor(ForgeTheme.textPrimary)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ForgeTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ForgeTheme.border, lineWidth: 2)
                                )
                        )
                    
                    if !userName.isEmpty {
                        Text("Welcome, \(userName)!")
                            .font(ForgeTheme.nunito(14, weight: .semibold))
                            .foregroundColor(Color(hex: "0A84FF"))
                    }
                }
                
                Spacer()
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("CONTINUE")
                            .font(ForgeTheme.bebas(24))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(userName.isEmpty ? ForgeTheme.textMuted.opacity(0.3) : Color(hex: "0A84FF"))
                    .cornerRadius(16)
                }
                .disabled(userName.isEmpty)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - Goal Selection View
struct GoalSelectionView: View {
    @Binding var selectedGoal: Goal
    let userName: String
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text("I AM PLANNING...")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                            .lineSpacing(4)
                        
                        Text("WE'LL BUILD YOUR PROGRAM AROUND THIS.")
                            .font(ForgeTheme.nunito(13, weight: .heavy))
                            .tracking(1.5)
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 100)
                    
                    // Goal options
                    VStack(spacing: 16) {
                        ForEach(Goal.allCases, id: \.self) { goal in
                            GoalOptionCard(
                                goal: goal,
                                isSelected: selectedGoal == goal,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedGoal = goal
                                    }
                                }
                            )
                        }
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 24)
            }
            
            // Floating button
            VStack {
                Spacer()
                Button {
                    onComplete()
                } label: {
                    HStack(spacing: 12) {
                        Text("LET'S BUILD IT")
                            .font(ForgeTheme.bebas(24))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "0A84FF"))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "0A84FF").opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Goal Option Card
struct GoalOptionCard: View {
    let goal: Goal
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "0A84FF").opacity(0.2) : ForgeTheme.surface)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(hex: "0A84FF") : ForgeTheme.border, lineWidth: 2)
                        )
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "0A84FF"))
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue.uppercased())
                        .font(ForgeTheme.bebas(32))
                        .foregroundColor(isSelected ? Color(hex: "0A84FF") : goal.color)
                    
                    Text(goal.description.uppercased())
                        .font(ForgeTheme.nunito(11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(ForgeTheme.textMuted)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "0A84FF") : ForgeTheme.textMuted)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "0A84FF").opacity(0.1) : ForgeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color(hex: "0A84FF") : ForgeTheme.border, lineWidth: isSelected ? 2 : 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Height Entry View
struct HeightEntryView: View {
    @Binding var height: Int
    let onContinue: () -> Void
    
    private var feet: Int {
        height / 12
    }
    
    private var inches: Int {
        height % 12
    }
    
    private var heightBinding: Binding<Int> {
        Binding(
            get: { feet },
            set: { newFeet in
                height = (newFeet * 12) + inches
            }
        )
    }
    
    private var inchesBinding: Binding<Int> {
        Binding(
            get: { inches },
            set: { newInches in
                height = (feet * 12) + newInches
            }
        )
    }
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("BODY STATS")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    VStack(alignment: .leading, spacing: -8) {
                        Text("WHAT'S YOUR")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("HEIGHT?")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }
                }
                .padding(.top, 100)
                
                // Height picker
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        // Feet picker
                        VStack(spacing: 12) {
                            Picker("Feet", selection: heightBinding) {
                                ForEach(3...8, id: \.self) { ft in
                                    Text("\(ft)")
                                        .font(ForgeTheme.bebas(48))
                                        .tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 200)
                            .clipped()
                            
                            Text("FEET")
                                .font(ForgeTheme.nunito(14, weight: .heavy))
                                .tracking(1.5)
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ForgeTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ForgeTheme.border, lineWidth: 2)
                                )
                        )
                        
                        // Inches picker
                        VStack(spacing: 12) {
                            Picker("Inches", selection: inchesBinding) {
                                ForEach(0..<12, id: \.self) { inch in
                                    Text("\(inch)")
                                        .font(ForgeTheme.bebas(48))
                                        .tag(inch)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 200)
                            .clipped()
                            
                            Text("INCHES")
                                .font(ForgeTheme.nunito(14, weight: .heavy))
                                .tracking(1.5)
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ForgeTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ForgeTheme.border, lineWidth: 2)
                                )
                        )
                    }
                    
                    Text("YOU'RE \(feet)'\(inches)\" TALL")
                        .font(ForgeTheme.nunito(14, weight: .semibold))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
                
                Spacer()
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("CONTINUE")
                            .font(ForgeTheme.bebas(24))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "0A84FF"))
                    .cornerRadius(16)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Current Weight Entry View
struct CurrentWeightEntryView: View {
    @Binding var weight: Int
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("BODY STATS")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    VStack(alignment: .leading, spacing: -8) {
                        Text("WHAT'S YOUR")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("WEIGHT?")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }
                }
                .padding(.top, 100)
                
                // Current Weight picker
                VStack(spacing: 16) {
                    Text("CURRENT WEIGHT")
                        .font(ForgeTheme.nunito(12, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(ForgeTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        Picker("Weight", selection: $weight) {
                            ForEach(Array(stride(from: 80, through: 400, by: 1)), id: \.self) { lbs in
                                Text("\(lbs)")
                                    .font(ForgeTheme.bebas(48))
                                    .tag(lbs)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 200)
                        .clipped()
                        
                        Text("POUNDS")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1.5)
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ForgeTheme.border, lineWidth: 2)
                            )
                    )
                    
                    Text("YOU WEIGH \(weight) LBS")
                        .font(ForgeTheme.nunito(14, weight: .semibold))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
                
                Spacer()
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("CONTINUE")
                            .font(ForgeTheme.bebas(24))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "0A84FF"))
                    .cornerRadius(16)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Goal Weight Entry View
struct GoalWeightEntryView: View {
    let currentWeight: Int
    @Binding var desiredWeight: Int
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("ALMOST DONE")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                    
                    VStack(alignment: .leading, spacing: -8) {
                        Text("WHAT'S YOUR")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("GOAL WEIGHT?")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }
                }
                .padding(.top, 100)
                
                // Goal Weight picker
                VStack(spacing: 16) {
                    Text("GOAL WEIGHT")
                        .font(ForgeTheme.nunito(12, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(ForgeTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        Picker("Goal Weight", selection: $desiredWeight) {
                            ForEach(Array(stride(from: 80, through: 400, by: 1)), id: \.self) { lbs in
                                Text("\(lbs)")
                                    .font(ForgeTheme.bebas(48))
                                    .tag(lbs)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 200)
                        .clipped()
                        
                        Text("POUNDS")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1.5)
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ForgeTheme.border, lineWidth: 2)
                            )
                    )
                    
                    HStack(spacing: 8) {
                        Image(systemName: desiredWeight < currentWeight ? "arrow.down.circle.fill" : desiredWeight > currentWeight ? "arrow.up.circle.fill" : "equal.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "0A84FF"))
                        
                        if desiredWeight < currentWeight {
                            Text("LOSE \(currentWeight - desiredWeight) LBS")
                                .font(ForgeTheme.nunito(14, weight: .semibold))
                                .foregroundColor(Color(hex: "0A84FF"))
                        } else if desiredWeight > currentWeight {
                            Text("GAIN \(desiredWeight - currentWeight) LBS")
                                .font(ForgeTheme.nunito(14, weight: .semibold))
                                .foregroundColor(Color(hex: "0A84FF"))
                        } else {
                            Text("MAINTAIN WEIGHT")
                                .font(ForgeTheme.nunito(14, weight: .semibold))
                                .foregroundColor(Color(hex: "0A84FF"))
                        }
                    }
                }
                
                Spacer()
                
                // Complete button
                Button {
                    onComplete()
                } label: {
                    HStack(spacing: 12) {
                        Text("LET'S GO!")
                            .font(ForgeTheme.bebas(24))
                            .tracking(2)
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "0A84FF"))
                    .cornerRadius(16)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState())
}
