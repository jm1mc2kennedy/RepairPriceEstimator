import SwiftUI

struct MetalRatesEditView: View {
    let metalType: MetalType
    let currentRate: MetalMarketRate?
    @ObservedObject var viewModel: MetalRatesViewModel
    
    @State private var rate: String
    @State private var unit: MetalUnit
    @State private var effectiveDate: Date
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(metalType: MetalType, currentRate: MetalMarketRate?, viewModel: MetalRatesViewModel) {
        self.metalType = metalType
        self.currentRate = currentRate
        self.viewModel = viewModel
        
        if let rate = currentRate {
            _rate = State(initialValue: rate.rate.description)
            _unit = State(initialValue: rate.unit)
            _effectiveDate = State(initialValue: rate.effectiveDate)
        } else {
            _rate = State(initialValue: "")
            _unit = State(initialValue: .gramsPerGram)
            _effectiveDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Metal Information") {
                    HStack {
                        Text("Metal Type")
                        Spacer()
                        Text(metalType.displayName)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Section("Rate Information") {
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0.00", text: $rate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(MetalUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    
                    DatePicker("Effective Date", selection: $effectiveDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Metal Rate")
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
        guard let rateValue = Decimal(string: rate) else { return false }
        return rateValue > 0
    }
    
    private func saveRate() async {
        guard let rateValue = Decimal(string: rate) else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            _ = try await viewModel.updateMetalRate(metalType: metalType, rate: rateValue, unit: unit)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

