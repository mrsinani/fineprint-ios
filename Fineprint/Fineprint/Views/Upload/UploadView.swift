import SwiftUI
import UniformTypeIdentifiers
import VisionKit

struct UploadView: View {
    enum InitialAction {
        case none
        case scan
    }

    var initialAction: InitialAction = .none
    var onOpenSettings: () -> Void = {}

    @State private var isPickerPresented = false
    @State private var isScannerPresented = false
    @State private var isProcessingScan = false
    @State private var selectedFileName: String?
    @State private var selectedFileData: Data?
    @State private var selectedFileType: String = "application/pdf"
    @State private var scannedPageCount: Int?
    @State private var documentType = "Lease Agreement"
    @State private var isUploading = false
    @State private var uploadProgress: String?
    @State private var errorMessage: String?
    @State private var analysisResult: AnalyzeApiResponse?
    @State private var showAnalysis = false
    @State private var didHandleInitial = false

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
            ZStack {
                Brand.pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    BrandHeader(onMenuTap: onOpenSettings)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            PageTitle("Upload File", subtitle: "Manage and analyze your contracts")
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            sourceCards
                                .padding(.horizontal, 20)

                            if selectedFileName != nil || isProcessingScan {
                                fileDetailsSection
                                    .padding(.horizontal, 20)
                            }

                            if let error = errorMessage {
                                errorCard(error)
                                    .padding(.horizontal, 20)
                            }

                            if selectedFileData != nil {
                                uploadButton
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.pdf, .png, .jpeg],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .fullScreenCover(isPresented: $isScannerPresented) {
                DocumentScannerView { images in
                    isScannerPresented = false
                    Task { await processScannedImages(images) }
                } onCancel: {
                    isScannerPresented = false
                }
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $showAnalysis) {
                if let analysis = analysisResult {
                    AnalysisResultView(
                        analysis: analysis,
                        documentTitle: selectedFileName ?? "Document"
                    )
                }
            }
            .onAppear {
                guard !didHandleInitial else { return }
                didHandleInitial = true
                if initialAction == .scan && VNDocumentCameraViewController.isSupported {
                    isScannerPresented = true
                }
            }
        }
    }

    private var sourceCards: some View {
        VStack(spacing: 14) {
            SourceCard(
                title: "Browse Files",
                subtitle: "Upload PDF or image files",
                systemIcon: "folder.fill",
                iconGradient: Brand.lightGradient,
                tintBackground: false
            ) {
                isPickerPresented = true
            }

            if VNDocumentCameraViewController.isSupported {
                SourceCard(
                    title: "Scan Document",
                    subtitle: "Use your camera to capture documents",
                    systemIcon: "camera.fill",
                    iconGradient: Brand.deepGradient,
                    tintBackground: true
                ) {
                    isScannerPresented = true
                }
            }
        }
    }

    private var fileDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Selected file")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Brand.tealTint)
                        .frame(width: 48, height: 48)
                    if isProcessingScan {
                        ProgressView()
                            .tint(Brand.tealDeep)
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.tealDeep)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    if isProcessingScan {
                        Text("Recognizing text…")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                        Text("Running OCR on scanned pages")
                            .font(.system(size: 12))
                            .foregroundStyle(Brand.inkSecondary)
                    } else if let name = selectedFileName {
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                            .lineLimit(1)
                        if let pages = scannedPageCount {
                            Text("\(pages) page\(pages == 1 ? "" : "s") · Ready to upload")
                                .font(.system(size: 12))
                                .foregroundStyle(Brand.inkSecondary)
                        } else {
                            Text(selectedFileType.replacingOccurrences(of: "application/", with: "").uppercased())
                                .font(.system(size: 12))
                                .foregroundStyle(Brand.inkSecondary)
                        }
                    }
                }

                Spacer()

                if !isProcessingScan && selectedFileData != nil {
                    Button {
                        clearSelection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.inkTertiary)
                    }
                }
            }
            .softCard(padding: 14)

            HStack {
                Text("Document Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Brand.ink)
                Spacer()
                Menu {
                    ForEach(documentTypes, id: \.self) { type in
                        Button(type) { documentType = type }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(documentType)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Brand.tealDeep)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Brand.tealDeep)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Brand.tealSoft, in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Brand.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Brand.subtleBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var uploadButton: some View {
        Button {
            Task { await uploadAndAnalyze() }
        } label: {
            HStack(spacing: 10) {
                if isUploading {
                    ProgressView()
                        .tint(.white)
                }
                Text(isUploading ? (uploadProgress ?? "Processing…") : "Upload & Analyze")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.deepGradient)
            )
            .shadow(color: Brand.tealDeep.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(selectedFileData == nil || isUploading || isProcessingScan)
        .opacity((selectedFileData == nil || isUploading || isProcessingScan) ? 0.6 : 1)
    }

    private func errorCard(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Brand.riskHigh)
            VStack(alignment: .leading, spacing: 4) {
                Text("Something went wrong")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.inkSecondary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .softCard(padding: 14)
    }

    private func clearSelection() {
        selectedFileName = nil
        selectedFileData = nil
        scannedPageCount = nil
        errorMessage = nil
    }

    private func processScannedImages(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }

        isProcessingScan = true
        errorMessage = nil
        selectedFileName = nil
        selectedFileData = nil

        let result = await SearchablePDFBuilder.build(from: images)

        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .medium,
            timeStyle: .short
        ).replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        selectedFileName = "Scan \(timestamp).pdf"
        selectedFileData = result.pdfData
        selectedFileType = "application/pdf"
        scannedPageCount = result.pageCount
        isProcessingScan = false
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
                scannedPageCount = nil

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
                pageCount: scannedPageCount,
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

private struct SourceCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String
    let iconGradient: LinearGradient
    let tintBackground: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: systemIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Brand.ink)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.inkSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tintBackground ? Brand.tealTint : Brand.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tintBackground ? Brand.tealPrimary.opacity(0.3) : Brand.subtleBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UploadView()
}
