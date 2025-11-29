import SwiftUI

struct InspectionView: View {
    let guest: Guest
    @StateObject private var inspectionService = InspectionService()
    @State private var showingConditionPicker = false
    @State private var showingResults = false
    @State private var inspectionResult: InspectionResult?
    @State private var notes = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if inspectionService.isInspecting {
                    inspectionContent
                } else {
                    startInspectionContent
                }
            }
            .navigationTitle("Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if inspectionService.isInspecting {
                            inspectionService.cancelInspection()
                        }
                        dismiss()
                    }
                }
                
                if inspectionService.isInspecting {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Complete") {
                            completeInspection()
                        }
                        .disabled(inspectionService.currentInspection?.findings.isEmpty == true)
                    }
                }
            }
        }
        .sheet(isPresented: $showingConditionPicker) {
            ConditionPickerView { category, severity, description, location in
                inspectionService.addFinding(
                    category: category,
                    severity: severity,
                    description: description,
                    location: location
                )
            }
        }
        .sheet(isPresented: $showingResults) {
            if let result = inspectionResult {
                InspectionResultView(result: result) { action in
                    handleRecommendedAction(action)
                }
            }
        }
    }
    
    // MARK: - Start Inspection Content
    
    private var startInspectionContent: some View {
        VStack(spacing: 30) {
            // Guest Info
            VStack(spacing: 15) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentGold)
                
                AppText.sectionTitle(guest.fullName)
                
                if let contact = guest.contactInfo {
                    AppText.bodySecondary(contact)
                }
            }
            
            // Inspection Description
            VStack(spacing: 20) {
                AppText.sectionTitle("Inspection & Assessment")
                
                VStack(alignment: .leading, spacing: 10) {
                    AppText.fieldLabel("Initial Description")
                    TextField("Describe the jewelry piece", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            
            Spacer()
            
            // Start Button
            Button("Start Inspection") {
                Task {
                    _ = await inspectionService.startInspection(
                        guestId: guest.id,
                        inspectorId: "current-user", // TODO: Get from auth service
                        initialDescription: notes
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(notes.isEmpty)
            .padding()
        }
        .padding()
    }
    
    // MARK: - Active Inspection Content
    
    private var inspectionContent: some View {
        VStack(spacing: 20) {
            // Progress Header
            if let inspection = inspectionService.currentInspection {
                VStack(spacing: 10) {
                    AppText.bodyText(guest.fullName)
                    AppText.caption("Started: \(formatTime(inspection.startTime))")
                    
                    HStack {
                        AppText.fieldLabel("Overall Condition")
                        Spacer()
                        Text(inspection.overallCondition.displayName)
                            .font(.labelMedium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(inspection.overallCondition.color).opacity(0.2))
                            .foregroundColor(Color(inspection.overallCondition.color))
                            .cornerRadius(8)
                    }
                    
                    if !inspection.safeToClean {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.accentRed)
                            AppText.bodySecondary("UNSAFE TO CLEAN")
                                .foregroundColor(.accentRed)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            
            // Findings List
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    AppText.sectionTitle("Condition Findings")
                    Spacer()
                    Button("Add Finding") {
                        showingConditionPicker = true
                    }
                    .foregroundColor(.primaryBlue)
                }
                
                if let findings = inspectionService.currentInspection?.findings, !findings.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(findings.enumerated()), id: \.offset) { index, finding in
                                FindingRowView(finding: finding) {
                                    removeFinding(at: index)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.accentGreen)
                        AppText.bodySecondary("No issues found")
                        AppText.caption("Tap 'Add Finding' if you discover any issues")
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func completeInspection() {
        Task {
            do {
                let result = try await inspectionService.completeInspection()
                await MainActor.run {
                    inspectionResult = result
                    showingResults = true
                }
            } catch {
                print("❌ Error completing inspection: \(error)")
            }
        }
    }
    
    private func removeFinding(at index: Int) {
        guard var inspection = inspectionService.currentInspection else { return }
        inspection.findings.remove(at: index)
        inspection.updateOverallCondition()
        inspection.updateSafeToClean()
        inspectionService.currentInspection = inspection
    }
    
    private func handleRecommendedAction(_ action: RecommendedAction) {
        switch action.type {
        case .cleaning:
            // Navigate to cleaning workflow
            print("Navigate to cleaning")
        case .repairQuote:
            // Navigate to repair quote creation
            print("Navigate to repair quote")
        case .specificRepair:
            // Add specific repair to quote
            print("Add specific repair: \(action.description)")
        default:
            print("Handle action: \(action.description)")
        }
        
        dismiss()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Finding Row View

struct FindingRowView: View {
    let finding: ConditionFinding
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(finding.category.displayName)
                        .font(.labelMedium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text(finding.severity.displayName)
                        .font(.captionLarge)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(finding.severity.color).opacity(0.2))
                        .foregroundColor(Color(finding.severity.color))
                        .cornerRadius(6)
                }
                
                if let location = finding.location {
                    AppText.caption("Location: \(location)")
                }
                
                AppText.bodySecondary(finding.description)
                    .lineLimit(2)
            }
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.accentRed)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Condition Picker View

struct ConditionPickerView: View {
    let onConditionSelected: (ConditionCategory, ConditionSeverity, String, String?) -> Void
    
    @State private var selectedCategory: ConditionCategory = .general
    @State private var selectedSeverity: ConditionSeverity = .minor
    @State private var description = ""
    @State private var location = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Condition Type") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ConditionCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .tag(category)
                        }
                    }
                    
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(ConditionSeverity.allCases, id: \.self) { severity in
                            Text(severity.displayName)
                                .tag(severity)
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Location (optional)", text: $location)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Add Finding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onConditionSelected(
                            selectedCategory,
                            selectedSeverity,
                            description,
                            location.isEmpty ? nil : location
                        )
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
}

// MARK: - Inspection Result View

struct InspectionResultView: View {
    let result: InspectionResult
    let onActionSelected: (RecommendedAction) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Summary
                VStack(spacing: 15) {
                    if result.safeToClean {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentGreen)
                        AppText.sectionTitle("Safe to Clean")
                        AppText.bodySecondary("No significant issues found")
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentRed)
                        AppText.sectionTitle("Repair Required")
                        AppText.bodySecondary("Issues found that require attention")
                    }
                }
                
                // Recommended Actions
                VStack(alignment: .leading, spacing: 10) {
                    AppText.sectionTitle("Recommended Actions")
                    
                    ForEach(result.recommendedActions, id: \.id) { action in
                        Button(action: {
                            onActionSelected(action)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(action.description)
                                        .font(.labelMedium)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Priority: \(action.priority.displayName)")
                                        .font(.captionLarge)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Inspection Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InspectionView(guest: Guest(
        companyId: "company1",
        primaryStoreId: "store1",
        firstName: "John",
        lastName: "Smith",
        email: "john.smith@email.com"
    ))
}
