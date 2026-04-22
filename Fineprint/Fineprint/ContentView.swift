import SwiftUI
import ClerkKit
import ClerkKitUI

struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    @State private var authIsPresented = false

    var body: some View {
        if clerk.user != nil {
            TabView {
                Tab("Documents", systemImage: "doc.text") {
                    DashboardView()
                }

                Tab("Upload", systemImage: "arrow.up.doc") {
                    UploadView()
                }

                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                }
            }
            .environment(clerk)
        } else {
            VStack(spacing: 20) {
                Text("FinePrint")
                    .font(.largeTitle.bold())

                Text("AI-powered document analysis")
                    .foregroundStyle(.secondary)

                Button("Sign In") {
                    authIsPresented = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .sheet(isPresented: $authIsPresented) {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(Clerk.shared)
}
