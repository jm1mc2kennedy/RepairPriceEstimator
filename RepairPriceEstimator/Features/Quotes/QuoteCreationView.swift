import SwiftUI

struct QuoteCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .padding()
                
                AppText.bodySecondary("Step \(currentStep) of \(totalSteps)")
                    .padding(.bottom)
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case 1:
                        GuestSelectionStepView()
                    case 2:
                        StoreSelectionStepView()
                    case 3:
                        LineItemsStepView()
                    case 4:
                        PhotosStepView()
                    case 5:
                        ReviewStepView()
                    default:
                        AppText.bodyText("Invalid step")
                    }
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    if currentStep > 1 {
                        Button("Previous") {
                            currentStep -= 1
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                    }
                    
                    Button(currentStep == totalSteps ? "Save Quote" : "Next") {
                        if currentStep == totalSteps {
                            // Save quote logic here
                            dismiss()
                        } else {
                            currentStep += 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("New Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Step Views

struct GuestSelectionStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Select Guest")
            
            VStack(spacing: 15) {
                Button("Search Existing Guest") {
                    // Implementation
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Text("or")
                    .foregroundColor(.textSecondary)
                
                Button("Create New Guest") {
                    // Implementation
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct StoreSelectionStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Select Store")
            
            VStack(spacing: 10) {
                AppText.bodyText("Main Store")
                AppText.bodySecondary("123 Main St, Anytown, USA")
                AppText.bodySecondary("(555) 123-4567")
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primaryBlue, lineWidth: 2)
            )
            .padding()
        }
    }
}

struct LineItemsStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Add Line Items")
            
            Button("Add Service") {
                // Implementation
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
            
            AppText.bodySecondary("No line items added yet")
        }
    }
}

struct PhotosStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Add Photos")
            
            Button("Take Photo") {
                // Implementation
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.primaryBlue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
            
            AppText.bodySecondary("No photos added yet")
        }
    }
}

struct ReviewStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Review Quote")
            
            VStack(alignment: .leading, spacing: 10) {
                AppText.fieldLabel("Quote Total")
                AppText.price(Decimal(0))
                
                AppText.fieldLabel("Status")
                AppText.bodyText("Draft")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    QuoteCreationView()
}
