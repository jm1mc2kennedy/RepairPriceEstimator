import SwiftUI

struct QuoteDetailView: View {
    let quote: Quote
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quote Header
                VStack(spacing: 10) {
                    AppText.quoteID(quote.id)
                    AppText.status(quote.status)
                    AppText.price(quote.total, currencyCode: quote.currencyCode)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Guest Information
                VStack(alignment: .leading, spacing: 10) {
                    AppText.sectionTitle("Guest Information")
                    
                    VStack(alignment: .leading, spacing: 5) {
                        AppText.bodyText("John Smith") // Placeholder
                        AppText.bodySecondary("john.smith@email.com")
                        AppText.bodySecondary("(555) 123-4567")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Quote Details
                VStack(alignment: .leading, spacing: 10) {
                    AppText.sectionTitle("Quote Details")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Created", value: formatDate(quote.createdAt))
                        DetailRow(label: "Updated", value: formatDate(quote.updatedAt))
                        DetailRow(label: "Valid Until", value: formatDate(quote.validUntil))
                        DetailRow(label: "Store", value: "Main Store") // Placeholder
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Line Items
                VStack(alignment: .leading, spacing: 10) {
                    AppText.sectionTitle("Line Items")
                    
                    // Placeholder line items
                    VStack(spacing: 8) {
                        LineItemRow(
                            description: "Ring Sizing Up",
                            sku: "RS-UP",
                            price: 45.00
                        )
                        
                        Divider()
                        
                        LineItemRow(
                            description: "Prong Retip (2 prongs)",
                            sku: "PR-TIP",
                            price: 50.00
                        )
                    }
                    
                    // Totals
                    VStack(spacing: 5) {
                        Divider()
                        
                        HStack {
                            AppText.fieldLabel("Subtotal")
                            Spacer()
                            AppText.priceSmall(quote.subtotal, currencyCode: quote.currencyCode)
                        }
                        
                        HStack {
                            AppText.fieldLabel("Tax")
                            Spacer()
                            AppText.priceSmall(quote.tax, currencyCode: quote.currencyCode)
                        }
                        
                        HStack {
                            AppText.bodyText("Total")
                            Spacer()
                            AppText.price(quote.total, currencyCode: quote.currencyCode)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Photos Section
                VStack(alignment: .leading, spacing: 10) {
                    AppText.sectionTitle("Photos")
                    
                    AppText.bodySecondary("No photos available")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 10) {
                    Button("Send via Email") {
                        showingShareSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Send via Text") {
                        // Implementation
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    if quote.canEdit {
                        Button("Edit Quote") {
                            // Implementation
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.backgroundSecondary)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical)
            }
            .padding()
        }
        .navigationTitle("Quote Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(quote: quote)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            AppText.fieldLabel(label)
            Spacer()
            AppText.bodySecondary(value)
        }
    }
}

struct LineItemRow: View {
    let description: String
    let sku: String
    let price: Decimal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                AppText.bodyText(description)
                AppText.caption("SKU: \(sku)")
            }
            
            Spacer()
            
            AppText.priceSmall(price)
        }
    }
}

struct ShareSheet: View {
    let quote: Quote
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                AppText.sectionTitle("Share Quote")
                
                AppText.bodyText("Quote \(quote.id) will be shared as a PDF attachment.")
                
                Button("Send Email") {
                    // Implementation for sending email
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        QuoteDetailView(quote: Quote(
            id: "Q-2025-000001",
            companyId: "company1",
            storeId: "store1",
            guestId: "guest1",
            status: .presented,
            subtotal: 95.00,
            tax: 7.60,
            total: 102.60
        ))
    }
}
