import SwiftUI

struct QuoteCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuoteCreationViewModel
    @State private var showingNewGuest = false
    @State private var showingServiceTypePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingSaveError = false
    @State private var saveError: String?
    @State private var initialGuest: Guest?
    
    init(initialGuest: Guest? = nil) {
        // Note: We can't set selectedGuest in init because it's @Published
        // Instead, we'll set it in .task or .onAppear
        self._viewModel = StateObject(wrappedValue: QuoteCreationViewModel())
        self._initialGuest = State(initialValue: initialGuest)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(viewModel.currentStep), total: Double(viewModel.totalSteps))
                    .padding()
                
                AppText.bodySecondary("Step \(viewModel.currentStep) of \(viewModel.totalSteps)")
                    .padding(.bottom)
                
                // Content based on current step
                Group {
                    switch viewModel.currentStep {
                    case 1:
                        GuestSelectionStepView(viewModel: viewModel, showingNewGuest: $showingNewGuest)
                    case 2:
                        StoreSelectionStepView(viewModel: viewModel)
                    case 3:
                        LineItemsStepView(viewModel: viewModel, showingServiceTypePicker: $showingServiceTypePicker)
                    case 4:
                        PhotosStepView(viewModel: viewModel, showingPhotoPicker: $showingPhotoPicker)
                    case 5:
                        ReviewStepView(viewModel: viewModel)
                    default:
                        AppText.bodyText("Invalid step")
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    if viewModel.currentStep > 1 {
                        Button("Previous") {
                            viewModel.previousStep()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                    }
                    
                    Button(viewModel.currentStep == viewModel.totalSteps ? "Save Quote" : "Next") {
                        if viewModel.currentStep == viewModel.totalSteps {
                            Task {
                                await saveQuote()
                            }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(viewModel.canProceedToNextStep ? Color.primaryBlue : Color.textTertiary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!viewModel.canProceedToNextStep || viewModel.isLoading)
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
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingNewGuest) {
                NewGuestInQuoteView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingServiceTypePicker) {
                ServiceTypePickerView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $showingSaveError, presenting: saveError) { _ in
                Button("OK") { }
            } message: { error in
                Text(error)
            }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
        .task {
            // Set initial guest if provided
            if let guest = initialGuest {
                viewModel.selectedGuest = guest
                initialGuest = nil // Clear after setting
            }
        }
        }
    }
    
    private func saveQuote() async {
        do {
            let quote = try await viewModel.saveQuote()
            print("✅ Quote created successfully: \(quote.id)")
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

// MARK: - Step 1: Guest Selection

struct GuestSelectionStepView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    @Binding var showingNewGuest: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Select Guest")
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                if viewModel.availableGuests.isEmpty && viewModel.guestSearchText.isEmpty {
                    VStack(spacing: 15) {
                        Button("Create New Guest") {
                            showingNewGuest = true
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.accentGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {
                    SearchBar(text: $viewModel.guestSearchText)
                        .onChange(of: viewModel.guestSearchText) { _, _ in
                            Task { await viewModel.loadGuests() }
                        }
                        .padding(.horizontal)
                    
                    List {
                        ForEach(viewModel.availableGuests) { guest in
                            Button(action: {
                                viewModel.selectGuest(guest)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        AppText.bodyText(guest.fullName)
                                        if let contact = guest.contactInfo {
                                            AppText.bodySecondary(contact)
                                        }
                                    }
                                    Spacer()
                                    if viewModel.selectedGuest?.id == guest.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentGreen)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if viewModel.selectedGuest != nil {
                VStack(spacing: 8) {
                    AppText.fieldLabel("Selected Guest")
                    AppText.bodyText(viewModel.selectedGuest!.fullName)
                    if let contact = viewModel.selectedGuest!.contactInfo {
                        AppText.bodySecondary(contact)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .task {
            await viewModel.loadGuests()
        }
    }
}

// MARK: - Step 2: Store Selection

struct StoreSelectionStepView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Select Store")
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(viewModel.availableStores) { store in
                        Button(action: {
                            viewModel.selectStore(store)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    AppText.bodyText(store.name)
                                    Spacer()
                                    if viewModel.selectedStore?.id == store.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentGreen)
                                    }
                                }
                                AppText.bodySecondary(store.location)
                                AppText.bodySecondary(store.phone)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadStores()
        }
    }
}

// MARK: - Step 3: Line Items

struct LineItemsStepView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    @Binding var showingServiceTypePicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Add Line Items")
            
            Button("Add Service") {
                showingServiceTypePicker = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            
            if viewModel.lineItems.isEmpty {
                AppText.bodySecondary("No line items added yet")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                AppText.bodyText(item.serviceType.name)
                                Spacer()
                                AppText.priceSmall(item.totalPrice)
                            }
                            AppText.caption("SKU: \(item.serviceType.defaultSku) • Qty: \(item.quantity)")
                            if item.isRush {
                                AppText.caption("Rush Service")
                                    .foregroundColor(.accentGold)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.removeLineItem(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: Photos

struct PhotosStepView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    @Binding var showingPhotoPicker: Bool
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            AppText.sectionTitle("Add Photos")
            
            HStack(spacing: 15) {
                Button("Take Photo") {
                    showingCamera = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if viewModel.photos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    AppText.bodySecondary("No photos added yet")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                if let uiImage = UIImage(data: photo.imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 150, height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color.backgroundSecondary)
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(8)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.textTertiary)
                                        )
                                }
                                
                                Button(action: {
                                    viewModel.removePhoto(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let photoDraft = QuotePhotoDraft(imageData: imageData, caption: nil)
                viewModel.addPhoto(photoDraft)
                selectedImage = nil
            }
        }
    }
}

// MARK: - Image Picker Helpers

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Step 5: Review

struct ReviewStepView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppText.sectionTitle("Review Quote")
                
                // Guest Summary
                if let guest = viewModel.selectedGuest {
                    VStack(alignment: .leading, spacing: 8) {
                        AppText.fieldLabel("Guest")
                        AppText.bodyText(guest.fullName)
                        if let contact = guest.contactInfo {
                            AppText.bodySecondary(contact)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                }
                
                // Store Summary
                if let store = viewModel.selectedStore {
                    VStack(alignment: .leading, spacing: 8) {
                        AppText.fieldLabel("Store")
                        AppText.bodyText(store.name)
                        AppText.bodySecondary(store.location)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                }
                
                // Line Items Summary
                VStack(alignment: .leading, spacing: 8) {
                    AppText.fieldLabel("Line Items")
                    ForEach(viewModel.lineItems) { item in
                        HStack {
                            AppText.bodySecondary("\(item.quantity)x \(item.serviceType.name)")
                            Spacer()
                            AppText.bodySecondary("$\(item.totalPrice)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(8)
                
                // Totals
                VStack(alignment: .leading, spacing: 10) {
                    AppText.fieldLabel("Quote Total")
                    
                    HStack {
                        AppText.fieldLabel("Subtotal")
                        Spacer()
                        AppText.priceSmall(viewModel.subtotal)
                    }
                    
                    if viewModel.rushMultiplier > 1.0 {
                        HStack {
                            AppText.fieldLabel("Rush Multiplier")
                            Spacer()
                            AppText.bodySecondary("\(viewModel.rushMultiplier)x")
                        }
                    }
                    
                    HStack {
                        AppText.fieldLabel("Tax")
                        Spacer()
                        AppText.priceSmall(viewModel.tax)
                    }
                    
                    Divider()
                    
                    HStack {
                        AppText.sectionTitle("Total")
                        Spacer()
                        AppText.price(viewModel.total)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(8)
                
                // Notes
                VStack(alignment: .leading, spacing: 10) {
                    AppText.fieldLabel("Internal Notes")
                    TextEditor(text: $viewModel.internalNotes)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                    
                    AppText.fieldLabel("Customer-Facing Notes")
                    TextEditor(text: $viewModel.customerFacingNotes)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct NewGuestInQuoteView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var isSaving = false
    
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
            _ = try await viewModel.createNewGuest(newGuest)
            dismiss()
        } catch {
            print("❌ Error creating guest: \(error)")
        }
    }
}

struct ServiceTypePickerView: View {
    @ObservedObject var viewModel: QuoteCreationViewModel
    @State private var searchText = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var filteredServiceTypes: [ServiceType] {
        if searchText.isEmpty {
            return viewModel.availableServiceTypes
        } else {
            return viewModel.availableServiceTypes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.defaultSku.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredServiceTypes) { serviceType in
                    Button(action: {
                        viewModel.addLineItem(serviceType: serviceType)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            AppText.bodyText(serviceType.name)
                            AppText.bodySecondary("SKU: \(serviceType.defaultSku)")
                            AppText.priceSmall(serviceType.baseRetail)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadServiceTypes()
        }
    }
}

#Preview {
    QuoteCreationView()
}
