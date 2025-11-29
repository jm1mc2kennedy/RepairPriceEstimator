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
    @State private var showingNewRule = false
    @State private var selectedRule: PricingRule?
    @State private var showingEdit = false
    
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
                    Button("Add Pricing Rule") {
                        showingNewRule = true
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.pricingRules) { rule in
                        Button(action: {
                            selectedRule = rule
                            showingEdit = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    AppText.bodyText(rule.name)
                                    Spacer()
                                    if !rule.isActive {
                                        AppText.caption("INACTIVE")
                                            .foregroundColor(.accentRed)
                                    }
                                }
                                AppText.bodySecondary(rule.description)
                                HStack(spacing: 16) {
                                    AppText.caption("Metal: \(String(describing: rule.formulaDefinition.metalMarkupPercentage))x")
                                    AppText.caption("Labor: \(String(describing: rule.formulaDefinition.laborMarkupPercentage))x")
                                    if rule.formulaDefinition.rushMultiplier != 1.0 {
                                        AppText.caption("Rush: \(String(describing: rule.formulaDefinition.rushMultiplier))x")
                                    }
                                }
                                .foregroundColor(.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    // Deactivate rule
                                    let deactivated = PricingRule(
                                        id: rule.id,
                                        companyId: rule.companyId,
                                        name: rule.name,
                                        description: rule.description,
                                        formulaDefinition: rule.formulaDefinition,
                                        allowManualOverride: rule.allowManualOverride,
                                        requireManagerApprovalIfOverrideExceedsPercent: rule.requireManagerApprovalIfOverrideExceedsPercent,
                                        isActive: false
                                    )
                                    do {
                                        _ = try await viewModel.updatePricingRule(deactivated)
                                    } catch {
                                        // Error handled by viewModel
                                    }
                                }
                            } label: {
                                Label("Deactivate", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pricing Rules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewRule = true
                }
            }
        }
        .sheet(isPresented: $showingNewRule) {
            PricingRulesEditView(pricingRule: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEdit) {
            if let rule = selectedRule {
                PricingRulesEditView(pricingRule: rule, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadPricingRules()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
    }
}

struct MetalRatesView: View {
    @StateObject private var viewModel = MetalRatesViewModel()
    @State private var selectedMetalType: MetalType?
    @State private var showingEdit = false
    
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
                    Button("Add Metal Rate") {
                        if let firstMetal = MetalType.allCases.first {
                            selectedMetalType = firstMetal
                            showingEdit = true
                        }
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.metalRates) { rate in
                        Button(action: {
                            selectedMetalType = rate.metalType
                            showingEdit = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    AppText.bodyText(rate.metalType.displayName)
                                    AppText.bodySecondary("Updated: \(formatDate(rate.effectiveDate)) • \(rate.unit.displayName)")
                                }
                                Spacer()
                                AppText.priceSmall(rate.rate, currencyCode: "USD")
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Show all metal types, even if no rate exists
                    ForEach(MetalType.allCases.filter { metalType in
                        !viewModel.metalRates.contains { $0.metalType == metalType }
                    }) { metalType in
                        Button(action: {
                            selectedMetalType = metalType
                            showingEdit = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    AppText.bodyText(metalType.displayName)
                                    AppText.bodySecondary("No rate set")
                                        .foregroundColor(.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentGreen)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Metal Rates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(MetalType.allCases, id: \.self) { metalType in
                        Button(metalType.displayName) {
                            selectedMetalType = metalType
                            showingEdit = true
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let metalType = selectedMetalType {
                let currentRate = viewModel.metalRates.first { $0.metalType == metalType }
                MetalRatesEditView(metalType: metalType, currentRate: currentRate, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadMetalRates()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
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
    @State private var selectedRole: UserRole?
    @State private var showingEdit = false
    
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
                    Button("Add Labor Rate") {
                        if let firstRole = UserRole.allCases.first {
                            selectedRole = firstRole
                            showingEdit = true
                        }
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.laborRates) { rate in
                        Button(action: {
                            selectedRole = rate.role
                            showingEdit = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    AppText.bodyText(rate.role.displayName)
                                    AppText.bodySecondary("Updated: \(formatDate(rate.effectiveDate))")
                                }
                                Spacer()
                                AppText.bodyText(rate.formattedRate)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Show all roles, even if no rate exists
                    ForEach(UserRole.allCases.filter { role in
                        !viewModel.laborRates.contains { $0.role == role }
                    }) { role in
                        Button(action: {
                            selectedRole = role
                            showingEdit = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    AppText.bodyText(role.displayName)
                                    AppText.bodySecondary("No rate set")
                                        .foregroundColor(.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentGreen)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Labor Rates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button(role.displayName) {
                            selectedRole = role
                            showingEdit = true
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let role = selectedRole {
                let currentRate = viewModel.laborRates.first { $0.role == role }
                LaborRatesEditView(role: role, currentRate: currentRate, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadLaborRates()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
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
    @State private var showingNewUser = false
    @State private var selectedUser: User?
    @State private var showingEdit = false
    
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
                    Button("Add User") {
                        showingNewUser = true
                    }
                    .padding()
                    .background(Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.users) { user in
                        Button(action: {
                            selectedUser = user
                            showingEdit = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    AppText.bodyText(user.displayName)
                                    AppText.bodySecondary(user.email)
                                    AppText.caption("Role: \(user.role.rawValue) • \(user.isActive ? "Active" : "Inactive")")
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    try? await viewModel.deactivateUser(user)
                                }
                            } label: {
                                Label("Deactivate", systemImage: "person.slash")
                            }
                        }
                    }
                }
                .searchable(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { _, _ in
                    Task { await viewModel.loadUsers() }
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingNewUser = true
                }
            }
        }
        .sheet(isPresented: $showingNewUser) {
            UserEditView(user: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEdit) {
            if let user = selectedUser {
                UserEditView(user: user, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadUsers()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
    }
}

struct CompanySettingsView: View {
    @StateObject private var viewModel = CompanySettingsViewModel()
    @State private var showingCompanyEdit = false
    @State private var showingNewStore = false
    @State private var selectedStore: Store?
    @State private var showingStoreEdit = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let company = viewModel.company {
                        Section("Company Information") {
                            Button(action: {
                                showingCompanyEdit = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        DetailRow(label: "Name", value: company.name)
                                        DetailRow(label: "Contact", value: company.primaryContactInfo)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                        }
                    }
                    
                    Section("Stores") {
                        ForEach(viewModel.stores) { store in
                            Button(action: {
                                selectedStore = store
                                showingStoreEdit = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            AppText.bodyText(store.name)
                                            Spacer()
                                            if !store.isActive {
                                                AppText.caption("INACTIVE")
                                                    .foregroundColor(.accentRed)
                                            }
                                        }
                                        AppText.bodySecondary(store.location)
                                        AppText.bodySecondary(store.phone)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Company Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Store") {
                    showingNewStore = true
                }
            }
        }
        .sheet(isPresented: $showingCompanyEdit) {
            CompanyEditView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingNewStore) {
            StoreEditView(store: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingStoreEdit) {
            if let store = selectedStore {
                StoreEditView(store: store, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { }
        } message: { error in
            Text(error)
        }
    }
}

#Preview {
    NavigationView {
        AdminHomeView()
            .environmentObject(AuthService.shared)
    }
}
