import SwiftUI

struct UserEditView: View {
    let user: User?
    @ObservedObject var viewModel: UserManagementViewModel
    
    @State private var displayName: String
    @State private var email: String
    @State private var role: UserRole
    @State private var selectedStoreIds: Set<String>
    @State private var isActive: Bool
    @State private var availableStores: [Store] = []
    
    @State private var isSaving = false
    @State private var showingDeleteAlert = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    init(user: User?, viewModel: UserManagementViewModel) {
        self.user = user
        self.viewModel = viewModel
        
        if let user = user {
            _displayName = State(initialValue: user.displayName)
            _email = State(initialValue: user.email)
            _role = State(initialValue: user.role)
            _selectedStoreIds = State(initialValue: Set(user.storeIds))
            _isActive = State(initialValue: user.isActive)
        } else {
            _displayName = State(initialValue: "")
            _email = State(initialValue: "")
            _role = State(initialValue: .associate)
            _selectedStoreIds = State(initialValue: [])
            _isActive = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Display Name", text: $displayName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .disabled(user != nil) // Can't change email for existing users
                }
                
                Section("Role & Access") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    
                    if !availableStores.isEmpty {
                        List {
                            ForEach(availableStores) { store in
                                Toggle(store.name, isOn: Binding(
                                    get: { selectedStoreIds.contains(store.id) },
                                    set: { isOn in
                                        if isOn {
                                            selectedStoreIds.insert(store.id)
                                        } else {
                                            selectedStoreIds.remove(store.id)
                                        }
                                    }
                                ))
                            }
                        }
                        .frame(height: CGFloat(availableStores.count * 44))
                    }
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                if user != nil {
                    Section {
                        Button("Deactivate User", role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .disabled(!isActive)
                    }
                }
            }
            .navigationTitle(user == nil ? "New User" : "Edit User")
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
                            await saveUser()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .alert("Deactivate User", isPresented: $showingDeleteAlert) {
                Button("Deactivate", role: .destructive) {
                    Task {
                        await deactivateUser()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This user will no longer be able to access the system.")
            }
            .alert("Error", isPresented: $showingSaveError, presenting: saveError) { _ in
                Button("OK") { }
            } message: { error in
                Text(error)
            }
            .task {
                await loadStores()
            }
        }
    }
    
    private var isValidInput: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        !selectedStoreIds.isEmpty
    }
    
    private func loadStores() async {
        guard let session = authService.currentSession else { return }
        do {
            let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", session.company.id)
            availableStores = try await CloudKitService.shared.query(Store.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        } catch {
            print("❌ Error loading stores: \(error)")
        }
    }
    
    private func saveUser() async {
        guard let session = authService.currentSession else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let updatedUser = User(
            id: user?.id ?? UUID().uuidString,
            companyId: session.company.id,
            storeIds: Array(selectedStoreIds),
            role: role,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            isActive: isActive,
            createdAt: user?.createdAt ?? Date()
        )
        
        do {
            if user == nil {
                _ = try await viewModel.createUser(updatedUser)
            } else {
                _ = try await viewModel.updateUser(updatedUser)
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
    
    private func deactivateUser() async {
        guard let user = user else { return }
        
        do {
            try await viewModel.deactivateUser(user)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

