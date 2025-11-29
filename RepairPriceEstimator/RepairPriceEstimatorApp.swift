import SwiftUI
import CloudKit

@main
struct RepairPriceEstimatorApp: App {
    @StateObject private var cloudKitService = CloudKitService.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var bootstrapService = BootstrapService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(authService)
                .environmentObject(bootstrapService)
                .task {
                    // Initialize CloudKit and bootstrap data on app launch
                    await initializeApp()
                }
        }
    }
    
    @MainActor
    private func initializeApp() async {
        do {
            // Check CloudKit account status
            try await cloudKitService.refreshAccountStatus()
            
            // Bootstrap initial data if needed
            try await bootstrapService.bootstrapInitialData()
        } catch {
            print("❌ Failed to initialize app: \(error)")
        }
    }
}

// Temporary ContentView for now - will be replaced with proper auth flow
struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}
