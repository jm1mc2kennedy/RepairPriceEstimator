import SwiftUI

struct GuestListView: View {
    @State private var searchText = ""
    @State private var showingNewGuest = false
    
    var body: some View {
        VStack {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.vertical)
            
            // Guest List
            List {
                ForEach(mockGuests) { guest in
                    NavigationLink(destination: GuestDetailView(guest: guest)) {
                        GuestRowView(guest: guest)
                    }
                }
            }
            .refreshable {
                // Refresh logic
            }
        }
        .navigationTitle("Guests")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewGuest = true
                }
            }
        }
        .sheet(isPresented: $showingNewGuest) {
            NewGuestView()
        }
    }
    
    private var mockGuests: [Guest] {
        [
            Guest(
                companyId: "company1",
                primaryStoreId: "store1",
                firstName: "John",
                lastName: "Smith",
                email: "john.smith@email.com",
                phone: "(555) 123-4567"
            ),
            Guest(
                companyId: "company1",
                primaryStoreId: "store1",
                firstName: "Jane",
                lastName: "Doe",
                email: "jane.doe@email.com",
                phone: "(555) 987-6543"
            )
        ]
    }
}

struct GuestRowView: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AppText.bodyText(guest.fullName)
            
            if let contact = guest.contactInfo {
                AppText.bodySecondary(contact)
            }
        }
        .padding(.vertical, 2)
    }
}

struct NewGuestView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    
    @Environment(\.dismiss) private var dismiss
    
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
            .navigationTitle("New Guest")
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
        GuestListView()
    }
}
