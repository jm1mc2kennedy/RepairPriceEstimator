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
    
    func isEnabled(for session: UserSession?) -> Bool {
        guard let session = session else { return false }
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

// MARK: - Placeholder Admin Views

struct PricingRulesView: View {
    var body: some View {
        AppText.pageTitle("Pricing Rules")
            .navigationTitle("Pricing Rules")
    }
}

struct MetalRatesView: View {
    var body: some View {
        AppText.pageTitle("Metal Rates")
            .navigationTitle("Metal Rates")
    }
}

struct LaborRatesView: View {
    var body: some View {
        AppText.pageTitle("Labor Rates")
            .navigationTitle("Labor Rates")
    }
}

struct UserManagementView: View {
    var body: some View {
        AppText.pageTitle("User Management")
            .navigationTitle("Users")
    }
}

struct CompanySettingsView: View {
    var body: some View {
        AppText.pageTitle("Company Settings")
            .navigationTitle("Company")
    }
}

#Preview {
    NavigationView {
        AdminHomeView()
            .environmentObject(AuthService.shared)
    }
}
