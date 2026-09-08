import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ProgressTrackingView()
                .environmentObject(appState)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            
            SettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(ForgeTheme.accentBulk)
    }
}
#Preview {
    MainTabView()
        .environmentObject(AppState())
}

