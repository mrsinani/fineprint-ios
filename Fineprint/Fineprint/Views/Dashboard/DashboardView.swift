import SwiftUI

struct DashboardView: View {
    enum Destination {
        case upload
        case scan
        case documents
    }

    var onNavigate: (Destination) -> Void = { _ in }
    var onOpenSettings: () -> Void = {}

    @State private var documents: [Document] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDocument: Document?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    BrandHeader(onMenuTap: onOpenSettings)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            PageTitle("Welcome back!", subtitle: "Manage your contracts.")
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            QuickActionsRow(
                                onUpload: { onNavigate(.upload) },
                                onScan: { onNavigate(.scan) }
                            )
                            .padding(.horizontal, 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("My documents")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Brand.ink)
                                Text("Recently analyzed contracts")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Brand.inkSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                            VStack(spacing: 12) {
                                if isLoading && documents.isEmpty {
                                    ForEach(0..<3, id: \.self) { _ in
                                        DocumentCardSkeleton()
                                    }
                                } else if documents.isEmpty {
                                    EmptyDocumentsCard {
                                        onNavigate(.upload)
                                    }
                                } else {
                                    ForEach(documents.prefix(5)) { doc in
                                        NavigationLink(value: doc) {
                                            DocumentCard(document: doc)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if documents.count > 5 {
                                        Button {
                                            onNavigate(.documents)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text("View all documents")
                                                Image(systemName: "arrow.right")
                                            }
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Brand.tealDeep)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            Spacer(minLength: 40)
                        }
                        .padding(.bottom, 24)
                    }
                    .refreshable { await loadDocuments() }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Document.self) { doc in
                AnalysisView(document: doc)
            }
            .task { await loadDocuments() }
        }
    }

    private func loadDocuments() async {
        isLoading = true
        errorMessage = nil
        do {
            documents = try await APIClient.shared.fetchDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct QuickActionsRow: View {
    let onUpload: () -> Void
    let onScan: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            QuickActionCard(
                title: "Upload File",
                systemIcon: "arrow.up.doc.fill",
                gradient: Brand.lightGradient,
                iconColor: .white,
                action: onUpload
            )

            QuickActionCard(
                title: "Scan Now",
                systemIcon: "camera.fill",
                gradient: Brand.deepGradient,
                iconColor: .white,
                action: onScan
            )
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let systemIcon: String
    let gradient: LinearGradient
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 52, height: 52)
                    Image(systemName: systemIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(gradient)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentCard: View {
    let document: Document

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.tealTint)
                    .frame(width: 52, height: 52)
                Image(systemName: "folder.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Brand.tealDeep)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)

                if let fileName = trimmedFileName {
                    Text(fileName)
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(formattedDate)
                            .font(.system(size: 12))
                    }
                    if let pages = document.pageCount {
                        Text("•")
                        Text("\(pages) pages")
                            .font(.system(size: 12))
                    }
                }
                .foregroundStyle(Brand.inkTertiary)
            }

            Spacer()
        }
        .softCard(padding: 14)
    }

    private var trimmedFileName: String? {
        guard let name = document.fileName as String? else { return nil }
        let stem = (name as NSString).deletingPathExtension
        return stem.isEmpty ? nil : stem
    }

    private var formattedDate: String {
        guard let raw = document.createdAt else { return "—" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
        guard let d = date else { return raw }
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: d)
    }
}

private struct DocumentCardSkeleton: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Brand.tealTint)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Brand.border).frame(height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Brand.border).frame(width: 140, height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Brand.border).frame(width: 100, height: 10)
            }
            Spacer()
        }
        .softCard(padding: 14)
        .opacity(animate ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

private struct EmptyDocumentsCard: View {
    let onUpload: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Brand.tealPrimary)
            Text("No documents yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Brand.ink)
            Text("Upload your first contract to get started.")
                .font(.system(size: 14))
                .foregroundStyle(Brand.inkSecondary)
                .multilineTextAlignment(.center)

            Button(action: onUpload) {
                Text("Upload Document")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Brand.tealDeep, in: Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .softCard(padding: 20)
    }
}

#Preview {
    DashboardView()
}
