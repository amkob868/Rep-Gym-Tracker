import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isEditingWeight = false
    @State private var isEditingHeight = false
    @State private var editedWeight = ""
    @State private var editedHeight = ""
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROFILE")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Your fitness journey")
                            .font(ForgeTheme.nunito(15, weight: .light))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    
                    // Profile card
                    VStack(spacing: 20) {
                        // Avatar
                        Circle()
                            .fill(appState.goal.color)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(ForgeTheme.bebas(48))
                                    .foregroundColor(.black)
                            )
                        
                        // Name section
                        if isEditingName {
                            VStack(spacing: 12) {
                                TextField("Your name", text: $editedName)
                                    .font(ForgeTheme.nunito(18, weight: .bold))
                                    .foregroundColor(ForgeTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(ForgeTheme.surface)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                                    )
                                
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        isEditingName = false
                                    }
                                    .font(ForgeTheme.nunito(14, weight: .bold))
                                    .foregroundColor(ForgeTheme.textMuted)
                                    
                                    Button("Save") {
                                        if !editedName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            appState.userName = editedName.trimmingCharacters(in: .whitespaces)
                                            isEditingName = false
                                        }
                                    }
                                    .font(ForgeTheme.bebas(18))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(appState.goal.color)
                                    .cornerRadius(12)
                                }
                            }
                        } else {
                            VStack(spacing: 4) {
                                Text(appState.userName)
                                    .font(ForgeTheme.bebas(36))
                                    .foregroundColor(ForgeTheme.textPrimary)
                                
                                Button {
                                    editedName = appState.userName
                                    isEditingName = true
                                } label: {
                                    Text("Edit name")
                                        .font(ForgeTheme.nunito(13, weight: .semibold))
                                        .foregroundColor(appState.goal.color)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ForgeTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5))
                    )
                    
                    // Stats section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STATS")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        VStack(spacing: 12) {
                            StatRow(title: "Current Goal", value: appState.goal.rawValue, color: appState.goal.color)
                            StatRow(title: "Current Streak", value: "\(appState.streak) days", color: ForgeTheme.accentCut)
                            StatRow(title: "Today's Workout", value: appState.todayName, color: ForgeTheme.accentRecomp)
                        }
                    }
                    
                    // Body Metrics section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("BODY METRICS")
                            .font(ForgeTheme.nunito(15, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        VStack(spacing: 12) {
                            // Weight Card
                            HStack {
                                HStack {
                                    Circle()
                                        .fill(ForgeTheme.accentBulk)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("WEIGHT")
                                        .font(ForgeTheme.nunito(16, weight: .bold))
                                        .foregroundColor(ForgeTheme.textMuted)
                                }
                                
                                Spacer()
                                
                                if isEditingWeight {
                                    HStack(spacing: 8) {
                                        TextField("0", text: $editedWeight)
                                            .font(ForgeTheme.bebas(20))
                                            .foregroundColor(ForgeTheme.textPrimary)
                                            .frame(width: 60)
                                            .multilineTextAlignment(.trailing)
                                        
                                        Text("LB")
                                            .font(ForgeTheme.bebas(20))
                                            .foregroundColor(ForgeTheme.textMuted)
                                        
                                        Button {
                                            if let weight = Int(editedWeight), weight > 0 {
                                                appState.weight = weight
                                            }
                                            isEditingWeight = false
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(appState.goal.color)
                                        }
                                        
                                        Button {
                                            isEditingWeight = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(ForgeTheme.textMuted)
                                        }
                                    }
                                } else {
                                    Button {
                                        editedWeight = String(appState.weight)
                                        isEditingWeight = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text("\(appState.weight) LB")
                                                .font(ForgeTheme.bebas(20))
                                                .foregroundColor(ForgeTheme.textPrimary)
                                            
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(appState.goal.color)
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
                            
                            // Height Card
                            HStack {
                                HStack {
                                    Circle()
                                        .fill(ForgeTheme.accentCut)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("HEIGHT")
                                        .font(ForgeTheme.nunito(16, weight: .bold))
                                        .foregroundColor(ForgeTheme.textMuted)
                                }
                                
                                Spacer()
                                
                                if isEditingHeight {
                                    HStack(spacing: 8) {
                                        TextField("0", text: $editedHeight)
                                            .font(ForgeTheme.bebas(20))
                                            .foregroundColor(ForgeTheme.textPrimary)
                                            .frame(width: 60)
                                            .multilineTextAlignment(.trailing)
                                        
                                        Text("IN")
                                            .font(ForgeTheme.bebas(20))
                                            .foregroundColor(ForgeTheme.textMuted)
                                        
                                        Button {
                                            if let height = Int(editedHeight), height > 0 {
                                                appState.height = height
                                            }
                                            isEditingHeight = false
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(appState.goal.color)
                                        }
                                        
                                        Button {
                                            isEditingHeight = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(ForgeTheme.textMuted)
                                        }
                                    }
                                } else {
                                    Button {
                                        editedHeight = String(appState.height)
                                        isEditingHeight = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(formatHeight(appState.height))
                                                .font(ForgeTheme.bebas(20))
                                                .foregroundColor(ForgeTheme.textPrimary)
                                            
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(appState.goal.color)
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
                            
                            // BMI Card (if both weight and height are set)
                            if appState.weight > 0 && appState.height > 0 {
                                let bmi = calculateBMI(weight: Double(appState.weight), height: Double(appState.height))
                                
                                HStack {
                                    HStack {
                                        Circle()
                                            .fill(ForgeTheme.accentRecomp)
                                            .frame(width: 8, height: 8)
                                        
                                        Text("BMI")
                                            .font(ForgeTheme.nunito(16, weight: .bold))
                                            .foregroundColor(ForgeTheme.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "%.1f", bmi))
                                            .font(ForgeTheme.bebas(20))
                                            .foregroundColor(ForgeTheme.textPrimary)
                                        
                                        Text(getBMICategory(bmi))
                                            .font(ForgeTheme.nunito(14, weight: .semibold))
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
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .dismissKeyboardOnTap()
    }
    
    // Helper function to format height in feet and inches
    func formatHeight(_ totalInches: Int) -> String {
        let feet = totalInches / 12
        let inches = totalInches % 12
        return "\(feet)'\(inches)\""
    }
    
    // Calculate BMI from weight (lbs) and height (inches)
    func calculateBMI(weight: Double, height: Double) -> Double {
        // BMI = (weight in pounds × 703) / (height in inches)²
        return (weight * 703) / (height * height)
    }
    
    // Get BMI category
    func getBMICategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title.uppercased())
                .font(ForgeTheme.nunito(16, weight: .bold))
                .foregroundColor(ForgeTheme.textMuted)
            
            Spacer()
            
            Text(value)
                .font(ForgeTheme.bebas(20))
                .foregroundColor(ForgeTheme.textPrimary)
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
    ProfileView()
        .environmentObject(AppState())
}
