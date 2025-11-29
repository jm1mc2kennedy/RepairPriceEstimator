import SwiftUI

/// App-wide typography styles and text formatting
extension Font {
    
    // MARK: - Headings
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 24, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 20, weight: .medium, design: .default)
    
    // MARK: - Body Text
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    // MARK: - Labels & Captions
    static let labelLarge = Font.system(size: 16, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 14, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)
    
    static let captionLarge = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Specialized Fonts
    static let quoteID = Font.system(size: 18, weight: .bold, design: .monospaced)
    static let price = Font.system(size: 20, weight: .semibold, design: .default)
    static let priceSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: - Button Text
    static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)
}

// MARK: - Text Styles for Common Use Cases
struct AppText {
    
    // MARK: - Title Styles
    static func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.titleLarge)
            .foregroundColor(.textPrimary)
    }
    
    static func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.titleMedium)
            .foregroundColor(.textPrimary)
    }
    
    static func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(.titleSmall)
            .foregroundColor(.textPrimary)
    }
    
    // MARK: - Body Text Styles
    static func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)
    }
    
    static func bodySecondary(_ text: String) -> some View {
        Text(text)
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
    }
    
    // MARK: - Label Styles
    static func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.labelMedium)
            .foregroundColor(.textSecondary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.captionLarge)
            .foregroundColor(.textTertiary)
    }
    
    // MARK: - Specialized Text
    static func quoteID(_ id: String) -> some View {
        Text(id)
            .font(.quoteID)
            .foregroundColor(.primaryBlue)
    }
    
    static func price(_ amount: Decimal, currencyCode: String = "USD") -> some View {
        Text(formatCurrency(amount, currencyCode: currencyCode))
            .font(.price)
            .foregroundColor(.textPrimary)
    }
    
    static func priceSmall(_ amount: Decimal, currencyCode: String = "USD") -> some View {
        Text(formatCurrency(amount, currencyCode: currencyCode))
            .font(.priceSmall)
            .foregroundColor(.textPrimary)
    }
    
    static func status(_ status: QuoteStatus) -> some View {
        Text(status.displayName)
            .font(.labelMedium)
            .foregroundColor(status.color)
    }
    
    // MARK: - Helper Functions
    private static func formatCurrency(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
}

// MARK: - Text Modifiers
extension Text {
    func appBodyStyle() -> some View {
        self
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)
    }
    
    func appSecondaryStyle() -> some View {
        self
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
    }
    
    func appCaptionStyle() -> some View {
        self
            .font(.captionLarge)
            .foregroundColor(.textTertiary)
    }
}
