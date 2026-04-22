import SwiftUI

/// Full analysis screen loaded from a Document (fetches from API).
struct AnalysisView: View {
    let document: Document

    @State private var analysis: AnalyzeApiResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Brand.pageBackground.ignoresSafeArea()

            Group {
                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(Brand.tealDeep)
                            .scaleEffect(1.2)
                        Text("Loading analysis…")
                            .font(.system(size: 14))
                            .foregroundStyle(Brand.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Brand.riskMedium)
                        Text("Couldn't load analysis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Brand.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let analysis {
                    AnalysisResultView(
                        analysis: analysis,
                        documentTitle: document.displayTitle,
                        documentId: document.id,
                        documentType: documentSubtitle,
                        uploadedAtText: formattedUploadedAt
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadAnalysis() }
    }

    private var documentSubtitle: String {
        let ft = (document.fileType ?? "").lowercased()
        if ft.contains("pdf") { return "PDF Document" }
        if ft.contains("image") { return "Image Document" }
        return document.documentType ?? "Document"
    }

    private var formattedUploadedAt: String? {
        guard let raw = document.createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
        guard let d = date else { return nil }
        let df = DateFormatter()
        df.dateFormat = "'Uploaded' MMM d, yyyy"
        return df.string(from: d)
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
