import SwiftUI

struct StoreEditView: View {
    let store: Store?
    @ObservedObject var viewModel: CompanySettingsViewModel
    
    @State private var name: String
    @State private var storeCode: String
    @State private var location: String
    @State private var phone: String
    @State private var isActive: Bool
    
    @State private var isSaving = false
    @State private var showingDeleteAlert = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    init(store: Store?, viewModel: CompanySettingsViewModel) {
        self.store = store
        self.viewModel = viewModel
        
        if let store = store {
            _name = State(initialValue: store.name)
            _storeCode = State(initialValue: store.storeCode)
            _location = State(initialValue: store.location)
            _phone = State(initialValue: store.phone)
            _isActive = State(initialValue: store.isActive)
        } else {
            _name = State(initialValue: "")
            _storeCode = State(initialValue: "")
            _location = State(initialValue: "")
            _phone = State(initialValue: "")
            _isActive = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Store Information") {
                    TextField("Store Name", text: $name)
                    TextField("Store Code", text: $storeCode)
                        .autocapitalization(.allCharacters)
                    TextField("Location", text: $location)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                if store != nil {
                    Section {
                        Button("Deactivate Store", role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .disabled(!isActive)
                    }
                }
            }
            .navigationTitle(store == nil ? "New Store" : "Edit Store")
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
                            await saveStore()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .alert("Deactivate Store", isPresented: $showingDeleteAlert) {
                Button("Deactivate", role: .destructive) {
                    Task {
                        await deactivateStore()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This store will be deactivated and hidden from active selections.")
            }
            .alert("Error", isPresented: $showingSaveError, presenting: saveError) { _ in
                Button("OK") { }
            } message: { error in
                Text(error)
            }
        }
    }
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveStore() async {
        guard let session = authService.currentSession else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let updatedStore = Store(
            id: store?.id ?? UUID().uuidString,
            companyId: session.company.id,
            name: name.trimmingCharacters(in: .whitespaces),
            storeCode: storeCode.trimmingCharacters(in: .whitespaces).uppercased(),
            location: location.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            isActive: isActive
        )
        
        do {
            if store == nil {
                _ = try await viewModel.createStore(updatedStore)
            } else {
                _ = try await viewModel.updateStore(updatedStore)
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
    
    private func deactivateStore() async {
        guard let store = store else { return }
        
        do {
            try await viewModel.deleteStore(store)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

