import SwiftUI

/// A component for displaying prices in a consistent format
struct PriceDisplayView: View {
    let amount: Decimal
    let currencyCode: String
    let size: PriceSize
    let style: PriceStyle
    
    init(
        amount: Decimal,
        currencyCode: String = "USD",
        size: PriceSize = .medium,
        style: PriceStyle = .normal
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.size = size
        self.style = style
    }
    
    var body: some View {
        Text(formattedPrice)
            .font(font)
            .foregroundColor(color)
    }
    
    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }
    
    private var font: Font {
        switch size {
        case .small:
            return .priceSmall
        case .medium:
            return .price
        case .large:
            return Font.system(size: 28, weight: .bold, design: .default)
        }
    }
    
    private var color: Color {
        switch style {
        case .normal:
            return .textPrimary
        case .positive:
            return .accentGreen
        case .negative:
            return .accentRed
        case .secondary:
            return .textSecondary
        }
    }
}

enum PriceSize {
    case small
    case medium
    case large
}

enum PriceStyle {
    case normal
    case positive
    case negative
    case secondary
}

#Preview {
    VStack(spacing: 20) {
        PriceDisplayView(amount: 125.50, size: .small)
        PriceDisplayView(amount: 125.50, size: .medium)
        PriceDisplayView(amount: 125.50, size: .large)
        
        PriceDisplayView(amount: 125.50, style: .positive)
        PriceDisplayView(amount: 125.50, style: .negative)
        PriceDisplayView(amount: 125.50, style: .secondary)
    }
    .padding()
}
