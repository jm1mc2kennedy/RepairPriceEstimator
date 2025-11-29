import SwiftUI
import UIKit

struct QuoteDetailView: View {
    let quoteId: String
    @StateObject private var viewModel: QuoteDetailViewModel
    private let shareService = ShareService()
    private let pdfGenerator = PDFGenerator()
    @State private var showingShareSheet = false
    @State private var showingStatusPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var sharingError: String?
    @State private var showingSharingError = false
    @State private var pdfDataToShare: Data?
    @State private var shareSubject: String = ""
    
    init(quoteId: String) {
        self.quoteId = quoteId
        self._viewModel = StateObject(wrappedValue: QuoteDetailViewModel(quoteId: quoteId))
    }
    
    // Convenience initializer for backwards compatibility
    init(quote: Quote) {
        self.quoteId = quote.id
        self._viewModel = StateObject(wrappedValue: QuoteDetailViewModel(quoteId: quote.id))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.quote == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let quote = viewModel.quote {
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
                            
                            if let guest = viewModel.guest {
                                VStack(alignment: .leading, spacing: 5) {
                                    AppText.bodyText(guest.fullName)
                                    if let email = guest.email {
                                        AppText.bodySecondary(email)
                                    }
                                    if let phone = guest.phone {
                                        AppText.bodySecondary(phone)
                                    }
                                }
                            } else {
                                AppText.bodySecondary("Loading guest information...")
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
                                if let store = viewModel.store {
                                    DetailRow(label: "Store", value: store.name)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        // Line Items
                        VStack(alignment: .leading, spacing: 10) {
                            AppText.sectionTitle("Line Items")
                            
                            if viewModel.lineItems.isEmpty {
                                AppText.bodySecondary("No line items")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.lineItems) { lineItem in
                                        LineItemRow(
                                            description: lineItem.description,
                                            sku: lineItem.sku,
                                            price: lineItem.finalRetail
                                        )
                                        
                                        if lineItem.id != viewModel.lineItems.last?.id {
                                            Divider()
                                        }
                                    }
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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        // Photos Section
                        VStack(alignment: .leading, spacing: 10) {
                            AppText.sectionTitle("Photos")
                            
                            if viewModel.photos.isEmpty {
                                AppText.bodySecondary("No photos available")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(viewModel.photos) { photo in
                                            AsyncImage(url: photo.assetURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                
                        // Action Buttons
                        VStack(spacing: 10) {
                            Button("Send via Email") {
                                sendViaEmail()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(viewModel.guest?.email == nil)
                            
                            Button("Send via Text") {
                                sendViaSMS()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accentGreen)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(viewModel.guest?.phone == nil)
                            
                            if quote.status.canEdit {
                                Button("Update Status") {
                                    showingStatusPicker = true
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
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.accentRed)
                    AppText.bodyText("Quote not found")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Quote Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadQuoteDetails()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfDataToShare {
                ShareSheetViewController(pdfData: pdfData, subject: shareSubject)
            }
        }
        .sheet(isPresented: $showingStatusPicker) {
            if let quote = viewModel.quote {
                StatusPickerSheet(quote: quote) { newStatus in
                    Task {
                        await viewModel.updateStatus(newStatus)
                        showingStatusPicker = false
                        await viewModel.refresh()
                    }
                }
            }
        }
        .confirmationDialog("Delete Quote", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteQuote()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this quote? This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if let quote = viewModel.quote, !quote.status.canEdit {
                        Button("Update Status") {
                            showingStatusPicker = true
                        }
                    }
                    Button("Delete Quote", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    Button("Refresh") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
        .alert("Sharing Error", isPresented: $showingSharingError, presenting: sharingError) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
    }
    
    private func sendViaEmail() {
        guard let quote = viewModel.quote,
              let guest = viewModel.guest,
              let store = viewModel.store else {
            sharingError = "Missing quote information"
            showingSharingError = true
            return
        }
        
        // Generate PDF
        let pdfData = pdfGenerator.generatePDF(
            quote: quote,
            guest: guest,
            store: store,
            lineItems: viewModel.lineItems,
            photos: viewModel.photos
        )
        
        // Try to open email app directly
        if let emailURL = shareService.shareQuoteViaEmail(
            quote: quote,
            guest: guest,
            lineItems: viewModel.lineItems,
            pdfData: pdfData
        ) {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                // Fallback: show share sheet with PDF
                pdfDataToShare = pdfData
                shareSubject = "Repair Quote: \(quote.id)"
                showingShareSheet = true
            }
        } else {
            // No email address, show share sheet anyway
            pdfDataToShare = pdfData
            shareSubject = "Repair Quote: \(quote.id)"
            showingShareSheet = true
        }
    }
    
    private func sendViaSMS() {
        guard let quote = viewModel.quote,
              let guest = viewModel.guest else {
            sharingError = "Missing quote information"
            showingSharingError = true
            return
        }
        
        if let smsURL = shareService.shareQuoteViaSMS(
            quote: quote,
            guest: guest,
            lineItems: viewModel.lineItems
        ) {
            if UIApplication.shared.canOpenURL(smsURL) {
                UIApplication.shared.open(smsURL)
            } else {
                sharingError = "SMS is not available on this device"
                showingSharingError = true
            }
        } else {
            sharingError = "Could not create SMS. Please ensure the guest has a phone number."
            showingSharingError = true
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
    private let pdfGenerator = PDFGenerator()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                AppText.sectionTitle("Share Quote")
                
                AppText.bodyText("Quote \(quote.id) will be shared as a PDF attachment.")
                
                Button("Share PDF") {
                    sharePDF()
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
    
    private func sharePDF() {
        // Generate PDF (this would need quote, guest, store, lineItems from viewModel)
        // For now, just dismiss - actual implementation would be in QuoteDetailView
        dismiss()
    }
}

struct StatusPickerSheet: View {
    let quote: Quote
    let onStatusSelected: (QuoteStatus) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(quote.status.possibleNextStatuses, id: \.self) { status in
                    Button(action: {
                        onStatusSelected(status)
                    }) {
                        HStack {
                            Text(status.displayName)
                            Spacer()
                            if status == quote.status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Update Status")
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
        QuoteDetailView(quoteId: "Q-2025-000001")
    }
}
