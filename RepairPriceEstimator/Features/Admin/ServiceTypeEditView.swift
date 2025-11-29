import SwiftUI

struct ServiceTypeEditView: View {
    let serviceType: ServiceType?
    
    @State private var name: String
    @State private var category: ServiceCategory
    @State private var defaultSku: String
    @State private var defaultLaborMinutes: String
    @State private var defaultMetalUsageGrams: String
    @State private var baseRetail: String
    @State private var baseCost: String
    @State private var isActive: Bool
    
    @State private var showingDeleteAlert = false
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    init(serviceType: ServiceType?) {
        self.serviceType = serviceType
        
        // Initialize state with existing values or defaults
        if let serviceType = serviceType {
            self._name = State(initialValue: serviceType.name)
            self._category = State(initialValue: serviceType.category)
            self._defaultSku = State(initialValue: serviceType.defaultSku)
            self._defaultLaborMinutes = State(initialValue: String(serviceType.defaultLaborMinutes))
            self._defaultMetalUsageGrams = State(initialValue: serviceType.defaultMetalUsageGrams?.description ?? "")
            self._baseRetail = State(initialValue: serviceType.baseRetail.description)
            self._baseCost = State(initialValue: serviceType.baseCost.description)
            self._isActive = State(initialValue: serviceType.isActive)
        } else {
            self._name = State(initialValue: "")
            self._category = State(initialValue: .jewelryRepair)
            self._defaultSku = State(initialValue: "")
            self._defaultLaborMinutes = State(initialValue: "30")
            self._defaultMetalUsageGrams = State(initialValue: "")
            self._baseRetail = State(initialValue: "")
            self._baseCost = State(initialValue: "")
            self._isActive = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Service Information") {
                    TextField("Service Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ServiceCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .tag(category)
                        }
                    }
                    
                    TextField("Default SKU", text: $defaultSku)
                        .autocapitalization(.allCharacters)
                }
                
                Section("Labor & Materials") {
                    HStack {
                        Text("Labor Time")
                        Spacer()
                        TextField("Minutes", text: $defaultLaborMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("min")
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack {
                        Text("Metal Usage")
                        Spacer()
                        TextField("Grams", text: $defaultMetalUsageGrams)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.textSecondary)
                    }
                    
                    AppText.caption("Leave metal usage empty for services that don't require metal")
                        .foregroundColor(.textSecondary)
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Base Cost")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0.00", text: $baseCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Base Retail")
                        Spacer()
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0.00", text: $baseRetail)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                if serviceType != nil {
                    Section {
                        Button("Delete Service Type", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(serviceType == nil ? "New Service Type" : "Edit Service Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveServiceType()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
        .alert("Delete Service Type", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteServiceType()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All quotes using this service type will be affected.")
        }
        .alert("Save Result", isPresented: $showingSaveAlert) {
            Button("OK") {
                if alertMessage.contains("Success") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isValidInput: Bool {
        !name.isEmpty &&
        !defaultSku.isEmpty &&
        !defaultLaborMinutes.isEmpty &&
        !baseRetail.isEmpty &&
        !baseCost.isEmpty &&
        Int(defaultLaborMinutes) != nil &&
        Decimal(string: baseRetail) != nil &&
        Decimal(string: baseCost) != nil
    }
    
    private func saveServiceType() {
        // Validate SKU uniqueness (mock validation)
        if !isValidSKU(defaultSku) {
            alertMessage = "SKU '\(defaultSku)' is already in use. Please choose a different SKU."
            showingSaveAlert = true
            return
        }
        
        // Create or update service type
        let metalUsage = defaultMetalUsageGrams.isEmpty ? nil : Decimal(string: defaultMetalUsageGrams)
        
        let newServiceType = ServiceType(
            id: serviceType?.id ?? UUID().uuidString,
            companyId: serviceType?.companyId ?? "company1",
            name: name,
            category: category,
            defaultSku: defaultSku,
            defaultLaborMinutes: Int(defaultLaborMinutes) ?? 0,
            defaultMetalUsageGrams: metalUsage,
            baseRetail: Decimal(string: baseRetail) ?? 0,
            baseCost: Decimal(string: baseCost) ?? 0,
            isActive: isActive
        )
        
        // Save logic would go here
        print("Saving service type: \(newServiceType)")
        
        alertMessage = "Service type saved successfully!"
        showingSaveAlert = true
    }
    
    private func deleteServiceType() {
        // Delete logic would go here
        print("Deleting service type: \(serviceType?.name ?? "")")
        dismiss()
    }
    
    private func isValidSKU(_ sku: String) -> Bool {
        // Mock SKU validation - in real app, check against database
        let existingSKUs = ["RS-UP", "RS-DN", "PR-TIP", "CH-REP", "WB-REP", "UC-CLN"]
        
        if let currentSKU = serviceType?.defaultSku, currentSKU == sku {
            return true // Same SKU as current service type
        }
        
        return !existingSKUs.contains(sku)
    }
}

#Preview {
    ServiceTypeEditView(serviceType: ServiceType(
        companyId: "company1",
        name: "Ring Sizing Up",
        category: .jewelryRepair,
        defaultSku: "RS-UP",
        defaultLaborMinutes: 30,
        defaultMetalUsageGrams: 0.5,
        baseRetail: 45.00,
        baseCost: 15.00
    ))
}
