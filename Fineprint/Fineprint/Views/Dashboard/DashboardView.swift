import SwiftUI

struct DashboardView: View {
    @State private var documents: [Document] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDocument: Document?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && documents.isEmpty {
                    ProgressView("Loading documents…")
                } else if let error = errorMessage, documents.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Failed to load documents")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                                .padding(.horizontal)
                            Button("Retry") { Task { await loadDocuments() } }
                                .buttonStyle(.bordered)
                        }
                        .padding(.top, 60)
                    }
                } else if documents.isEmpty {
                    ContentUnavailableView {
                        Label("No Documents", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text("Upload a document to get started")
                    }
                } else {
                    List(documents) { doc in
                        NavigationLink(value: doc) {
                            DocumentRow(document: doc)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await trashDocument(doc) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .refreshable { await loadDocuments() }
                }
            }
            .navigationTitle("Documents")
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

    private func trashDocument(_ doc: Document) async {
        do {
            try await APIClient.shared.trashDocument(id: doc.id)
            documents.removeAll { $0.id == doc.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DashboardView()
}
