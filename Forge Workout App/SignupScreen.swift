import SwiftUI
import AuthenticationServices
import Amplify
import UIKit

struct SignupScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignUpView = false
    @State private var showSignInView = false
    @State private var hasAnimated = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var appleSignInError: String?

    var body: some View {
        ZStack {
            if appState.isSignedIn {
                // Only create OnboardingFlowView when truly authenticated
                OnboardingFlowView()
                    .environmentObject(appState)
                    .id("onboarding") // Give it a unique ID
                    .zIndex(100) // Very high z-index
            }

            if !appState.isSignedIn {
                ZStack {
                    // Base layer - black background to prevent any flash-through
                    Color.black
                        .ignoresSafeArea()
                        .zIndex(0)
                    
                    if !showSignUpView && !showSignInView {
                        loginContent
                            .zIndex(1)
                    }
                    
                    if showSignUpView {
                        SignUpView(isAuthenticated: $appState.isSignedIn, showSignUpView: $showSignUpView)
                            .environmentObject(appState)
                            .transition(.move(edge: .trailing))
                            .zIndex(2)
                    }

                    if showSignInView {
                        SignInView(isAuthenticated: $appState.isSignedIn, showSignInView: $showSignInView)
                            .environmentObject(appState)
                            .transition(.move(edge: .trailing))
                            .zIndex(2)
                    }
                }
                .zIndex(1)
            }
        }
    }

    private var loginContent: some View {
        ZStack {
            // Blue background image - MUST cover entire screen
            GeometryReader { _ in
                Image("bluebackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {

                // Animated dumbbell
                Image("dumbbell")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: hasAnimated ? 160 : 240,
                        height: hasAnimated ? 160 : 240
                    )
                    .padding(.top, hasAnimated ? 40 : 200)
                    .drawingGroup() // Hardware acceleration for the dumbbell

                // Title and subtitle appear below dumbbell
                VStack(spacing: 12) {
                    Text("WELCOME TO REP")
                        .font(ForgeTheme.bebas(56))
                        .foregroundColor(.white)
                        .tracking(2)

                    Text("THE LAST GYM APP YOU'LL EVER NEED")
                        .font(ForgeTheme.bebas(16))
                        .foregroundColor(.white)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(hasAnimated ? 1 : 0)
                .padding(.top, 12)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    // Federated sign-in through Cognito. We only mark the user
                    // signed in on a real Amplify result — no local shortcut.
                    Button {
                        Task { await signInWithApple() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sign in with Apple")
                                .font(.system(size: 19, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.black))
                    }

                    GlassEffectContainer(spacing: 12) {
                        VStack(spacing: 12) {
                            Button {
                                showSignUpView = true
                            } label: {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "B39DDB").opacity(0.5))
                                    )
                                    .cornerRadius(14)
                            }
                            
                            Button {
                                showSignInView = true
                            } label: {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "9575CD").opacity(0.45))
                                    )
                                    .cornerRadius(14)
                            }
                        }
                    }

                    Text("By continuing you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(hasAnimated ? 1 : 0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.75)) {
                    hasAnimated = true
                }
            }
        }
        .statusBarHidden(true)
        .alert(
            "Sign in with Apple",
            isPresented: Binding(
                get: { appleSignInError != nil },
                set: { if !$0 { appleSignInError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appleSignInError ?? "")
        }
    }

    /// Real federated Apple sign-in via Cognito. Only flips `isSignedIn` when
    /// Amplify reports an actual signed-in session; otherwise surfaces an error
    /// and leaves the user signed out (no fake local auth).
    @MainActor
    private func signInWithApple() async {
        do {
            let result = try await Amplify.Auth.signInWithWebUI(
                for: .apple,
                presentationAnchor: SignupScreen.presentationAnchor()
            )
            if result.isSignedIn {
                appState.isSignedIn = true
            } else {
                appleSignInError = "Sign in with Apple needs another step. Please continue with email."
            }
        } catch {
            print("❌ Apple sign-in failed: \(error)")
            appleSignInError = "Sign in with Apple isn't available right now. Please use email to continue."
        }
    }

    /// Key window used as the presentation anchor for the federated web flow.
    private static func presentationAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - SignUpView
struct SignUpView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showSignUpView: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && passwordsMatch
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ABSOLUTE full screen white background
                Color.white
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showSignUpView = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 20)
                    
                    Text("CREATE ACCOUNT")
                        .font(ForgeTheme.bebas(56))
                        .foregroundColor(.black)
                    
                    Text("Time to level up")
                        .font(ForgeTheme.nunito(18, weight: .semibold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.black)
                        
                        TextField("", text: $email, prompt: Text("your@email.com").foregroundColor(.gray.opacity(0.5)))
                            .font(ForgeTheme.nunito(18, weight: .semibold))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .padding(16)
                            .background(textFieldBackground)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.black)
                        
                        SecureField("", text: $password, prompt: Text("minimum 8 characters").foregroundColor(.gray.opacity(0.5)))
                            .font(ForgeTheme.nunito(18, weight: .semibold))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .textContentType(.newPassword)
                            .padding(16)
                            .background(textFieldBackground)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONFIRM PASSWORD")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.black)
                        
                        SecureField("", text: $confirmPassword, prompt: Text("re-enter password").foregroundColor(.gray.opacity(0.5)))
                            .font(ForgeTheme.nunito(18, weight: .semibold))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .textContentType(.newPassword)
                            .padding(16)
                            .background(confirmPasswordBackground)
                    }
                    
                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .font(ForgeTheme.nunito(14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .accentColor(.black)
                .foregroundColor(.black)
                
                Spacer()
                
                if let error = errorMessage {
                    Text(error)
                        .font(ForgeTheme.nunito(13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                
                // Submit button
                Button {
                    Task {
                        withAnimation(.none) { isLoading = true }
                        errorMessage = nil
                        do {
                            let result = try await Amplify.Auth.signUp(
                                username: email,
                                password: password,
                                options: .init(userAttributes: [
                                    AuthUserAttribute(.email, value: email)
                                ])
                            )
                            if case .confirmUser = result.nextStep {
                                showConfirmation = true
                            }
                        } catch let error as AuthError {
                            errorMessage = error.errorDescription
                        }
                        withAnimation(.none) { isLoading = false }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("CREATE ACCOUNT")
                                .font(ForgeTheme.bebas(24))
                                .tracking(2)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canSubmit ? Color(hex: "0A84FF") : Color.gray.opacity(0.3))
                    )
                }
                .disabled(!canSubmit || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        }
        .background(Color.white) // Extra layer of white
        .compositingGroup() // Force this view to be rendered as a single unit
        .sheet(isPresented: $showConfirmation) {
            ConfirmSignUpView(email: email, password: password, isAuthenticated: $isAuthenticated, showSignUpView: $showSignUpView)
                .background(Color.white)
                .compositingGroup()
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .navigationBarHidden(true)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            )
    }
    
    private var confirmPasswordBackground: some View {
        let borderColor = !confirmPassword.isEmpty && !passwordsMatch
            ? Color.red.opacity(0.8)
            : Color.gray.opacity(0.3)
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
    }
}

// MARK: - SignInView
struct SignInView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showSignInView: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showSignInView = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 20)
                    
                    Text("WELCOME BACK")
                        .font(ForgeTheme.bebas(56))
                        .foregroundColor(.black)
                    
                    Text("Sign in to continue")
                        .font(ForgeTheme.nunito(18, weight: .semibold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.black)
                        
                        TextField("", text: $email, prompt: Text("your@email.com").foregroundColor(.gray.opacity(0.5)))
                            .font(ForgeTheme.nunito(18, weight: .semibold))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .padding(16)
                            .background(textFieldBackground)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(ForgeTheme.nunito(14, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.black)
                        
                        SecureField("", text: $password, prompt: Text("enter your password").foregroundColor(.gray.opacity(0.5)))
                            .font(ForgeTheme.nunito(18, weight: .semibold))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .textContentType(.password)
                            .padding(16)
                            .background(textFieldBackground)
                    }
                }
                .padding(.horizontal, 24)
                .accentColor(.black)
                .foregroundColor(.black)
                
                Spacer()
                
                if let error = errorMessage {
                    Text(error)
                        .font(ForgeTheme.nunito(13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                
                // Submit button
                Button {
                    Task {
                        withAnimation(.none) { isLoading = true }
                        errorMessage = nil
                        do {
                            let result = try await Amplify.Auth.signIn(
                                username: email,
                                password: password
                            )
                            if result.isSignedIn {
                                await MainActor.run {
                                    isAuthenticated = true
                                }
                            }
                        } catch let error as AuthError {
                            errorMessage = error.errorDescription
                        }
                        withAnimation(.none) { isLoading = false }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("SIGN IN")
                                .font(ForgeTheme.bebas(24))
                                .tracking(2)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill((!email.isEmpty && !password.isEmpty) ? Color(hex: "0A84FF") : Color.gray.opacity(0.3))
                    )
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .navigationBarHidden(true)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            )
    }
}

// MARK: - ConfirmSignUpView
struct ConfirmSignUpView: View {
    let email: String
    let password: String
    @Binding var isAuthenticated: Bool
    @Binding var showSignUpView: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ABSOLUTE full screen white background
                Color.white
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHECK YOUR EMAIL")
                        .font(ForgeTheme.bebas(48))
                        .foregroundColor(.black)
                    
                    Text("We sent a confirmation code to \(email)")
                        .font(ForgeTheme.nunito(16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("CONFIRMATION CODE")
                        .font(ForgeTheme.nunito(14, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                    
                    OTPInputView(code: $code, isCodeFieldFocused: $isCodeFieldFocused)
                }
                
                Spacer()
                
                if let error = errorMessage {
                    Text(error)
                        .font(ForgeTheme.nunito(13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                
                // Resend Code Button
                Button {
                    Task {
                        do {
                            try await Amplify.Auth.resendSignUpCode(for: email)
                            await MainActor.run {
                                errorMessage = "✅ New code sent to your email!"
                            }
                            // Clear success message after 3 seconds
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run {
                                errorMessage = nil
                            }
                        } catch let error as AuthError {
                            errorMessage = error.errorDescription
                        }
                    }
                } label: {
                    Text("Didn't receive the code? Resend")
                        .font(ForgeTheme.nunito(13, weight: .semibold))
                        .foregroundColor(Color(hex: "0A84FF"))
                        .underline()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                Button {
                    Task {
                        withAnimation(.none) { isLoading = true }
                        errorMessage = nil
                        do {
                            // Step 1: Confirm the signup
                            try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
                            print("✅ Signup confirmed")
                            
                            // Step 2: Sign out any existing session first
                            await Amplify.Auth.signOut()
                            print("✅ Signed out any existing session")
                            
                            // Step 3: Sign in to establish a Cognito session
                            let signInResult = try await Amplify.Auth.signIn(username: email, password: password)
                            print("✅ Signed in after confirmation")
                            
                            if signInResult.isSignedIn {
                                withAnimation(.none) { isLoading = false }
                                // Dismiss the sheet
                                dismiss()
                                // Wait for sheet dismissal animation to complete
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                // Dismiss the SignUpView and authenticate
                                await MainActor.run {
                                    withAnimation(.none) {
                                        showSignUpView = false
                                        isAuthenticated = true
                                    }
                                }
                            }
                        } catch let error as AuthError {
                            errorMessage = error.errorDescription
                            withAnimation(.none) { isLoading = false }
                        }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("CONFIRM")
                                .font(ForgeTheme.bebas(24))
                                .tracking(2)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(code.count == 6 ? Color(hex: "0A84FF") : Color.gray.opacity(0.3))
                    )
                }
                .disabled(code.count != 6 || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        }
        .background(Color.white) // Extra layer of white
        .compositingGroup() // Force this view to be rendered as a single unit
        .interactiveDismissDisabled()
        .onAppear {
            // Auto-focus the OTP field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFieldFocused = true
            }
        }
    }
}

// MARK: - OTPInputView
struct OTPInputView: View {
    @Binding var code: String
    @FocusState.Binding var isCodeFieldFocused: Bool
    
    private let digitCount = 6
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate box size: subtract horizontal padding (24*2=48) and spacing (5 gaps * 8pt)
            let boxSize = (geometry.size.width - 48 - (5 * 8)) / 6
            
            ZStack {
                // Hidden TextField that captures the actual input
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFieldFocused)
                    .opacity(0)
                    .frame(width: 1, height: 1)
                    .onChange(of: code) { oldValue, newValue in
                        // Limit to digits only and max 6 characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue || filtered.count > digitCount {
                            code = String(filtered.prefix(digitCount))
                        }
                    }
                
                // Visual display of 6 digit boxes
                HStack(spacing: 8) {
                    ForEach(0..<digitCount, id: \.self) { index in
                        DigitBox(
                            digit: digitAt(index),
                            isActive: index == code.count && isCodeFieldFocused,
                            boxSize: boxSize
                        )
                    }
                }
                .frame(width: geometry.size.width - 48)
                .onTapGesture {
                    isCodeFieldFocused = true
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 64)
        .padding(.horizontal, 24)
    }
    
    private func digitAt(_ index: Int) -> String? {
        guard index < code.count else { return nil }
        let digitIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[digitIndex])
    }
}

// MARK: - DigitBox
struct DigitBox: View {
    let digit: String?
    let isActive: Bool
    let boxSize: CGFloat
    
    @State private var animateActive = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isActive ? Color(hex: "0A84FF") : Color.gray.opacity(0.25),
                            lineWidth: isActive ? 2.5 : 1.5
                        )
                )
                .frame(width: boxSize, height: 64)
                .shadow(
                    color: isActive ? Color(hex: "0A84FF").opacity(0.2) : .clear,
                    radius: isActive ? 8 : 0,
                    x: 0,
                    y: isActive ? 2 : 0
                )
            
            if let digit = digit {
                Text(digit)
                    .font(ForgeTheme.nunito(28, weight: .bold))
                    .foregroundColor(.black)
                    .transition(.scale.combined(with: .opacity))
            } else if isActive {
                // Blinking cursor effect
                Rectangle()
                    .fill(Color(hex: "0A84FF"))
                    .frame(width: 2, height: 32)
                    .opacity(animateActive ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: animateActive
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: digit)
        .onAppear {
            animateActive = true
        }
    }
}

#Preview {
    SignupScreen()
        .environmentObject(AppState())
}
