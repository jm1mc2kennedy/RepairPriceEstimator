import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(adminTiles) { tile in
                    AdminTile(
                        tile: tile,
                        isEnabled: tile.isEnabled(for: authService.currentSession)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var adminTiles: [AdminTileData] {
        [
            AdminTileData(
                id: "service-types",
                title: "Service Types",
                subtitle: "Manage repair services",
                systemImage: "wrench.and.screwdriver",
                color: .accentGold,
                destination: AnyView(ServiceTypeListView()),
                requiredPermissions: [.managePricing]
            ),
            AdminTileData(
                id: "pricing-rules",
                title: "Pricing Rules",
                subtitle: "Configure pricing formulas",
                systemImage: "dollarsign.circle",
                color: .accentGreen,
                destination: AnyView(PricingRulesView()),
                requiredPermissions: [.managePricing]
            ),
            AdminTileData(
                id: "metal-rates",
                title: "Metal Rates",
                subtitle: "Market pricing updates",
                systemImage: "chart.line.uptrend.xyaxis",
                color: .primaryBlue,
                destination: AnyView(MetalRatesView()),
                requiredPermissions: [.managePricing]
            ),
            AdminTileData(
                id: "labor-rates",
                title: "Labor Rates",
                subtitle: "Hourly rate management",
                systemImage: "clock",
                color: .accentSilver,
                destination: AnyView(LaborRatesView()),
                requiredPermissions: [.managePricing]
            ),
            AdminTileData(
                id: "users",
                title: "Users",
                subtitle: "User management",
                systemImage: "person.3",
                color: .primaryDark,
                destination: AnyView(UserManagementView()),
                requiredPermissions: [.manageUsers]
            ),
            AdminTileData(
                id: "company-settings",
                title: "Company",
                subtitle: "Company & store settings",
                systemImage: "building.2",
                color: .textSecondary,
                destination: AnyView(CompanySettingsView()),
                requiredPermissions: [.accessAdmin]
            )
        ]
    }
}

// MARK: - Admin Tile Data

struct AdminTileData: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let destination: AnyView
    let requiredPermissions: [PermissionAction]
    
    @MainActor
    func isEnabled(for session: UserSession?) -> Bool {
        guard session != nil else { return false }
        guard !requiredPermissions.isEmpty else { return true }
        
        return requiredPermissions.allSatisfy { permission in
            AuthService.shared.hasPermission(for: permission)
        }
    }
}

// MARK: - Admin Tile View

struct AdminTile: View {
    let tile: AdminTileData
    let isEnabled: Bool
    
    var body: some View {
        NavigationLink(destination: tile.destination) {
            VStack(spacing: 12) {
                Image(systemName: tile.systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(isEnabled ? tile.color : .textTertiary)
                
                VStack(spacing: 4) {
                    Text(tile.title)
                        .font(.labelLarge)
                        .foregroundColor(isEnabled ? .textPrimary : .textTertiary)
                    
                    Text(tile.subtitle)
                        .font(.captionLarge)
                        .foregroundColor(isEnabled ? .textSecondary : .textTertiary)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Admin Views

struct PricingRulesView: View {
    @StateObject private var viewModel = PricingRulesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.pricingRules.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pricingRules.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No pricing rules configured")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.pricingRules) { rule in
                        VStack(alignment: .leading, spacing: 8) {
                            AppText.bodyText(rule.name)
                            AppText.bodySecondary(rule.description)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Pricing Rules")
        .task {
            await viewModel.loadPricingRules()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

struct MetalRatesView: View {
    @StateObject private var viewModel = MetalRatesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.metalRates.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.metalRates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No metal rates configured")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.metalRates) { rate in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                AppText.bodyText(rate.metalType.displayName)
                                AppText.bodySecondary("Updated: \(formatDate(rate.effectiveDate))")
                            }
                            Spacer()
                            AppText.priceSmall(rate.rate, currencyCode: "USD")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Metal Rates")
        .task {
            await viewModel.loadMetalRates()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct LaborRatesView: View {
    @StateObject private var viewModel = LaborRatesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.laborRates.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.laborRates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No labor rates configured")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.laborRates) { rate in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                AppText.bodyText(rate.role.rawValue)
                                AppText.bodySecondary("Updated: \(formatDate(rate.effectiveDate))")
                            }
                            Spacer()
                            AppText.bodyText(rate.formattedRate)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Labor Rates")
        .task {
            await viewModel.loadLaborRates()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct UserManagementView: View {
    @StateObject private var viewModel = UserManagementViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.users.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.2")
                        .font(.system(size: 60))
                        .foregroundColor(.textTertiary)
                    AppText.bodyText("No users found")
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.users) { user in
                        VStack(alignment: .leading, spacing: 8) {
                            AppText.bodyText(user.displayName)
                            AppText.bodySecondary(user.email)
                            AppText.caption("Role: \(user.role.rawValue) • \(user.isActive ? "Active" : "Inactive")")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .searchable(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { _, _ in
                    Task { await viewModel.loadUsers() }
                }
            }
        }
        .navigationTitle("Users")
        .task {
            await viewModel.loadUsers()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

struct CompanySettingsView: View {
    @StateObject private var viewModel = CompanySettingsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let company = viewModel.company {
                        Section("Company Information") {
                            DetailRow(label: "Name", value: company.name)
                            DetailRow(label: "Contact", value: company.primaryContactInfo)
                        }
                    }
                    
                    Section("Stores") {
                        ForEach(viewModel.stores) { store in
                            VStack(alignment: .leading, spacing: 8) {
                                AppText.bodyText(store.name)
                                AppText.bodySecondary(store.location)
                                AppText.bodySecondary(store.phone)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Company Settings")
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    NavigationView {
        AdminHomeView()
            .environmentObject(AuthService.shared)
    }
}
