import SwiftUI
import UIKit

/// Wrapper for UIActivityViewController to share PDFs
struct ShareSheetViewController: UIViewControllerRepresentable {
    let pdfData: Data
    let subject: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: nil
        )
        
        // Set subject for email
        activityVC.setValue(subject, forKey: "subject")
        
        // Configure for iPad (will be set by parent view controller if needed)
        
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                dismiss()
            }
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

