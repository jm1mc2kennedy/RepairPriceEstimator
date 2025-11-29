import SwiftUI

struct GuestDetailView: View {
    let guest: Guest
    @State private var showingNewQuote = false
    @State private var showingEditGuest = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Guest Info Card
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        AppText.sectionTitle(guest.fullName)
                        Spacer()
                        Button("Edit") {
                            showingEditGuest = true
                        }
                        .foregroundColor(.primaryBlue)
                    }
                    
                    if let email = guest.email {
                        DetailRow(label: "Email", value: email)
                    }
                    
                    if let phone = guest.phone {
                        DetailRow(label: "Phone", value: phone)
                    }
                    
                    if let notes = guest.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            AppText.fieldLabel("Notes")
                            AppText.bodySecondary(notes)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Quick Actions
                VStack(spacing: 10) {
                    Button("Create New Quote") {
                        showingNewQuote = true
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    if let email = guest.email {
                        Button("Send Email") {
                            // Open mail app
                            if let emailURL = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(emailURL)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if let phone = guest.phone {
                        Button("Call Guest") {
                            // Open phone app
                            let phoneNumber = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let phoneURL = URL(string: "tel:\(phoneNumber)") {
                                UIApplication.shared.open(phoneURL)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.accentGold)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                // Quote History
                VStack(alignment: .leading, spacing: 15) {
                    AppText.sectionTitle("Quote History")
                    
                    // Mock quote history
                    VStack(spacing: 10) {
                        QuoteHistoryRow(
                            quoteID: "Q-2025-000001",
                            date: Date(),
                            status: .completed,
                            total: 162.00
                        )
                        
                        QuoteHistoryRow(
                            quoteID: "Q-2024-000145",
                            date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                            status: .completed,
                            total: 85.00
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Guest Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewQuote) {
            QuoteCreationView()
        }
        .sheet(isPresented: $showingEditGuest) {
            EditGuestView(guest: guest)
        }
    }
}

struct QuoteHistoryRow: View {
    let quoteID: String
    let date: Date
    let status: QuoteStatus
    let total: Decimal
    
    var body: some View {
        NavigationLink(destination: QuoteDetailView(quote: mockQuote)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    AppText.bodyText(quoteID)
                    AppText.caption(formatDate(date))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    AppText.status(status)
                    AppText.priceSmall(total)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var mockQuote: Quote {
        Quote(
            id: quoteID,
            companyId: "company1",
            storeId: "store1",
            guestId: "guest1",
            status: status,
            createdAt: date,
            total: total
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditGuestView: View {
    let guest: Guest
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var notes: String
    
    @Environment(\.dismiss) private var dismiss
    
    init(guest: Guest) {
        self.guest = guest
        self._firstName = State(initialValue: guest.firstName)
        self._lastName = State(initialValue: guest.lastName)
        self._email = State(initialValue: guest.email ?? "")
        self._phone = State(initialValue: guest.phone ?? "")
        self._notes = State(initialValue: guest.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Guest Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save logic
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        GuestDetailView(guest: Guest(
            companyId: "company1",
            primaryStoreId: "store1",
            firstName: "John",
            lastName: "Smith",
            email: "john.smith@email.com",
            phone: "(555) 123-4567",
            notes: "Preferred customer, always pays promptly"
        ))
    }
}
