import Foundation
import ClerkKit

enum AuthManager {
    /// Fetches a fresh session JWT from Clerk for API calls.
    static func getToken() async -> String? {
        try? await Clerk.shared.auth.getToken()
    }
}
