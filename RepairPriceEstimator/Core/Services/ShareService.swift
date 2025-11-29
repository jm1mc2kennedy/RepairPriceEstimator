import Foundation
import MessageUI
import UIKit

/// Service for sharing quotes via email and SMS
@MainActor
final class ShareService {
    
    /// Share quote via email
    func shareQuoteViaEmail(quote: Quote, guest: Guest, lineItems: [QuoteLineItem], pdfData: Data?) -> URL? {
        // Create email URL scheme
        guard let guestEmail = guest.email else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = guestEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Repair Quote: \(quote.id)"),
            URLQueryItem(name: "body", value: emailBody(for: quote, guest: guest, lineItems: lineItems))
        ]
        
        return components.url
    }
    
    /// Share quote via SMS
    func shareQuoteViaSMS(quote: Quote, guest: Guest, lineItems: [QuoteLineItem]) -> URL? {
        guard let guestPhone = guest.phone else {
            return nil
        }
        
        // Clean phone number (remove non-digit characters)
        let cleanedPhone = guestPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Create SMS URL scheme
        let messageBody = smsBody(for: quote, guest: guest, lineItems: lineItems)
        
        // iOS SMS URL format
        var components = URLComponents()
        components.scheme = "sms"
        components.host = cleanedPhone
        components.queryItems = [
            URLQueryItem(name: "body", value: messageBody)
        ]
        
        return components.url
    }
    
    /// Generate email body text
    private func emailBody(for quote: Quote, guest: Guest, lineItems: [QuoteLineItem]) -> String {
        var body = """
        Dear \(guest.firstName),
        
        Thank you for choosing our repair services. Please find your quote details below:
        
        Quote ID: \(quote.id)
        Date: \(formatDate(quote.createdAt))
        Valid Until: \(formatDate(quote.validUntil))
        
        Services:
        """
        
        for item in lineItems {
            body += "\n• \(item.description): \(formatCurrency(item.finalRetail))"
        }
        
        body += """
        
        
        Subtotal: \(formatCurrency(quote.subtotal))
        Tax: \(formatCurrency(quote.tax))
        Total: \(formatCurrency(quote.total))
        
        """
        
        if let notes = quote.customerFacingNotes {
            body += "Notes: \(notes)\n\n"
        }
        
        body += """
        Please review this quote and let us know if you have any questions or would like to proceed.
        
        Best regards,
        Repair Team
        """
        
        return body
    }
    
    /// Generate SMS body text
    private func smsBody(for quote: Quote, guest: Guest, lineItems: [QuoteLineItem]) -> String {
        var body = "Repair Quote \(quote.id): "
        
        if lineItems.count == 1 {
            body += lineItems.first?.description ?? "Service"
        } else {
            body += "\(lineItems.count) services"
        }
        
        body += " - Total: \(formatCurrency(quote.total)). Valid until \(formatShortDate(quote.validUntil))."
        
        if let notes = quote.customerFacingNotes, !notes.isEmpty {
            body += " \(notes)"
        }
        
        return body
    }
    
    /// Format currency
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
    
    /// Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Format short date
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

