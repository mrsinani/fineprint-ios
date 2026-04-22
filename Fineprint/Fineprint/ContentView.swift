import SwiftUI
import ClerkKit
import ClerkKitUI

struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    @State private var authIsPresented = false
    @State private var selectedTab: AppTab = .dashboard
    @State private var uploadInitialAction: UploadView.InitialAction = .none
    @State private var settingsPresented = false
    @State private var uploadResetCounter = 0

    enum AppTab: Hashable {
        case dashboard, upload, documents
    }

    var body: some View {
        if clerk.user != nil {
            signedInView
        } else {
            LandingView(authIsPresented: $authIsPresented)
                .sheet(isPresented: $authIsPresented) {
                    AuthView()
                }
        }
    }

    private var signedInView: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house.fill", value: AppTab.dashboard) {
                DashboardView(
                    onNavigate: handleDashboardNavigation,
                    onOpenSettings: { settingsPresented = true }
                )
            }

            Tab("Upload", systemImage: "arrow.up.doc.fill", value: AppTab.upload) {
                UploadView(
                    initialAction: uploadInitialAction,
                    onOpenSettings: { settingsPresented = true }
                )
                .id(uploadResetCounter)
            }

            Tab("Documents", systemImage: "doc.text.fill", value: AppTab.documents) {
                DocumentsListView(onOpenSettings: { settingsPresented = true })
            }
        }
        .environment(clerk)
        .tint(Brand.tealDeep)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.light)
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
        }
    }

    private func handleDashboardNavigation(_ destination: DashboardView.Destination) {
        switch destination {
        case .upload:
            uploadInitialAction = .none
            uploadResetCounter += 1
            selectedTab = .upload
        case .scan:
            uploadInitialAction = .scan
            uploadResetCounter += 1
            selectedTab = .upload
        case .documents:
            selectedTab = .documents
        }
    }
}

private struct LandingView: View {
    @Binding var authIsPresented: Bool
    @State private var contentAppeared = false

    var body: some View {
        ZStack {
            Image("HeroBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 28) {
                    Image("FineprintLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)

                    Text("Summarize, analyze, and review your\ncontracts with full confidence")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.6), value: contentAppeared)

                Spacer()
                Spacer()

                VStack(spacing: 14) {
                    Button {
                        authIsPresented = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(2.2)
                            .textCase(.uppercase)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                            )
                    }

                    Button {
                        authIsPresented = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("Sign In")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 13))
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 28)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.15), value: contentAppeared)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            contentAppeared = true
        }
    }
}

#Preview {
    ContentView()
        .environment(Clerk.shared)
}
