import SwiftUI
import Amplify

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SETTINGS")
                            .font(ForgeTheme.bebas(48))
                            .foregroundColor(ForgeTheme.textPrimary)
                        
                        Text("Customize your experience")
                            .font(ForgeTheme.nunito(15, weight: .light))
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                    .padding(.top, 20)
                    
                    // Workout Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WORKOUT")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        SettingRow(
                            icon: "target",
                            title: "Change Goal",
                            subtitle: "Currently: \(appState.goal.rawValue)",
                            color: appState.goal.color
                        ) {
                            // Goal selection would go here
                        }
                    }
                    
                    // App Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPEARANCE")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(ForgeTheme.accentBulk)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Theme".uppercased())
                                        .font(ForgeTheme.nunito(13, weight: .bold))
                                        .foregroundColor(ForgeTheme.textPrimary)
                                    Text("System default")
                                        .font(ForgeTheme.nunito(11, weight: .semibold))
                                        .foregroundColor(ForgeTheme.textMuted)
                                }
                            }
                            
                            Spacer()
                            
                            Text(colorScheme == .dark ? "Dark" : "Light")
                                .font(ForgeTheme.nunito(12, weight: .bold))
                                .foregroundColor(ForgeTheme.textMuted)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ForgeTheme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
                        )
                    }
                    
                    // About
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ABOUT")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        VStack(spacing: 12) {
                            SettingInfoRow(title: "App Version", value: "1.0.0")
                            SettingInfoRow(title: "Current Plan", value: "\(appState.goal.rawValue) Program")
                        }
                    }
                    
                    // Account
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT")
                            .font(ForgeTheme.nunito(11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                Text("LOG OUT")
                                    .font(ForgeTheme.nunito(13, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ForgeTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1.5))
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Log Out", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    do {
                        // Sign out from Amplify Auth first to clear Cognito session
                        await Amplify.Auth.signOut()
                        Log.debug("✅ Signed out from Amplify Auth during reset")
                    } catch {
                        Log.debug("⚠️ Error signing out during reset: \(error)")
                    }
                    
                    // Clear the workout cache to prevent data leakage between users
                    await WorkoutCache.shared.clearCache()
                    Log.debug("✅ Cleared workout cache")
                    
                    // ✅ Clear ALL UserDefaults keys to prevent stale state restoration
                    await MainActor.run {
                        let defaults = UserDefaults.standard
                        defaults.removeObject(forKey: "hasCompletedOnboarding")
                        defaults.removeObject(forKey: "userName")
                        defaults.removeObject(forKey: "goal")
                        defaults.removeObject(forKey: "streak")
                        defaults.removeObject(forKey: "weight")
                        defaults.removeObject(forKey: "height")
                        defaults.removeObject(forKey: "desiredWeight")
                        defaults.synchronize()
                        Log.debug("✅ Cleared all UserDefaults keys")
                        
                        // Then reset app state (this will re-save defaults with new values)
                        appState.isSignedIn = false
                        appState.hasCompletedOnboarding = false
                        appState.userName = "Champ"
                        appState.goal = .bulk
                        appState.streak = 0
                        appState.weight = 180
                        appState.height = 70
                        appState.desiredWeight = 170
                        Log.debug("✅ Reset AppState to defaults")
                    }
                }
            }
        } message: {
            Text("This will sign you out and clear all your local data. You can sign back in anytime.")
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(ForgeTheme.nunito(13, weight: .bold))
                        .foregroundColor(ForgeTheme.textPrimary)
                    Text(subtitle)
                        .font(ForgeTheme.nunito(11, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ForgeTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ForgeTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ForgeTheme.border, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setting Info Row
struct SettingInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(ForgeTheme.nunito(12, weight: .bold))
                .foregroundColor(ForgeTheme.textMuted)
            
            Spacer()
            
            Text(value)
                .font(ForgeTheme.nunito(13, weight: .bold))
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
    SettingsView()
        .environmentObject(AppState())
}

