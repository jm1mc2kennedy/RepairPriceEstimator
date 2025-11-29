import SwiftUI

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedStore: Store?
    @State private var availableStores: [Store] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Filter
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _, _ in
                        Task {
                            await viewModel.loadReports(timeRange: selectedTimeRange, storeId: selectedStore?.id)
                        }
                    }
                    
                    // Store Filter
                    if availableStores.count > 1 {
                        Picker("Store", selection: $selectedStore) {
                            Text("All Stores").tag(nil as Store?)
                            ForEach(availableStores) { store in
                                Text(store.name).tag(store as Store?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                        .onChange(of: selectedStore) { _, _ in
                            Task {
                                await viewModel.loadReports(timeRange: selectedTimeRange, storeId: selectedStore?.id)
                            }
                        }
                    }
                    
                    // Summary Cards
                    if !viewModel.isLoading {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            SummaryCard(
                                title: "Total Quotes",
                                value: "\(viewModel.totalQuotes)",
                                icon: "doc.text",
                                color: .primaryBlue
                            )
                            
                            SummaryCard(
                                title: "Revenue",
                                value: viewModel.totalRevenue.formatted(.currency(code: "USD")),
                                icon: "dollarsign.circle",
                                color: .accentGreen
                            )
                            
                            SummaryCard(
                                title: "Active Quotes",
                                value: "\(viewModel.activeQuotes)",
                                icon: "clock",
                                color: .accentGold
                            )
                            
                            SummaryCard(
                                title: "Completed",
                                value: "\(viewModel.completedQuotes)",
                                icon: "checkmark.circle",
                                color: .accentGreen
                            )
                        }
                        .padding(.horizontal)
                        
                        // Revenue Trend (simplified without Charts framework)
                        if !viewModel.revenueByDay.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                AppText.sectionTitle("Revenue Trend")
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.revenueByDay.suffix(7)) { data in
                                        HStack {
                                            Text(formatDate(data.date))
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                                .frame(width: 80, alignment: .leading)
                                            
                                            GeometryReader { geometry in
                                                HStack(spacing: 0) {
                                                    Rectangle()
                                                        .fill(Color.primaryBlue)
                                                        .frame(width: max(2, geometry.size.width * CGFloat(data.amount / (viewModel.revenueByDay.map { $0.amount }.max() ?? 1))), height: 20)
                                                    Spacer()
                                                }
                                            }
                                            .frame(height: 20)
                                            
                                            Text(data.amount.formatted(.currency(code: "USD")))
                                                .font(.caption)
                                                .foregroundColor(.textPrimary)
                                                .frame(width: 80, alignment: .trailing)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Top Service Types
                        if !viewModel.topServiceTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                AppText.sectionTitle("Top Service Types")
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.topServiceTypes.prefix(5), id: \.serviceTypeId) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            AppText.bodyText(item.serviceTypeName)
                                            AppText.caption("\(item.count) quotes")
                                        }
                                        Spacer()
                                        AppText.priceSmall(item.totalRevenue)
                                    }
                                    .padding()
                                    .background(Color.cardBackground)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Export Button
                        Button("Export Report") {
                            Task {
                                await viewModel.exportToPDF()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reports")
            .refreshable {
                await viewModel.loadReports(timeRange: selectedTimeRange, storeId: selectedStore?.id)
            }
            .task {
                await loadStores()
                await viewModel.loadReports(timeRange: selectedTimeRange, storeId: selectedStore?.id)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadStores() async {
        guard let session = AuthService.shared.currentSession else { return }
        do {
            let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", session.company.id)
            availableStores = try await CloudKitService.shared.query(Store.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        } catch {
            print("❌ Error loading stores: \(error)")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
    
    var dateRange: (Date, Date) {
        let end = Date()
        let calendar = Calendar.current
        let start: Date
        
        switch self {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        case .quarter:
            start = calendar.date(byAdding: .month, value: -3, to: end) ?? end
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        }
        
        return (start, end)
    }
}

