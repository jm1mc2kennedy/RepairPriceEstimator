import SwiftUI

struct GuestDetailView: View {
    let guest: Guest
    @StateObject private var viewModel = GuestListViewModel()
    @State private var showingNewQuote = false
    @State private var showingEditGuest = false
    @State private var guestQuotes: [Quote] = []
    @State private var isLoadingQuotes = false
    
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
                    
                    if isLoadingQuotes {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if guestQuotes.isEmpty {
                        AppText.bodySecondary("No quotes found")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(guestQuotes) { quote in
                                QuoteHistoryRow(quote: quote)
                                
                                if quote.id != guestQuotes.last?.id {
                                    Divider()
                                }
                            }
                        }
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
            QuoteCreationView(initialGuest: guest)
        }
        .sheet(isPresented: $showingEditGuest) {
            EditGuestView(guest: guest, viewModel: viewModel)
        }
        .task {
            await loadGuestQuotes()
        }
    }
    
    private func loadGuestQuotes() async {
        isLoadingQuotes = true
        defer { isLoadingQuotes = false }
        
        do {
            let repository = CloudKitService.shared
            let predicate = NSPredicate(format: "guestId == %@", guest.id)
            let sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            guestQuotes = try await repository.query(Quote.self, predicate: predicate, sortDescriptors: sortDescriptors)
        } catch {
            print("❌ Error loading guest quotes: \(error)")
        }
    }
}

struct QuoteHistoryRow: View {
    let quote: Quote
    
    var body: some View {
        NavigationLink(destination: QuoteDetailView(quoteId: quote.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    AppText.bodyText(quote.id)
                    AppText.caption(formatDate(quote.createdAt))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    AppText.status(quote.status)
                    AppText.priceSmall(quote.total, currencyCode: quote.currencyCode)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditGuestView: View {
    let guest: Guest
    @ObservedObject var viewModel: GuestListViewModel
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingError = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(guest: Guest, viewModel: GuestListViewModel) {
        self.guest = guest
        self.viewModel = viewModel
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
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveGuest()
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || isSaving)
                }
            }
            .disabled(isSaving)
            .alert("Error", isPresented: $showingError, presenting: saveError) { _ in
                Button("OK") { }
            } message: { error in
                Text(error)
            }
        }
    }
    
    private func saveGuest() async {
        isSaving = true
        defer { isSaving = false }
        
        let updatedGuest = Guest(
            id: guest.id,
            companyId: guest.companyId,
            primaryStoreId: guest.primaryStoreId,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        do {
            _ = try await viewModel.updateGuest(updatedGuest)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingError = true
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
