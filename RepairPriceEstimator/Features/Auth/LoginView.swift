import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var isSignUpMode: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentGold)
                    
                    AppText.pageTitle("Repair Price Estimator")
                    
                    AppText.bodySecondary("Professional jewelry repair pricing")
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Login/Sign Up Form
                VStack(spacing: 20) {
                    // Toggle between Sign In and Sign Up
                    Picker("Mode", selection: $isSignUpMode) {
                        Text("Sign In").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    
                    VStack(spacing: 15) {
                        if isSignUpMode {
                            VStack(alignment: .leading, spacing: 5) {
                                AppText.fieldLabel("Display Name")
                                TextField("Display Name", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                AppText.fieldLabel("Email")
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .keyboardType(.emailAddress)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            AppText.fieldLabel("Username")
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            AppText.fieldLabel("Password")
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        if isSignUpMode {
                            VStack(alignment: .leading, spacing: 5) {
                                AppText.fieldLabel("Confirm Password")
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    
                    // Sign In/Up Button
                    Button(action: {
                        if isSignUpMode {
                            handleSignUp()
                        } else {
                            handleLogin()
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text(isSignUpMode ? "Sign Up" : "Sign In")
                                    .font(.buttonLarge)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color.primaryBlue)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading || !isFormValid)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .alert("Login Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await authService.attemptAutoLogin()
        }
    }
    
    private var isFormValid: Bool {
        if isSignUpMode {
            return !username.isEmpty && !password.isEmpty && !displayName.isEmpty &&
                   !email.isEmpty && password == confirmPassword
        } else {
            return !username.isEmpty && !password.isEmpty
        }
    }
    
    private func handleLogin() {
        Task {
            do {
                let credentials = AuthCredentials(username: username, password: password)
                try await authService.authenticate(credentials: credentials)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingError = true
            return
        }
        
        Task {
            do {
                let signUpData = SignUpData(
                    username: username,
                    password: password,
                    displayName: displayName,
                    email: email
                )
                try await authService.signUp(data: signUpData)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
