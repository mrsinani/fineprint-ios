import SwiftUI
import ClerkKit
import ClerkKitUI

struct SettingsView: View {
    @Environment(Clerk.self) private var clerk
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = clerk.user {
                        if let email = user.primaryEmailAddress?.emailAddress {
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(email)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(user.id)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }

                    NavigationLink {
                        UserProfileView()
                    } label: {
                        Label("Manage Profile", systemImage: "person.circle")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Sign Out") {
                        showSignOutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }

                Section {
                    Button("Delete Account") {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await clerk.auth.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This action cannot be undone. All your documents and data will be permanently deleted.")
            }
        }
    }

    private func deleteAccount() async {
        do {
            var request = URLRequest(url: URL(string: Secrets.apiBaseURL + "/api/account")!)
            request.httpMethod = "DELETE"
            if let token = await AuthManager.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            _ = try await URLSession.shared.data(for: request)
            try await clerk.auth.signOut()
        } catch {
            // TODO: Show error to user
        }
    }
}

#Preview {
    SettingsView()
        .environment(Clerk.shared)
}
