import SwiftUI

struct DocumentsListView: View {
    var onOpenSettings: () -> Void = {}

    @State private var documents: [Document] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    BrandHeader(onMenuTap: onOpenSettings)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            PageTitle("Documents", subtitle: "All your analyzed contracts")
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            searchField
                                .padding(.horizontal, 20)

                            content
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }
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

    private var filteredDocuments: [Document] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return documents }
        return documents.filter { doc in
            doc.displayTitle.lowercased().contains(trimmed) ||
                doc.fileName.lowercased().contains(trimmed) ||
                (doc.documentType?.lowercased().contains(trimmed) ?? false)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Brand.inkTertiary)
            TextField("Search documents", text: $searchText)
                .textInputAutocapitalization(.never)
                .font(.system(size: 15))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Brand.inkTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Brand.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Brand.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && documents.isEmpty {
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    DocumentListSkeleton()
                }
            }
        } else if let error = errorMessage, documents.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Brand.riskMedium)
                Text("Failed to load documents")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Brand.inkSecondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await loadDocuments() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Brand.tealDeep, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else if filteredDocuments.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Brand.tealPrimary)
                Text(searchText.isEmpty ? "No documents yet" : "No matches")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                Text(searchText.isEmpty ? "Upload a contract to begin." : "Try a different search.")
                    .font(.system(size: 14))
                    .foregroundStyle(Brand.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredDocuments) { doc in
                    NavigationLink(value: doc) {
                        DocumentListCard(document: doc)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await trashDocument(doc) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
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

    private func trashDocument(_ doc: Document) async {
        do {
            try await APIClient.shared.trashDocument(id: doc.id)
            documents.removeAll { $0.id == doc.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DocumentListCard: View {
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

                if let type = document.documentType {
                    Text(type)
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

            if let score = document.overallRiskScore {
                RiskPill(score: score)
            }
        }
        .softCard(padding: 14)
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

private struct RiskPill: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch score {
        case 0..<40: Brand.riskLow
        case 40..<70: Brand.riskMedium
        default: Brand.riskHigh
        }
    }
}

private struct DocumentListSkeleton: View {
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

#Preview {
    DocumentsListView()
}
