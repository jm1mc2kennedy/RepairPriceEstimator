import SwiftUI

/// Mandatory intake checklist view enforcing all Springer's requirements
struct MandatoryIntakeView: View {
    let guest: Guest
    @State private var intakeData = IntakeFormData()
    @State private var showingErrors = false
    @State private var validationErrors: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    // Rush Flag
                    HStack {
                        Toggle("Rush Job", isOn: $intakeData.isRush)
                        if intakeData.isRush {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.rushIndicator)
                        }
                    }
                    
                    if intakeData.isRush {
                        Picker("Rush Type", selection: $intakeData.rushType) {
                            ForEach(RushType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    // Salesperson
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Salesperson *")
                        TextField("Salesperson name or ID", text: $intakeData.salesperson)
                    }
                    
                    // Repair Type
                    Picker("Repair Type *", selection: $intakeData.repairType) {
                        ForEach(ServiceCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                // Description Section
                Section("Description & Condition") {
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Short Description *")
                        TextField("Brief description for job bag", text: $intakeData.shortDescription)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("SKU (if applicable)")
                        TextField("Service SKU", text: $intakeData.sku)
                            .autocapitalization(.allCharacters)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Extended Description *")
                        TextField("Detailed condition and work needed", text: $intakeData.extendedDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Condition Notes *")
                        TextField("Current condition assessment", text: $intakeData.conditionNotes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                // Photos Section
                Section("Photos") {
                    HStack {
                        Toggle("Photos Required", isOn: $intakeData.photosRequired)
                        Spacer()
                        if intakeData.photosRequired {
                            Text("\(intakeData.photosCaptured) taken")
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if intakeData.photosRequired {
                        Button("Capture Photos") {
                            // TODO: Integrate with photo capture
                            intakeData.photosCaptured += 1
                        }
                        .disabled(intakeData.photosCaptured >= 5)
                    }
                }
                
                // Estimate & Approval Section
                Section("Estimate & Approval") {
                    Toggle("Estimate Required", isOn: $intakeData.estimateRequired)
                    
                    if intakeData.estimateRequired {
                        HStack {
                            Text("Pre-approved Limit")
                            Spacer()
                            Text("$")
                            TextField("0.00", text: $intakeData.preApprovedLimit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Instructions/Charges Notes")
                        TextField("Special instructions or charge notes", text: $intakeData.instructionsNotes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                // Shipping & Deposits Section
                Section("Shipping & Deposits") {
                    Toggle("Shipping Deposit Taken", isOn: $intakeData.shippingDepositTaken)
                    
                    if intakeData.shippingDepositTaken {
                        HStack {
                            Text("Deposit Amount")
                            Spacer()
                            Text("$")
                            TextField("0.00", text: $intakeData.shippingDepositAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }
                
                // Due Date Section
                Section("Due Date") {
                    DatePicker("Requested Due Date", selection: $intakeData.requestedDueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Promised Due Date *", selection: $intakeData.promisedDueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Due Date Realistic", isOn: $intakeData.dueDateRealistic)
                    
                    if !intakeData.dueDateRealistic {
                        AppText.caption("⚠️ Due date may not align with service requirements")
                            .foregroundColor(.accentRed)
                    }
                }
                
                // Springer's Item Section
                Section("Springer's Purchase") {
                    Toggle("Purchased at Springer's", isOn: $intakeData.springersItem)
                    
                    if intakeData.springersItem {
                        VStack(alignment: .leading, spacing: 4) {
                            AppText.fieldLabel("Sales SKU")
                            TextField("Original sales SKU", text: $intakeData.salesSku)
                                .autocapitalization(.allCharacters)
                        }
                    }
                }
                
                // Additional Flags Section
                Section("Additional Information") {
                    Toggle("High Value Item", isOn: $intakeData.highValue)
                    Toggle("Insurance Required", isOn: $intakeData.insuranceRequired)
                    Toggle("Customer Present", isOn: $intakeData.customerPresent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        AppText.fieldLabel("Special Handling")
                        TextField("Special handling requirements", text: $intakeData.specialHandling)
                    }
                }
            }
            .navigationTitle("Intake Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeIntake()
                    }
                    .disabled(!isIntakeComplete)
                }
            }
        }
        .alert("Validation Errors", isPresented: $showingErrors) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }
    
    private var isIntakeComplete: Bool {
        !intakeData.salesperson.isEmpty &&
        !intakeData.shortDescription.isEmpty &&
        !intakeData.extendedDescription.isEmpty &&
        !intakeData.conditionNotes.isEmpty &&
        (!intakeData.photosRequired || intakeData.photosCaptured > 0) &&
        (!intakeData.shippingDepositTaken || !intakeData.shippingDepositAmount.isEmpty)
    }
    
    private func completeIntake() {
        // Validate all required fields
        validationErrors = validateIntakeData()
        
        if !validationErrors.isEmpty {
            showingErrors = true
            return
        }
        
        // Create intake checklist from form data
        _ = IntakeChecklist(
            quoteId: "", // Will be set when quote is created
            inspectorId: "current-user", // TODO: Get from auth service
            findings: [], // Will be populated from inspection
            overallCondition: .minor,
            safeToClean: true,
            isRush: intakeData.isRush,
            salespersonId: intakeData.salesperson,
            repairType: intakeData.repairType,
            photosRequired: intakeData.photosRequired,
            photosCaptured: intakeData.photosCaptured,
            shortDescription: intakeData.shortDescription,
            extendedDescription: intakeData.extendedDescription,
            conditionNotes: intakeData.conditionNotes,
            estimateRequired: intakeData.estimateRequired,
            preApprovedLimit: Decimal(string: intakeData.preApprovedLimit),
            requiresApproval: intakeData.estimateRequired && intakeData.preApprovedLimit.isEmpty,
            shippingDepositTaken: intakeData.shippingDepositTaken,
            shippingDepositAmount: Decimal(string: intakeData.shippingDepositAmount),
            specialHandling: intakeData.specialHandling.isEmpty ? nil : intakeData.specialHandling,
            requestedDueDate: intakeData.requestedDueDate,
            promisedDueDate: intakeData.promisedDueDate,
            dueDateRealistic: intakeData.dueDateRealistic,
            springersItem: intakeData.springersItem,
            highValue: intakeData.highValue,
            insuranceRequired: intakeData.insuranceRequired,
            customerPresent: intakeData.customerPresent
        )
        
        // TODO: Save checklist and proceed to quote creation
        print("✅ Intake checklist completed")
        dismiss()
    }
    
    private func validateIntakeData() -> [String] {
        var errors: [String] = []
        
        // Required fields
        if intakeData.salesperson.isEmpty {
            errors.append("Salesperson is required")
        }
        
        if intakeData.shortDescription.isEmpty {
            errors.append("Short description is required")
        }
        
        if intakeData.extendedDescription.isEmpty {
            errors.append("Extended description is required")
        }
        
        if intakeData.conditionNotes.isEmpty {
            errors.append("Condition notes are required")
        }
        
        // Photo requirement
        if intakeData.photosRequired && intakeData.photosCaptured == 0 {
            errors.append("Photos are required but none have been captured")
        }
        
        // Due date validation
        if intakeData.requestedDueDate > intakeData.promisedDueDate {
            errors.append("Promised due date cannot be earlier than requested due date")
        }
        
        // Rush validation
        if intakeData.isRush {
            let hoursUntilDue = intakeData.promisedDueDate.timeIntervalSinceNow / 3600
            
            if intakeData.rushType == .sameDay && hoursUntilDue > 24 {
                errors.append("Same-day rush selected but due date is more than 24 hours away")
            }
            
            if intakeData.rushType == .within48Hours && hoursUntilDue > 48 {
                errors.append("48-hour rush selected but due date is more than 48 hours away")
            }
        }
        
        // Shipping deposit validation
        if intakeData.shippingDepositTaken && intakeData.shippingDepositAmount.isEmpty {
            errors.append("Shipping deposit amount is required when deposit is taken")
        }
        
        // Springer's item validation
        if intakeData.springersItem && intakeData.salesSku.isEmpty {
            errors.append("Sales SKU is required for Springer's items")
        }
        
        return errors
    }
}

// MARK: - Intake Form Data

struct IntakeFormData {
    // Basic information
    var isRush = false
    var rushType: RushType = .standard
    var salesperson = ""
    var repairType: ServiceCategory = .jewelryRepair
    
    // Description
    var shortDescription = ""
    var sku = ""
    var extendedDescription = ""
    var conditionNotes = ""
    
    // Photos
    var photosRequired = true
    var photosCaptured = 0
    
    // Estimate & Approval
    var estimateRequired = true
    var preApprovedLimit = ""
    var instructionsNotes = ""
    
    // Shipping & Deposits
    var shippingDepositTaken = false
    var shippingDepositAmount = ""
    
    // Due Dates
    var requestedDueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var promisedDueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var dueDateRealistic = true
    
    // Springer's Information
    var springersItem = false
    var salesSku = ""
    
    // Additional Flags
    var highValue = false
    var insuranceRequired = false
    var customerPresent = true
    var specialHandling = ""
}

// MARK: - Validation Helper View

struct ValidationErrorBanner: View {
    let errors: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.accentRed)
                
                Text("\(errors.count) validation error\(errors.count == 1 ? "" : "s")")
                    .font(.labelMedium)
                    .foregroundColor(.accentRed)
                
                Spacer()
                
                Button(isExpanded ? "Hide" : "Show") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .foregroundColor(.primaryBlue)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(errors.enumerated()), id: \.offset) { index, error in
                        Text("• \(error)")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.accentRed.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Intake Progress Indicator

struct IntakeProgressView: View {
    let completedFields: Int
    let totalFields: Int
    
    private var progress: Double {
        guard totalFields > 0 else { return 0 }
        return Double(completedFields) / Double(totalFields)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                AppText.fieldLabel("Completion Progress")
                Spacer()
                Text("\(completedFields)/\(totalFields)")
                    .font(.labelMedium)
                    .foregroundColor(.textSecondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress == 1.0 ? .accentGreen : .primaryBlue))
            
            if progress == 1.0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentGreen)
                    AppText.caption("All required fields completed")
                        .foregroundColor(.accentGreen)
                }
            }
        }
    }
}

// MARK: - Due Date Validation View

struct DueDateValidationView: View {
    let requestedDate: Date
    let promisedDate: Date
    let rushType: RushType
    
    private var validationStatus: ValidationStatus {
        let hoursUntilDue = promisedDate.timeIntervalSinceNow / 3600
        
        if promisedDate < requestedDate {
            return .error("Promised date is earlier than requested date")
        }
        
        switch rushType {
        case .sameDay:
            if hoursUntilDue > 24 {
                return .error("Same-day rush requires completion within 24 hours")
            }
            
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= RushType.sameDayCutoff {
                return .warning("Same-day request after 2PM requires coordinator approval")
            }
            
            return .valid
            
        case .within48Hours:
            if hoursUntilDue > 48 {
                return .error("48-hour rush requires completion within 48 hours")
            }
            return .valid
            
        case .standard:
            if hoursUntilDue < 24 {
                return .warning("Standard service promised within 24 hours - consider rush pricing")
            }
            return .valid
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: validationStatus.icon)
                .foregroundColor(Color(validationStatus.color))
            
            Text(validationStatus.message)
                .font(.captionLarge)
                .foregroundColor(Color(validationStatus.color))
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private enum ValidationStatus {
        case valid
        case warning(String)
        case error(String)
        
        var icon: String {
            switch self {
            case .valid: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .valid: return "green"
            case .warning: return "orange"
            case .error: return "red"
            }
        }
        
        var message: String {
            switch self {
            case .valid: return "Due date looks good"
            case .warning(let msg), .error(let msg): return msg
            }
        }
    }
}

#Preview {
    MandatoryIntakeView(guest: Guest(
        companyId: "company1",
        primaryStoreId: "store1",
        firstName: "John",
        lastName: "Smith",
        email: "john.smith@email.com"
    ))
}
