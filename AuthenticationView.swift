import SwiftUI
import AuthenticationServices

// MARK: - Authentication Coordinator
struct AuthenticationView: View {
    @State private var showingLogin = false
    @State private var showingCreateAccount = false
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            OnboardingFlowView()
        } else if showingLogin {
            LoginView(isAuthenticated: $isAuthenticated)
        } else if showingCreateAccount {
            CreateAccountView(isAuthenticated: $isAuthenticated)
        } else {
            WelcomeView(
                showingLogin: $showingLogin,
                showingCreateAccount: $showingCreateAccount
            )
        }
    }
}

// MARK: - Welcome View (Initial Screen)
struct WelcomeView: View {
    @Binding var showingLogin: Bool
    @Binding var showingCreateAccount: Bool
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo/Branding
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundColor(ForgeTheme.accentBulk)
                    
                    Text("FORGE")
                        .font(ForgeTheme.bebas(72))
                        .foregroundColor(ForgeTheme.textPrimary)
                    
                    Text("YOUR ULTIMATE WORKOUT COMPANION")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(ForgeTheme.textMuted)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingCreateAccount = true
                        }
                    } label: {
                        Text("CREATE ACCOUNT")
                            .font(ForgeTheme.bebas(22))
                            .tracking(2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(ForgeTheme.accentBulk)
                            .cornerRadius(16)
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingLogin = true
                        }
                    } label: {
                        Text("LOG IN")
                            .font(ForgeTheme.bebas(22))
                            .tracking(2)
                            .foregroundColor(ForgeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(ForgeTheme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(ForgeTheme.border, lineWidth: 2)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var animationStarted = false
    @State private var dumbbellSize: CGFloat = 220
    @State private var dumbbellOffsetY: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffsetY: CGFloat = 30
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Blue gradient background with fallback
            Color(hex: "0a84ff")
                .ignoresSafeArea()
            
            // Orange background image
            Image("organgebackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Dumbbell logo (animates)
            Image("dumbbell")
                .resizable()
                .scaledToFit()
                .frame(width: dumbbellSize, height: dumbbellSize)
                .foregroundColor(.white)
                .offset(y: dumbbellOffsetY)
            
            // Main content (fades in and slides up)
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Logo and title section
                VStack(spacing: 20) {
                    // Logo (hidden, but takes up space for layout)
                    Color.clear
                        .frame(width: 150, height: 150)
                    
                    // Title
                    Text("WELCOME TO REP")
                        .font(ForgeTheme.bebas(52))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    // Subtitle
                    Text("THE LAST GYM APP YOU'LL EVER NEED")
                        .font(ForgeTheme.bebas(16))
                        .foregroundColor(.white)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Buttons section
                VStack(spacing: 16) {
                    // Sign in with Apple button (BLACK style per Apple guidelines)
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            print("🍎 Sign in with Apple requested")
                        },
                        onCompletion: handleSignInWithApple
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(28)
                    
                    // Create Account button
                    Button {
                        // Navigate to create account
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "0a84ff"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .cornerRadius(28)
                    }
                    
                    // Sign In button
                    Button {
                        // Show login form
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    
                    // DEBUG: Skip button for testing
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isAuthenticated = true
                        }
                    } label: {
                        Text("Skip (Debug)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    
                    // Terms text
                    Text("By continuing you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffsetY)
        }
        .navigationBarHidden(true)
        .alert("Sign In Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            // Start animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    dumbbellSize = 150
                    dumbbellOffsetY = -180
                    contentOpacity = 1
                    contentOffsetY = 0
                }
            }
        }
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            print("✅ Sign in with Apple succeeded")
            
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                
                print("User ID: \(userID)")
                print("Email: \(email ?? "not provided")")
                print("Name: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")
                
                // TODO: Send credentials to your backend server for verification
                // For now, just authenticate locally
                withAnimation(.spring(response: 0.3)) {
                    isAuthenticated = true
                }
            }
            
        case .failure(let error):
            print("❌ Sign in with Apple failed: \(error)")
            
            // Handle specific error codes
            let nsError = error as NSError
            
            if nsError.code == 1000 {
                errorMessage = """
                Sign in with Apple requires proper configuration:
                
                1. Add 'Sign in with Apple' capability in Xcode
                2. Enable it in your App ID on developer.apple.com
                3. Make sure you're signed in with an Apple ID on this device
                
                For now, you can use the 'Skip (Debug)' button to test the app.
                """
            } else if nsError.code == 1001 {
                // User canceled
                print("User canceled Sign in with Apple")
                return
            } else {
                errorMessage = "Sign in failed: \(error.localizedDescription)\n\nYou can use 'Skip (Debug)' to continue testing."
            }
            
            showErrorAlert = true
        }
    }
}

// MARK: - Create Account View
struct CreateAccountView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) var dismiss
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && passwordsMatch
    }
    
    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ForgeTheme.textPrimary)
                    }
                    .padding(.bottom, 20)
                    
                    Text("CREATE ACCOUNT")
                        .font(ForgeTheme.bebas(48))
                        .foregroundColor(ForgeTheme.textPrimary)
                    
                    Text("Join the forge")
                        .font(ForgeTheme.nunito(15, weight: .semibold))
                        .foregroundColor(ForgeTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        TextField("your@email.com", text: $email)
                            .font(ForgeTheme.nunito(16, weight: .semibold))
                            .foregroundColor(ForgeTheme.textPrimary)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(textFieldBackground)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        SecureField("password", text: $password)
                            .font(ForgeTheme.nunito(16, weight: .semibold))
                            .foregroundColor(ForgeTheme.textPrimary)
                            .padding(16)
                            .background(textFieldBackground)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONFIRM PASSWORD")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(ForgeTheme.textMuted)
                        
                        SecureField("confirm password", text: $confirmPassword)
                            .font(ForgeTheme.nunito(16, weight: .semibold))
                            .foregroundColor(ForgeTheme.textPrimary)
                            .padding(16)
                            .background(confirmPasswordBackground)
                    }
                    
                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .font(ForgeTheme.nunito(12, weight: .semibold))
                            .foregroundColor(ForgeTheme.accentCut)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Submit button
                Button {
                    if canSubmit {
                        withAnimation(.spring(response: 0.3)) {
                            isAuthenticated = true
                        }
                    }
                } label: {
                    Text("CREATE ACCOUNT")
                        .font(ForgeTheme.bebas(22))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canSubmit ? ForgeTheme.accentBulk : ForgeTheme.textMuted.opacity(0.3))
                        .cornerRadius(16)
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(ForgeTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ForgeTheme.border, lineWidth: 1.5)
            )
    }
    
    private var confirmPasswordBackground: some View {
        let borderColor = !confirmPassword.isEmpty && !passwordsMatch 
            ? ForgeTheme.accentCut 
            : ForgeTheme.border
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(ForgeTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
    }
}

#Preview {
    AuthenticationView()
}
