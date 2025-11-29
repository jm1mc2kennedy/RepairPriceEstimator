import SwiftUI
import CloudKit

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var cloudKitService: CloudKitService
    @State private var showingProfileEdit = false
    @State private var showingCloudKitStatus = false
    @State private var notificationsEnabled = true
    @State private var defaultStore: Store?
    @State private var availableStores: [Store] = []
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section("Account") {
                    if let session = authService.currentSession {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentGold)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                AppText.bodyText(session.user.displayName)
                                AppText.caption(session.user.email)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingProfileEdit = true
                        }
                        
                        Button(action: {
                            showingProfileEdit = true
                        }) {
                            HStack {
                                Text("Edit Profile")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                }
                
                // App Preferences
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    Picker("Default Store", selection: $defaultStore) {
                        Text("None").tag(nil as Store?)
                        ForEach(availableStores, id: \.id) { store in
                            Text(store.name).tag(store as Store?)
                        }
                    }
                }
                
                // CloudKit Status
                Section("Data & Sync") {
                    HStack {
                        Text("CloudKit Status")
                        Spacer()
                        CloudKitStatusBadge(status: cloudKitService.accountStatus)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingCloudKitStatus = true
                    }
                    
                    Button("View Sync Status") {
                        showingCloudKitStatus = true
                    }
                    
                    Button("Export Data") {
                        Task {
                            await exportData()
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.textSecondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
                
                // Sign Out
                Section {
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
            }
            .sheet(isPresented: $showingCloudKitStatus) {
                CloudKitStatusView()
            }
            .task {
                await loadStores()
            }
        }
    }
    
    private func loadStores() async {
        guard let session = authService.currentSession else { return }
        do {
            let predicate = NSPredicate(format: "companyId == %@ AND isActive == 1", session.company.id)
            availableStores = try await CloudKitService.shared.query(Store.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
        } catch {
            print("❌ Error loading stores: \(error)")
        }
    }
    
    private func exportData() async {
        // TODO: Implement data export
        print("Export data functionality to be implemented")
    }
}

struct CloudKitStatusBadge: View {
    let status: CKAccountStatus
    
    var body: some View {
        Group {
            switch status {
            case .available:
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .noAccount:
                Label("No Account", systemImage: "xmark.circle.fill")
                    .foregroundColor(.orange)
            case .restricted:
                Label("Restricted", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            case .couldNotDetermine:
                Label("Unknown", systemImage: "questionmark.circle.fill")
                    .foregroundColor(.gray)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
}

struct CloudKitStatusView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                CloudKitStatusBadge(status: cloudKitService.accountStatus)
                    .font(.title2)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Container ID", value: "iCloud.com.jewelryrepair.estimator")
                    DetailRow(label: "Database", value: "Private")
                    DetailRow(label: "Status", value: statusDescription)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("CloudKit Status")
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
    
    private var statusDescription: String {
        switch cloudKitService.accountStatus {
        case .available:
            return "Connected and syncing"
        case .noAccount:
            return "No iCloud account signed in"
        case .restricted:
            return "iCloud account restricted"
        case .couldNotDetermine:
            return "Unable to determine status"
        @unknown default:
            return "Unknown status"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
        .environmentObject(CloudKitService.shared)
}

