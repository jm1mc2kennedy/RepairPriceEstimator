import SwiftUI

struct ServiceTypeEditView: View {
    let serviceType: ServiceType?
    @ObservedObject var viewModel: ServiceTypeListViewModel
    
    @State private var name: String
    @State private var category: ServiceCategory
    @State private var defaultSku: String
    @State private var defaultLaborMinutes: String
    @State private var defaultMetalUsageGrams: String
    @State private var baseRetail: String
    @State private var baseCost: String
    @State private var isActive: Bool
    
    @State private var showingDeleteAlert = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    init(serviceType: ServiceType?, viewModel: ServiceTypeListViewModel) {
        self.serviceType = serviceType
        self.viewModel = viewModel
        
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
                        Task {
                            await saveServiceType()
                        }
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .disabled(isSaving)
        }
        .alert("Delete Service Type", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteServiceType()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All quotes using this service type will be affected.")
        }
        .alert("Error", isPresented: $showingSaveError, presenting: saveError) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
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
    
    private func saveServiceType() async {
        guard let session = authService.currentSession else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let metalUsage = defaultMetalUsageGrams.isEmpty ? nil : Decimal(string: defaultMetalUsageGrams)
        
        let updatedServiceType = ServiceType(
            id: serviceType?.id ?? UUID().uuidString,
            companyId: serviceType?.companyId ?? session.company.id,
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            defaultSku: defaultSku.trimmingCharacters(in: .whitespaces).uppercased(),
            defaultLaborMinutes: Int(defaultLaborMinutes) ?? 0,
            defaultMetalUsageGrams: metalUsage,
            baseRetail: Decimal(string: baseRetail) ?? 0,
            baseCost: Decimal(string: baseCost) ?? 0,
            isActive: isActive
        )
        
        do {
            if serviceType == nil {
                _ = try await viewModel.createServiceType(updatedServiceType)
            } else {
                _ = try await viewModel.updateServiceType(updatedServiceType)
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
    
    private func deleteServiceType() async {
        guard let serviceType = serviceType else { return }
        
        do {
            try await viewModel.deleteServiceType(serviceType)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

#Preview {
    ServiceTypeEditView(
        serviceType: ServiceType(
            companyId: "company1",
            name: "Ring Sizing Up",
            category: .jewelryRepair,
            defaultSku: "RS-UP",
            defaultLaborMinutes: 30,
            defaultMetalUsageGrams: 0.5,
            baseRetail: 45.00,
            baseCost: 15.00
        ),
        viewModel: ServiceTypeListViewModel()
    )
}
