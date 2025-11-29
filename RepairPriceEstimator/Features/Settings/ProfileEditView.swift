import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Display Name", text: $displayName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
                
                Section("Company Information") {
                    if let session = authService.currentSession {
                        DetailRow(label: "Company", value: session.company.name)
                        DetailRow(label: "Role", value: session.user.role.displayName)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .onAppear {
                if let session = authService.currentSession {
                    displayName = session.user.displayName
                    email = session.user.email
                }
            }
            .alert("Error", isPresented: $showingError, presenting: errorMessage) { _ in
                Button("OK") { }
            } message: { error in
                Text(error)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Profile updated successfully")
            }
        }
    }
    
    private var isValidInput: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }
    
    private func saveProfile() async {
        guard let session = authService.currentSession else { return }
        guard isValidInput else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            var updatedUser = session.user
            // Note: User is a struct, so we need to create a new instance
            // Since User doesn't have a mutable initializer, we'll need to check the model
            // For now, we'll use the repository to update
            let updatedUserModel = User(
                id: updatedUser.id,
                companyId: updatedUser.companyId,
                storeIds: updatedUser.storeIds,
                role: updatedUser.role,
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                isActive: updatedUser.isActive,
                createdAt: updatedUser.createdAt
            )
            
            _ = try await CloudKitService.shared.save(updatedUserModel)
            
            // Refresh session
            await authService.refreshSession()
            
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

