import SwiftUI

struct LaborRatesEditView: View {
    let role: UserRole
    let currentRate: LaborRate?
    @ObservedObject var viewModel: LaborRatesViewModel
    
    @State private var ratePerHour: String
    @State private var effectiveDate: Date
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(role: UserRole, currentRate: LaborRate?, viewModel: LaborRatesViewModel) {
        self.role = role
        self.currentRate = currentRate
        self.viewModel = viewModel
        
        if let rate = currentRate {
            _ratePerHour = State(initialValue: rate.ratePerHour.description)
            _effectiveDate = State(initialValue: rate.effectiveDate)
        } else {
            _ratePerHour = State(initialValue: "")
            _effectiveDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Role Information") {
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(role.displayName)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Section("Rate Information") {
                    HStack {
                        Text("Rate Per Hour")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0.00", text: $ratePerHour)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    DatePicker("Effective Date", selection: $effectiveDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Labor Rate")
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
                            await saveRate()
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
        guard let rateValue = Decimal(string: ratePerHour) else { return false }
        return rateValue >= 0 // Minimum wage validation can be added
    }
    
    private func saveRate() async {
        guard let rateValue = Decimal(string: ratePerHour) else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            _ = try await viewModel.updateLaborRate(role: role, ratePerHour: rateValue)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

