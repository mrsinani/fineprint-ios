import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var isPickerPresented = false
    @State private var selectedFileName: String?
    @State private var selectedFileData: Data?
    @State private var selectedFileType: String = "application/pdf"
    @State private var documentType = "Lease Agreement"
    @State private var isUploading = false
    @State private var uploadProgress: String?
    @State private var errorMessage: String?
    @State private var analysisResult: AnalyzeApiResponse?
    @State private var showAnalysis = false

    private let documentTypes = [
        "Lease Agreement",
        "Employment Contract",
        "NDA",
        "Terms of Service",
        "Privacy Policy",
        "Service Agreement",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    Button {
                        isPickerPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(selectedFileName ?? "Select a document")
                                .foregroundStyle(selectedFileName == nil ? .secondary : .primary)
                        }
                    }

                    Picker("Document Type", selection: $documentType) {
                        ForEach(documentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                if let error = errorMessage {
                    Section("Error") {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Button {
                        Task { await uploadAndAnalyze() }
                    } label: {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text(isUploading ? (uploadProgress ?? "Processing…") : "Upload & Analyze")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedFileData == nil || isUploading)
                }
            }
            .navigationTitle("Upload")
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.pdf, .png, .jpeg],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .navigationDestination(isPresented: $showAnalysis) {
                if let analysis = analysisResult {
                    AnalysisResultView(
                        analysis: analysis,
                        documentTitle: selectedFileName ?? "Document"
                    )
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                selectedFileData = try Data(contentsOf: url)
                selectedFileName = url.lastPathComponent

                let ext = url.pathExtension.lowercased()
                switch ext {
                case "pdf": selectedFileType = "application/pdf"
                case "png": selectedFileType = "image/png"
                case "jpg", "jpeg": selectedFileType = "image/jpeg"
                default: selectedFileType = "application/octet-stream"
                }
                errorMessage = nil
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func uploadAndAnalyze() async {
        guard let fileData = selectedFileData, let fileName = selectedFileName else { return }
        isUploading = true
        errorMessage = nil

        do {
            uploadProgress = "Getting upload URL…"
            let signResponse = try await APIClient.shared.getSignedUploadURL(
                fileName: fileName,
                fileType: selectedFileType
            )

            uploadProgress = "Uploading file…"
            try await APIClient.shared.uploadFile(
                to: signResponse.signedUrl,
                data: fileData,
                fileType: selectedFileType
            )

            uploadProgress = "Analyzing document…"
            let analysis = try await APIClient.shared.analyzeDocument(
                storagePath: signResponse.storagePath,
                fileType: selectedFileType,
                documentType: documentType
            )

            uploadProgress = "Saving results…"
            _ = try await APIClient.shared.saveDocument(
                storagePath: signResponse.storagePath,
                docId: signResponse.docId,
                fileName: fileName,
                fileType: selectedFileType,
                analysisResult: analysis,
                documentType: documentType,
                pageCount: nil,
                title: fileName
            )

            analysisResult = analysis
            showAnalysis = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploading = false
        uploadProgress = nil
    }
}

#Preview {
    UploadView()
}
