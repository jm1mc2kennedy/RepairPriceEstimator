import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var username: String = ""
    @State private var password: String = ""
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
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            AppText.fieldLabel("Username")
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            AppText.fieldLabel("Password")
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text("Sign In")
                                    .font(.buttonLarge)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color.primaryBlue)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading || username.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Default Credentials Info
                VStack(spacing: 10) {
                    AppText.caption("Default Credentials:")
                    VStack(spacing: 5) {
                        AppText.bodySecondary("Super Admin: SUPERadmin / SUPERadmin")
                        AppText.bodySecondary("Admin: admin / admin")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("Login Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // Attempt auto-login on view appear
            await authService.attemptAutoLogin()
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
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
