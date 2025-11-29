import SwiftUI

struct QuoteListView: View {
    @StateObject private var viewModel = QuoteListViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading && viewModel.quotes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Search and Filter
                VStack(spacing: 10) {
                    SearchBar(text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in
                            Task { await viewModel.loadQuotes() }
                        }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: viewModel.selectedStatus == nil) {
                                viewModel.selectedStatus = nil
                                Task { await viewModel.loadQuotes() }
                            }
                            
                            ForEach(QuoteStatus.allCases, id: \.self) { status in
                                FilterChip(
                                    title: status.displayName,
                                    isSelected: viewModel.selectedStatus == status,
                                    color: status.color
                                ) {
                                    viewModel.selectedStatus = status
                                    Task { await viewModel.loadQuotes() }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Quote List
                if viewModel.quotes.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.textTertiary)
                        AppText.bodyText("No quotes found")
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.quotes) { quote in
                            NavigationLink(destination: QuoteDetailView(quoteId: quote.id)) {
                                QuoteRowView(quote: quote)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let quote = viewModel.quotes[index]
                                Task {
                                    await viewModel.deleteQuote(quote)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .navigationTitle("Quotes")
        .searchable(text: $viewModel.searchText)
        .task {
            await viewModel.loadQuotes()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
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
