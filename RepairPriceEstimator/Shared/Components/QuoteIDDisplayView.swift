import SwiftUI

/// A component for displaying Quote IDs in a consistent format
struct QuoteIDDisplayView: View {
    let quoteID: String
    let size: QuoteIDSize
    let style: QuoteIDStyle
    let showCopyButton: Bool
    
    @State private var showingCopiedFeedback = false
    
    init(
        quoteID: String,
        size: QuoteIDSize = .medium,
        style: QuoteIDStyle = .normal,
        showCopyButton: Bool = false
    ) {
        self.quoteID = quoteID
        self.size = size
        self.style = style
        self.showCopyButton = showCopyButton
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(quoteID)
                .font(font)
                .foregroundColor(color)
                .textSelection(.enabled)
            
            if showCopyButton {
                Button(action: copyQuoteID) {
                    Image(systemName: showingCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .foregroundColor(.primaryBlue)
                        .font(.system(size: size == .small ? 11 : size == .medium ? 12 : 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var font: Font {
        switch size {
        case .small:
            return Font.system(size: 14, weight: .semibold, design: .monospaced)
        case .medium:
            return .quoteID
        case .large:
            return Font.system(size: 24, weight: .bold, design: .monospaced)
        }
    }
    
    private var color: Color {
        switch style {
        case .normal:
            return .primaryBlue
        case .secondary:
            return .textSecondary
        case .highlighted:
            return .accentGold
        }
    }
    
    private func copyQuoteID() {
        UIPasteboard.general.string = quoteID
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCopiedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCopiedFeedback = false
            }
        }
    }
}

enum QuoteIDSize {
    case small
    case medium
    case large
}

enum QuoteIDStyle {
    case normal
    case secondary
    case highlighted
}

#Preview {
    VStack(spacing: 20) {
        QuoteIDDisplayView(quoteID: "Q-2025-000123", size: .small)
        QuoteIDDisplayView(quoteID: "Q-2025-000123", size: .medium)
        QuoteIDDisplayView(quoteID: "Q-2025-000123", size: .large)
        
        QuoteIDDisplayView(quoteID: "Q-2025-000123", style: .secondary)
        QuoteIDDisplayView(quoteID: "Q-2025-000123", style: .highlighted)
        
        QuoteIDDisplayView(
            quoteID: "Q-2025-000123",
            showCopyButton: true
        )
    }
    .padding()
}
