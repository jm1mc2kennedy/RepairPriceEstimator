import Foundation
import UIKit
import PDFKit

/// Service for generating PDF documents from quotes
@MainActor
final class PDFGenerator {
    
    /// Generate PDF data for a quote
    func generatePDF(quote: Quote, guest: Guest, store: Store, lineItems: [QuoteLineItem], photos: [QuotePhoto] = []) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Repair Price Estimator",
            kCGPDFContextAuthor: store.name,
            kCGPDFContextTitle: "Quote \(quote.id)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72.0 // Top margin
            
            // Header
            yPosition = drawHeader(context: context, yPosition: yPosition, pageWidth: pageWidth, store: store)
            
            yPosition += 20
            
            // Quote Information
            yPosition = drawQuoteInfo(context: context, yPosition: yPosition, pageWidth: pageWidth, quote: quote, guest: guest)
            
            yPosition += 20
            
            // Line Items
            yPosition = drawLineItems(context: context, yPosition: yPosition, pageWidth: pageWidth, lineItems: lineItems, quote: quote)
            
            // Check if we need a new page for photos
            if !photos.isEmpty && yPosition > pageHeight - 200 {
                context.beginPage()
                yPosition = 72.0
            }
            
            // Photos (if any)
            if !photos.isEmpty {
                yPosition += 20
                _ = drawPhotos(context: context, yPosition: yPosition, pageWidth: pageWidth, photos: photos)
            }
            
            // Footer
            drawFooter(context: context, pageWidth: pageWidth, pageHeight: pageHeight, quote: quote)
        }
        
        return data
    }
    
    // MARK: - Drawing Methods
    
    private func drawHeader(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, store: Store) -> CGFloat {
        var currentY = yPosition
        
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let storeFont = UIFont.systemFont(ofSize: 14)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let storeAttributes: [NSAttributedString.Key: Any] = [
            .font: storeFont,
            .foregroundColor: UIColor.gray
        ]
        
        // Title
        let title = "REPAIR QUOTE"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: currentY, width: titleSize.width, height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        // Store Name
        let storeName = store.name
        let storeSize = storeName.size(withAttributes: storeAttributes)
        let storeRect = CGRect(x: (pageWidth - storeSize.width) / 2, y: currentY, width: storeSize.width, height: storeSize.height)
        storeName.draw(in: storeRect, withAttributes: storeAttributes)
        currentY += storeSize.height + 5
        
        // Store Address
        let address = store.location
        let addressSize = address.size(withAttributes: storeAttributes)
        let addressRect = CGRect(x: (pageWidth - addressSize.width) / 2, y: currentY, width: addressSize.width, height: addressSize.height)
        address.draw(in: addressRect, withAttributes: storeAttributes)
        currentY += addressSize.height + 5
        
        // Store Phone
        let phone = store.phone
        let phoneSize = phone.size(withAttributes: storeAttributes)
        let phoneRect = CGRect(x: (pageWidth - phoneSize.width) / 2, y: currentY, width: phoneSize.width, height: phoneSize.height)
        phone.draw(in: phoneRect, withAttributes: storeAttributes)
        currentY += phoneSize.height + 20
        
        // Horizontal line
        context.cgContext.setStrokeColor(UIColor.gray.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.move(to: CGPoint(x: 72, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - 72, y: currentY))
        context.cgContext.strokePath()
        currentY += 10
        
        return currentY
    }
    
    private func drawQuoteInfo(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, quote: Quote, guest: Guest) -> CGFloat {
        var currentY = yPosition
        
        let labelFont = UIFont.boldSystemFont(ofSize: 12)
        let valueFont = UIFont.systemFont(ofSize: 12)
        
        let labelAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        let valueAttributes: [NSAttributedString.Key: Any] = [.font: valueFont]
        
        let leftMargin: CGFloat = 72
        let rightMargin: CGFloat = pageWidth - 72
        let columnWidth = (rightMargin - leftMargin) / 2
        
        // Quote ID
        "Quote ID:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: labelAttributes)
        quote.id.draw(at: CGPoint(x: leftMargin + 80, y: currentY), withAttributes: valueAttributes)
        currentY += 20
        
        // Guest Name
        "Customer:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: labelAttributes)
        guest.fullName.draw(at: CGPoint(x: leftMargin + 80, y: currentY), withAttributes: valueAttributes)
        currentY += 20
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        "Date:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: labelAttributes)
        dateFormatter.string(from: quote.createdAt).draw(at: CGPoint(x: leftMargin + 80, y: currentY), withAttributes: valueAttributes)
        currentY += 20
        
        // Valid Until
        "Valid Until:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: labelAttributes)
        dateFormatter.string(from: quote.validUntil).draw(at: CGPoint(x: leftMargin + 80, y: currentY), withAttributes: valueAttributes)
        currentY += 20
        
        // Status
        "Status:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: labelAttributes)
        quote.status.displayName.draw(at: CGPoint(x: leftMargin + 80, y: currentY), withAttributes: valueAttributes)
        currentY += 20
        
        return currentY
    }
    
    private func drawLineItems(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, lineItems: [QuoteLineItem], quote: Quote) -> CGFloat {
        var currentY = yPosition
        
        let headerFont = UIFont.boldSystemFont(ofSize: 14)
        let itemFont = UIFont.systemFont(ofSize: 12)
        
        let leftMargin: CGFloat = 72
        let rightMargin: CGFloat = pageWidth - 72
        
        // Section Header
        let header = "SERVICES"
        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
        header.draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: headerAttributes)
        currentY += 25
        
        // Table Header
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.gray
        ]
        
        "Description".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: tableHeaderAttributes)
        "SKU".draw(at: CGPoint(x: leftMargin + 250, y: currentY), withAttributes: tableHeaderAttributes)
        "Amount".draw(at: CGPoint(x: rightMargin - 100, y: currentY), withAttributes: tableHeaderAttributes)
        currentY += 20
        
        // Draw line under header
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: leftMargin, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: rightMargin, y: currentY))
        context.cgContext.strokePath()
        currentY += 15
        
        // Line Items
        let itemAttributes: [NSAttributedString.Key: Any] = [.font: itemFont]
        
        for item in lineItems {
            // Description
            item.description.draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: itemAttributes)
            
            // SKU
            item.sku.draw(at: CGPoint(x: leftMargin + 250, y: currentY), withAttributes: itemAttributes)
            
            // Amount
            let amountString = formatCurrency(item.finalRetail)
            let amountSize = amountString.size(withAttributes: itemAttributes)
            amountString.draw(at: CGPoint(x: rightMargin - amountSize.width, y: currentY), withAttributes: itemAttributes)
            
            currentY += 20
        }
        
        currentY += 10
        
        // Totals
        let totalAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12)]
        
        // Subtotal
        "Subtotal:".draw(at: CGPoint(x: rightMargin - 150, y: currentY), withAttributes: itemAttributes)
        formatCurrency(quote.subtotal).draw(at: CGPoint(x: rightMargin - formatCurrency(quote.subtotal).size(withAttributes: itemAttributes).width, y: currentY), withAttributes: itemAttributes)
        currentY += 20
        
        // Tax
        "Tax:".draw(at: CGPoint(x: rightMargin - 150, y: currentY), withAttributes: itemAttributes)
        formatCurrency(quote.tax).draw(at: CGPoint(x: rightMargin - formatCurrency(quote.tax).size(withAttributes: itemAttributes).width, y: currentY), withAttributes: itemAttributes)
        currentY += 20
        
        // Total
        let totalString = "Total:"
        totalString.draw(at: CGPoint(x: rightMargin - 150, y: currentY), withAttributes: totalAttributes)
        formatCurrency(quote.total).draw(at: CGPoint(x: rightMargin - formatCurrency(quote.total).size(withAttributes: totalAttributes).width, y: currentY), withAttributes: totalAttributes)
        currentY += 30
        
        // Customer Notes
        if let notes = quote.customerFacingNotes, !notes.isEmpty {
            "Notes:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: totalAttributes)
            currentY += 15
            
            let notesRect = CGRect(x: leftMargin, y: currentY, width: rightMargin - leftMargin, height: 100)
            notes.draw(in: notesRect, withAttributes: itemAttributes)
            currentY += 60
        }
        
        return currentY
    }
    
    private func drawPhotos(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, photos: [QuotePhoto]) -> CGFloat {
        var currentY = yPosition
        
        // Skip if no photos
        guard !photos.isEmpty else { return currentY }
        
        let headerFont = UIFont.boldSystemFont(ofSize: 14)
        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
        
        "PHOTOS".draw(at: CGPoint(x: 72, y: currentY), withAttributes: headerAttributes)
        currentY += 25
        
        let leftMargin: CGFloat = 72
        let rightMargin: CGFloat = pageWidth - 72
        let photoWidth: CGFloat = 150
        let photoHeight: CGFloat = 150
        let spacing: CGFloat = 20
        
        var xPosition = leftMargin
        var photosDrawn = 0
        
        for photo in photos.prefix(4) { // Limit to 4 photos per page
            var image: UIImage?
            
            // Try to load from URL (could be CloudKit asset or local file)
            if let url = photo.assetURL {
                // Check if it's a file URL
                if url.isFileURL {
                    if let imageData = try? Data(contentsOf: url) {
                        image = UIImage(data: imageData)
                    }
                } else {
                    // For CloudKit assets, we'd need to download first
                    // For now, skip if not a file URL
                    continue
                }
            }
            
            if let image = image {
                let imageRect = CGRect(x: xPosition, y: currentY, width: photoWidth, height: photoHeight)
                image.draw(in: imageRect)
                
                photosDrawn += 1
                xPosition += photoWidth + spacing
                
                // Move to next row if needed
                if xPosition + photoWidth > rightMargin {
                    xPosition = leftMargin
                    currentY += photoHeight + spacing
                }
            }
        }
        
        if photosDrawn > 0 {
            currentY += photoHeight + 20
        } else {
            currentY += 20
        }
        
        return currentY
    }
    
    private func drawFooter(context: UIGraphicsPDFRendererContext, pageWidth: CGFloat, pageHeight: CGFloat, quote: Quote) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = "Quote \(quote.id) - Generated on \(formatDate(Date()))"
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 36, width: footerSize.width, height: footerSize.height)
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

