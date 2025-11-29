import SwiftUI
import PhotosUI

/// A component for capturing and managing photos for quotes
struct PhotoCaptureView: View {
    @Binding var photos: [QuotePhoto]
    let quoteID: String
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                AppText.sectionTitle("Photos")
                Spacer()
                Menu {
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    Button("Choose from Library") {
                        showingImagePicker = true
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.primaryBlue)
                }
            }
            
            // Photo Grid
            if photos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    
                    AppText.bodySecondary("No photos added")
                    
                    Button("Add First Photo") {
                        showingCamera = true
                    }
                    .font(.buttonMedium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 150)
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: photoGridColumns, spacing: 12) {
                    ForEach(photos) { photo in
                        PhotoThumbnail(photo: photo) {
                            removePhoto(photo)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(quoteID: quoteID) { photo in
                addPhoto(photo)
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                loadPhoto(from: newPhoto)
            }
        }
    }
    
    private let photoGridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private func addPhoto(_ photo: QuotePhoto) {
        photos.append(photo)
    }
    
    private func removePhoto(_ photo: QuotePhoto) {
        photos.removeAll { $0.id == photo.id }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                // Save to temporary location
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                
                if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    try? jpegData.write(to: tempURL)
                    
                    let photo = QuotePhoto(
                        quoteId: quoteID,
                        assetURL: tempURL,
                        caption: nil
                    )
                    
                    await MainActor.run {
                        addPhoto(photo)
                    }
                }
            }
        }
    }
}

struct PhotoThumbnail: View {
    let photo: QuotePhoto
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            AsyncImage(url: photo.assetURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(4)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let quoteID: String
    let onPhotoTaken: (QuotePhoto) -> Void
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
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Save to temporary location
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                
                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                    try? jpegData.write(to: tempURL)
                    
                    let photo = QuotePhoto(
                        quoteId: parent.quoteID,
                        assetURL: tempURL,
                        caption: nil
                    )
                    
                    parent.onPhotoTaken(photo)
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoCaptureView(
        photos: .constant([]),
        quoteID: "Q-2025-000123"
    )
    .padding()
}
