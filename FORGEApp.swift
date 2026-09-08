import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSPluginsCore

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
            Log.debug("✅ Amplify configured successfully")
        } catch {
            Log.debug("❌ Amplify configuration failed: \(error)")
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
                var signedIn: Bool
                do {
                    let session = try await Amplify.Auth.fetchAuthSession()
                    signedIn = session.isSignedIn

                    // `isSignedIn` can be true even when the refresh token has
                    // expired — the failure only surfaces when tokens are
                    // actually requested. Force that check now so an expired
                    // session routes to login instead of failing every API call.
                    if signedIn, let provider = session as? AuthCognitoTokensProvider,
                       case .failure = provider.getCognitoTokens() {
                        signedIn = false
                        _ = try? await Amplify.Auth.signOut()
                    }
                    Log.debug(signedIn ? "✅ Existing session restored" : "ℹ️ No active/valid session")
                } catch {
                    Log.debug("❌ Session check failed: \(error)")
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
