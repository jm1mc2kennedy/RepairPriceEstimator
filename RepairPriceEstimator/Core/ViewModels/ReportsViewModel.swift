import Foundation
import SwiftUI

/// ViewModel for reports and analytics
@MainActor
final class ReportsViewModel: ObservableObject {
    nonisolated(unsafe) private let repository: DataRepository
    private let authService: AuthService
    
    @Published var totalQuotes: Int = 0
    @Published var totalRevenue: Decimal = 0
    @Published var activeQuotes: Int = 0
    @Published var completedQuotes: Int = 0
    @Published var revenueByDay: [RevenueDataPoint] = []
    @Published var topServiceTypes: [ServiceTypeStats] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init(repository: DataRepository = CloudKitService.shared, authService: AuthService = AuthService.shared) {
        self.repository = repository
        self.authService = authService
    }
    
    func loadReports(timeRange: TimeRange, storeId: String?) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let session = authService.currentSession else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }
        
        do {
            let (startDate, endDate) = timeRange.dateRange
            
            var predicate: NSPredicate
            if let storeId = storeId {
                predicate = NSPredicate(format: "companyId == %@ AND storeId == %@ AND createdAt >= %@ AND createdAt <= %@", session.company.id, storeId, startDate as NSDate, endDate as NSDate)
            } else {
                predicate = NSPredicate(format: "companyId == %@ AND createdAt >= %@ AND createdAt <= %@", session.company.id, startDate as NSDate, endDate as NSDate)
            }
            
            let quotes = try await repository.query(Quote.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)])
            
            // Calculate statistics
            totalQuotes = quotes.count
            totalRevenue = quotes.reduce(Decimal(0)) { $0 + $1.total }
            activeQuotes = quotes.filter { quote in
                quote.status == .draft || quote.status == .presented || quote.status == .awaitingApproval || 
                quote.status == .inShop || quote.status == .atVendor || quote.status == .qualityReview
            }.count
            completedQuotes = quotes.filter { quote in
                quote.status == .completed || quote.status == .approved
            }.count
            
            // Calculate revenue by day
            let calendar = Calendar.current
            var dailyRevenue: [Date: Decimal] = [:]
            
            for quote in quotes {
                let day = calendar.startOfDay(for: quote.createdAt)
                dailyRevenue[day, default: 0] += quote.total
            }
            
            revenueByDay = dailyRevenue.map { RevenueDataPoint(date: $0.key, amount: Double(truncating: $0.value as NSDecimalNumber)) }
                .sorted { $0.date < $1.date }
            
            // Calculate top service types
            var serviceTypeStats: [String: ServiceTypeStats] = [:]
            
            for quote in quotes {
                // Load line items for each quote
                let lineItemsPredicate = NSPredicate(format: "quoteId == %@", quote.id)
                let lineItems = try? await repository.query(QuoteLineItem.self, predicate: lineItemsPredicate, sortDescriptors: nil)
                
                for item in lineItems ?? [] {
                    // Load service type to get name
                    if let serviceType = try? await repository.fetch(ServiceType.self, id: item.serviceTypeId) {
                        let stats = serviceTypeStats[item.serviceTypeId, default: ServiceTypeStats(
                            serviceTypeId: item.serviceTypeId,
                            serviceTypeName: serviceType.name,
                            count: 0,
                            totalRevenue: 0
                        )]
                        
                        serviceTypeStats[item.serviceTypeId] = ServiceTypeStats(
                            serviceTypeId: item.serviceTypeId,
                            serviceTypeName: serviceType.name,
                            count: stats.count + 1,
                            totalRevenue: stats.totalRevenue + item.finalRetail
                        )
                    }
                }
            }
            
            topServiceTypes = Array(serviceTypeStats.values)
                .sorted { $0.totalRevenue > $1.totalRevenue }
            
            print("✅ Loaded reports: \(totalQuotes) quotes, \(totalRevenue) revenue")
        } catch {
            print("❌ Error loading reports: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func exportToPDF() async {
        // TODO: Implement PDF export
        print("Export to PDF functionality to be implemented")
    }
}

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct ServiceTypeStats: Identifiable {
    let id = UUID()
    let serviceTypeId: String
    let serviceTypeName: String
    let count: Int
    let totalRevenue: Decimal
}

