import SwiftUI

struct QuoteListView: View {
    @State private var searchText = ""
    @State private var selectedStatus: QuoteStatus? = nil
    
    var body: some View {
        VStack {
            // Search and Filter
            VStack(spacing: 10) {
                SearchBar(text: $searchText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }
                        
                        ForEach(QuoteStatus.allCases, id: \.self) { status in
                            FilterChip(
                                title: status.displayName,
                                isSelected: selectedStatus == status,
                                color: status.color
                            ) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            
            // Quote List
            List {
                // Placeholder quotes
                ForEach(mockQuotes) { quote in
                    NavigationLink(destination: QuoteDetailView(quote: quote)) {
                        QuoteRowView(quote: quote)
                    }
                }
            }
            .refreshable {
                // Refresh logic
            }
        }
        .navigationTitle("Quotes")
        .searchable(text: $searchText)
    }
    
    private var mockQuotes: [Quote] {
        [
            Quote(
                id: "Q-2025-000001",
                companyId: "company1",
                storeId: "store1",
                guestId: "guest1",
                status: .draft,
                subtotal: 150.00,
                tax: 12.00,
                total: 162.00
            ),
            Quote(
                id: "Q-2025-000002",
                companyId: "company1",
                storeId: "store1",
                guestId: "guest2",
                status: .presented,
                subtotal: 245.00,
                tax: 19.60,
                total: 264.60
            )
        ]
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search quotes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, isSelected: Bool, color: Color = .primaryBlue, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.captionLarge)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.backgroundSecondary)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .cornerRadius(16)
        }
    }
}

struct QuoteRowView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AppText.quoteID(quote.id)
                
                Spacer()
                
                AppText.priceSmall(quote.total, currencyCode: quote.currencyCode)
            }
            
            HStack {
                AppText.status(quote.status)
                
                Spacer()
                
                AppText.caption(formatDate(quote.createdAt))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        QuoteListView()
    }
}
