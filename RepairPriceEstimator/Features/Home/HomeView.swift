import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(navigationTiles) { tile in
                        NavigationTile(
                            tile: tile,
                            isEnabled: tile.isEnabled(for: authService.currentSession)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Repair Estimator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Profile") {
                            showingProfile = true
                        }
                        
                        Button("Sign Out", role: .destructive) {
                            authService.signOut()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var navigationTiles: [NavigationTileData] {
        [
            NavigationTileData(
                id: "new-quote",
                title: "New Quote",
                subtitle: "Create repair estimate",
                systemImage: "plus.circle.fill",
                color: .accentGreen,
                destination: AnyView(QuoteCreationView()),
                requiredPermissions: [.createQuotes]
            ),
            NavigationTileData(
                id: "find-quote",
                title: "Find Quote",
                subtitle: "Search existing quotes",
                systemImage: "magnifyingglass.circle.fill",
                color: .primaryBlue,
                destination: AnyView(QuoteListView()),
                requiredPermissions: [.viewQuotes]
            ),
            NavigationTileData(
                id: "guests",
                title: "Guests",
                subtitle: "Manage customers",
                systemImage: "person.2.circle.fill",
                color: .accentGold,
                destination: AnyView(GuestListView()),
                requiredPermissions: [.viewQuotes]
            ),
            NavigationTileData(
                id: "admin",
                title: "Admin",
                subtitle: "System settings",
                systemImage: "gear.circle.fill",
                color: .primaryDark,
                destination: AnyView(AdminHomeView()),
                requiredPermissions: [.accessAdmin]
            ),
            NavigationTileData(
                id: "reports",
                title: "Reports",
                subtitle: "Analytics & insights",
                systemImage: "chart.bar.circle.fill",
                color: .accentSilver,
                destination: AnyView(ReportsView()),
                requiredPermissions: [.viewQuotes]
            ),
            NavigationTileData(
                id: "settings",
                title: "Settings",
                subtitle: "App preferences",
                systemImage: "slider.horizontal.3",
                color: .textSecondary,
                destination: AnyView(SettingsView()),
                requiredPermissions: []
            )
        ]
    }
}

// MARK: - Navigation Tile Data

struct NavigationTileData: Identifiable {
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

// MARK: - Navigation Tile View

struct NavigationTile: View {
    let tile: NavigationTileData
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

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let session = authService.currentSession {
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentGold)
                        
                        AppText.cardTitle(session.user.displayName)
                        AppText.bodySecondary(session.user.role.rawValue)
                        AppText.caption(session.user.email)
                    }
                    .padding(.top, 30)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        AppText.fieldLabel("Company")
                        AppText.bodyText(session.company.name)
                        
                        AppText.fieldLabel("Primary Store")
                        AppText.bodyText(session.primaryStore.name)
                        
                        if session.accessibleStores.count > 1 {
                            AppText.fieldLabel("Accessible Stores")
                            ForEach(session.accessibleStores, id: \.id) { store in
                                AppText.bodySecondary("• \(store.name)")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentRed)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct ReportsView: View {
    var body: some View {
        AppText.pageTitle("Reports")
            .navigationTitle("Reports")
    }
}

struct SettingsView: View {
    var body: some View {
        AppText.pageTitle("Settings")
            .navigationTitle("Settings")
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.shared)
}
