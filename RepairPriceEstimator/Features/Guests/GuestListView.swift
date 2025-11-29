import SwiftUI

struct GuestListView: View {
    @StateObject private var viewModel = GuestListViewModel()
    @State private var showingNewGuest = false
    @State private var selectedGuest: Guest?
    @State private var showingGuestDetail = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading && viewModel.guests.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.guests.isEmpty && !viewModel.isLoading {
                VStack(spacing: 20) {
                    Image(systemName: "person.2")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No guests found")
                        .foregroundColor(.textSecondary)
                    Button("Add Guest") {
                        showingNewGuest = true
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Guest List
                List {
                    ForEach(viewModel.guests) { guest in
                        NavigationLink(destination: GuestDetailView(guest: guest)) {
                            GuestRowView(guest: guest)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let guest = viewModel.guests[index]
                            Task {
                                do {
                                    try await viewModel.deleteGuest(guest)
                                } catch {
                                    // Error shown via viewModel.showError
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Guests")
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadGuests() }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewGuest = true
                }
            }
        }
        .sheet(isPresented: $showingNewGuest) {
            NewGuestView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
        .task {
            await viewModel.loadGuests()
        }
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
    @ObservedObject var viewModel: GuestListViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingError = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
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
        guard let session = authService.currentSession else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let newGuest = Guest(
            companyId: session.company.id,
            primaryStoreId: session.primaryStore.id,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        do {
            _ = try await viewModel.createGuest(newGuest)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        GuestListView()
    }
}
