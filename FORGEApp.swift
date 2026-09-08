import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

@main
struct ForgeApp: App {
    @StateObject var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        ForgeTheme.registerFonts()
        configureAmplify()
    }

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure()
            print("✅ Amplify configured successfully")
        } catch {
            print("❌ Amplify configuration failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenCoordinator()
                .environmentObject(appState)
        }
    }
}

// App Delegate to control orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Lock to portrait orientation only
        return .portrait
    }
}

// Coordinator to handle launch screen timing
struct LaunchScreenCoordinator: View {
    @EnvironmentObject var appState: AppState
    @State private var isCheckingSession = true
    
    var body: some View {
        ZStack {
            if isCheckingSession {
                // Show blank loading screen while checking auth session
                Color.black
                    .ignoresSafeArea()
            } else if appState.isSignedIn && appState.hasCompletedOnboarding {
                // Signed in AND finished onboarding → the app.
                MainTabView()
                    .environmentObject(appState)
                    .id("mainTab")
                    .zIndex(100)
            } else {
                // Otherwise the signup flow handles login *and* onboarding,
                // branching on appState (the single source of truth).
                SignupScreen()
                    .environmentObject(appState)
                    .zIndex(1)
            }
        }
        .onAppear {
            Task {
                // The Cognito session is the source of truth for "signed in".
                // A transient error just means "treat as signed out for now" —
                // we never wipe onboarding progress here.
                let signedIn: Bool
                do {
                    let session = try await Amplify.Auth.fetchAuthSession()
                    signedIn = session.isSignedIn
                    print(session.isSignedIn ? "✅ Existing session restored" : "ℹ️ No active session")
                } catch {
                    print("❌ Session check failed: \(error)")
                    signedIn = false
                }

                await MainActor.run {
                    appState.isSignedIn = signedIn
                    isCheckingSession = false
                }
            }
        }
    }
}
