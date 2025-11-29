import SwiftUI

struct PricingRulesEditView: View {
    let pricingRule: PricingRule?
    @ObservedObject var viewModel: PricingRulesViewModel
    
    @State private var name: String
    @State private var description: String
    @State private var metalMarkup: String
    @State private var laborMarkup: String
    @State private var fixedFee: String
    @State private var rushMultiplier: String
    @State private var minimumCharge: String
    @State private var allowManualOverride: Bool
    @State private var overrideThreshold: String
    @State private var isActive: Bool
    
    @State private var isSaving = false
    @State private var showingDeleteAlert = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    init(pricingRule: PricingRule?, viewModel: PricingRulesViewModel) {
        self.pricingRule = pricingRule
        self.viewModel = viewModel
        
        if let rule = pricingRule {
            _name = State(initialValue: rule.name)
            _description = State(initialValue: rule.description)
            _metalMarkup = State(initialValue: String(describing: rule.formulaDefinition.metalMarkupPercentage))
            _laborMarkup = State(initialValue: String(describing: rule.formulaDefinition.laborMarkupPercentage))
            _fixedFee = State(initialValue: rule.formulaDefinition.fixedFee.description)
            _rushMultiplier = State(initialValue: String(describing: rule.formulaDefinition.rushMultiplier))
            _minimumCharge = State(initialValue: rule.formulaDefinition.minimumCharge?.description ?? "")
            _allowManualOverride = State(initialValue: rule.allowManualOverride)
            _overrideThreshold = State(initialValue: rule.requireManagerApprovalIfOverrideExceedsPercent?.description ?? "10.0")
            _isActive = State(initialValue: rule.isActive)
        } else {
            _name = State(initialValue: "")
            _description = State(initialValue: "")
            _metalMarkup = State(initialValue: "2.0")
            _laborMarkup = State(initialValue: "1.5")
            _fixedFee = State(initialValue: "0")
            _rushMultiplier = State(initialValue: "1.5")
            _minimumCharge = State(initialValue: "")
            _allowManualOverride = State(initialValue: true)
            _overrideThreshold = State(initialValue: "10.0")
            _isActive = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rule Information") {
                    TextField("Rule Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Pricing Formula") {
                    HStack {
                        Text("Metal Markup")
                        Spacer()
                        TextField("%", text: $metalMarkup)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack {
                        Text("Labor Markup")
                        Spacer()
                        TextField("%", text: $laborMarkup)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack {
                        Text("Fixed Fee")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0.00", text: $fixedFee)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Rush Multiplier")
                        Spacer()
                        TextField("1.5", text: $rushMultiplier)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Minimum Charge")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("Optional", text: $minimumCharge)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Override Settings") {
                    Toggle("Allow Manual Override", isOn: $allowManualOverride)
                    
                    if allowManualOverride {
                        HStack {
                            Text("Approval Threshold")
                            Spacer()
                            TextField("%", text: $overrideThreshold)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("%")
                                .foregroundColor(.textSecondary)
                        }
                        AppText.caption("Requires manager approval if discount exceeds this percentage")
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                if pricingRule != nil {
                    Section {
                        Button("Delete Rule", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(pricingRule == nil ? "New Pricing Rule" : "Edit Pricing Rule")
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
                            await saveRule()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .alert("Delete Pricing Rule", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteRule()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
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
        Decimal(string: metalMarkup) != nil &&
        Decimal(string: laborMarkup) != nil &&
        Decimal(string: fixedFee) != nil &&
        Decimal(string: rushMultiplier) != nil &&
        (minimumCharge.isEmpty || Decimal(string: minimumCharge) != nil) &&
        (overrideThreshold.isEmpty || Decimal(string: overrideThreshold) != nil)
    }
    
    private func saveRule() async {
        guard let session = authService.currentSession else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let formula = PricingFormula(
            metalMarkupPercentage: Decimal(string: metalMarkup) ?? 2.0,
            laborMarkupPercentage: Decimal(string: laborMarkup) ?? 1.5,
            fixedFee: Decimal(string: fixedFee) ?? 0,
            rushMultiplier: Decimal(string: rushMultiplier) ?? 1.5,
            minimumCharge: minimumCharge.isEmpty ? nil : Decimal(string: minimumCharge)
        )
        
        let rule = PricingRule(
            id: pricingRule?.id ?? UUID().uuidString,
            companyId: session.company.id,
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            formulaDefinition: formula,
            allowManualOverride: allowManualOverride,
            requireManagerApprovalIfOverrideExceedsPercent: allowManualOverride ? (Decimal(string: overrideThreshold) ?? 10.0) : nil,
            isActive: isActive
        )
        
        do {
            _ = try await viewModel.updatePricingRule(rule)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
    
    private func deleteRule() async {
        guard let rule = pricingRule else { return }
        
        // Deactivate instead of hard delete
        let deactivatedRule = PricingRule(
            id: rule.id,
            companyId: rule.companyId,
            name: rule.name,
            description: rule.description,
            formulaDefinition: rule.formulaDefinition,
            allowManualOverride: rule.allowManualOverride,
            requireManagerApprovalIfOverrideExceedsPercent: rule.requireManagerApprovalIfOverrideExceedsPercent,
            isActive: false
        )
        
        do {
            _ = try await viewModel.updatePricingRule(deactivatedRule)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

