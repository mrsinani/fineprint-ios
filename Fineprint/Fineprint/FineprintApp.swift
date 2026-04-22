import SwiftUI
import ClerkKit

@main
struct FineprintApp: App {
    init() {
        Clerk.configure(publishableKey: Secrets.clerkPublishableKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Clerk.shared)
        }
    }
}
