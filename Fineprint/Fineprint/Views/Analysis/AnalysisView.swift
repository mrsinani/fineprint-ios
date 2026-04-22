import SwiftUI

/// Full analysis screen loaded from a Document (fetches from API).
struct AnalysisView: View {
    let document: Document

    @State private var analysis: AnalyzeApiResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading analysis…")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if let analysis {
                AnalysisResultView(
                    analysis: analysis,
                    documentTitle: document.displayTitle,
                    documentId: document.id
                )
            }
        }
        .navigationTitle(document.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAnalysis() }
    }

    private func loadAnalysis() async {
        do {
            let detail = try await APIClient.shared.fetchDocumentAnalysis(id: document.id)
            if let analysisData = detail.analysis {
                analysis = analysisData
            } else {
                errorMessage = "No analysis found for this document."
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            errorMessage = "Failed to load analysis data."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
