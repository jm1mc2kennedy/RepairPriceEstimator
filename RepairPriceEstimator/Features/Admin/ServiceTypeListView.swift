import SwiftUI

struct ServiceTypeListView: View {
    @StateObject private var viewModel = ServiceTypeListViewModel()
    @State private var showingNewServiceType = false
    @State private var selectedServiceType: ServiceType?
    @State private var showingEdit = false
    
    var body: some View {
        VStack {
            // Search and Filter
            VStack(spacing: 10) {
                SearchBar(text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) { _, _ in
                        Task { await viewModel.loadServiceTypes() }
                    }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                            Task { await viewModel.loadServiceTypes() }
                        }
                        
                        ForEach(ServiceCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: viewModel.selectedCategory == category,
                                color: category.color
                            ) {
                                viewModel.selectedCategory = category
                                Task { await viewModel.loadServiceTypes() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            
            // Service Types List
            if viewModel.isLoading && viewModel.serviceTypes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.serviceTypes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No service types found")
                        .foregroundColor(.textSecondary)
                    Button("Add Service Type") {
                        showingNewServiceType = true
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.serviceTypes) { serviceType in
                        Button(action: {
                            selectedServiceType = serviceType
                            showingEdit = true
                        }) {
                            ServiceTypeRowView(serviceType: serviceType)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await viewModel.deleteServiceType(serviceType)
                                    } catch {
                                        // Error shown via viewModel.showError
                                    }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Service Types")
        .searchable(text: $viewModel.searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewServiceType = true
                }
            }
        }
        .sheet(isPresented: $showingNewServiceType) {
            ServiceTypeEditView(serviceType: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEdit) {
            if let serviceType = selectedServiceType {
                ServiceTypeEditView(serviceType: serviceType, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadServiceTypes()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
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
