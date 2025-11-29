import SwiftUI

struct CompanyEditView: View {
    @ObservedObject var viewModel: CompanySettingsViewModel
    
    @State private var name: String
    @State private var primaryContactInfo: String
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CompanySettingsViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.company?.name ?? "")
        _primaryContactInfo = State(initialValue: viewModel.company?.primaryContactInfo ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Company Information") {
                    TextField("Company Name", text: $name)
                    TextField("Primary Contact Info", text: $primaryContactInfo, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Company")
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
                            await saveCompany()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
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
        !primaryContactInfo.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveCompany() async {
        guard var company = viewModel.company else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let updatedCompany = Company(
            id: company.id,
            name: name.trimmingCharacters(in: .whitespaces),
            primaryContactInfo: primaryContactInfo.trimmingCharacters(in: .whitespaces),
            createdAt: company.createdAt
        )
        
        do {
            _ = try await viewModel.updateCompany(updatedCompany)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

