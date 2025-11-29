import SwiftUI

struct ServiceTypeListView: View {
    @State private var searchText = ""
    @State private var selectedCategory: ServiceCategory? = nil
    @State private var showingNewServiceType = false
    
    var body: some View {
        VStack {
            // Search and Filter
            VStack(spacing: 10) {
                SearchBar(text: $searchText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ServiceCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            
            // Service Types List
            List {
                ForEach(mockServiceTypes) { serviceType in
                    NavigationLink(destination: ServiceTypeEditView(serviceType: serviceType)) {
                        ServiceTypeRowView(serviceType: serviceType)
                    }
                }
            }
            .refreshable {
                // Refresh logic
            }
        }
        .navigationTitle("Service Types")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewServiceType = true
                }
            }
        }
        .sheet(isPresented: $showingNewServiceType) {
            ServiceTypeEditView(serviceType: nil)
        }
    }
    
    private var mockServiceTypes: [ServiceType] {
        [
            ServiceType(
                companyId: "company1",
                name: "Ring Sizing Up",
                category: .jewelryRepair,
                defaultSku: "RS-UP",
                defaultLaborMinutes: 30,
                defaultMetalUsageGrams: 0.5,
                baseRetail: 45.00,
                baseCost: 15.00
            ),
            ServiceType(
                companyId: "company1",
                name: "Prong Retip",
                category: .jewelryRepair,
                defaultSku: "PR-TIP",
                defaultLaborMinutes: 15,
                defaultMetalUsageGrams: 0.1,
                baseRetail: 25.00,
                baseCost: 8.00
            ),
            ServiceType(
                companyId: "company1",
                name: "Watch Battery",
                category: .watchRepair,
                defaultSku: "WB-REP",
                defaultLaborMinutes: 10,
                baseRetail: 15.00,
                baseCost: 5.00
            )
        ]
    }
}

struct ServiceTypeRowView: View {
    let serviceType: ServiceType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AppText.bodyText(serviceType.name)
                
                Spacer()
                
                Text(serviceType.category.displayName)
                    .font(.captionLarge)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(serviceType.category.color.opacity(0.2))
                    .foregroundColor(serviceType.category.color)
                    .cornerRadius(8)
            }
            
            HStack {
                AppText.caption("SKU: \(serviceType.defaultSku)")
                
                Spacer()
                
                AppText.priceSmall(serviceType.baseRetail)
            }
            
            if !serviceType.isActive {
                AppText.caption("INACTIVE")
                    .foregroundColor(.accentRed)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        ServiceTypeListView()
    }
}
