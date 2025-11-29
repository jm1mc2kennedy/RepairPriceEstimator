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
        print("🚀 Initializing app...")
        
        // Check CloudKit account status (doesn't throw, just updates status)
        // This will fail gracefully if entitlements are missing
        await cloudKitService.refreshAccountStatus()
        print("📊 CloudKit account status: \(cloudKitService.accountStatus)")
        
        // Only bootstrap if CloudKit is available
        do {
            if await cloudKitService.isAvailable {
                print("☁️  CloudKit is available, bootstrapping data...")
                try await bootstrapService.bootstrapInitialData()
                print("✅ Bootstrap completed")
            } else {
                print("⚠️  CloudKit not available (status: \(cloudKitService.accountStatus))")
                print("   The app will still work, but CloudKit features will be unavailable.")
                print("   To enable CloudKit:")
                print("   1. Ensure entitlements are configured correctly")
                print("   2. Sign in to iCloud on the simulator/device")
                print("   3. Verify the CloudKit container exists in Apple Developer portal")
            }
        } catch {
            print("❌ Failed to bootstrap app data: \(error)")
            print("   Error details: \(error.localizedDescription)")
            print("   The app will continue without CloudKit features.")
        }
        
        print("✅ App initialization complete")
    }
}

// Temporary ContentView for now - will be replaced with proper auth flow
struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var cloudKitService: CloudKitService
    
    var body: some View {
        Group {
            // Always show login screen if not authenticated - don't wait for CloudKit
            if authService.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            print("📱 ContentView appeared")
            print("   Auth status: \(authService.isAuthenticated)")
            print("   CloudKit status: \(cloudKitService.accountStatus)")
        }
    }
}

// Debug view to test if SwiftUI is rendering at all
struct DebugView: View {
    var body: some View {
        VStack {
            Text("Debug View")
                .font(.largeTitle)
            Text("If you see this, SwiftUI is working")
                .font(.caption)
        }
        .padding()
    }
}
