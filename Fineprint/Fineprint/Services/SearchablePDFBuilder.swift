import Foundation
import UIKit
@preconcurrency import Vision
import ImageIO

enum SearchablePDFBuilder {
    struct Result {
        let pdfData: Data
        let pageCount: Int
        let extractedText: String
    }

    static func build(from images: [UIImage]) async -> Result {
        var pageObservations: [[VNRecognizedTextObservation]] = []
        var textChunks: [String] = []

        for image in images {
            let observations = await recognizeText(in: image)
            pageObservations.append(observations)

            let pageText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            textChunks.append(pageText)
        }

        let combinedText = textChunks.joined(separator: "\n\n")

        let defaultBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: defaultBounds)

        let data = renderer.pdfData { ctx in
            for (index, image) in images.enumerated() {
                let pageSize = image.size
                let pageRect = CGRect(origin: .zero, size: pageSize)
                ctx.beginPage(withBounds: pageRect, pageInfo: [:])

                image.draw(in: pageRect)

                drawInvisibleTextLayer(
                    observations: pageObservations[index],
                    pageSize: pageSize
                )
            }
        }

        return Result(pdfData: data, pageCount: images.count, extractedText: combinedText)
    }

    private static func drawInvisibleTextLayer(
        observations: [VNRecognizedTextObservation],
        pageSize: CGSize
    ) {
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            guard !text.isEmpty else { continue }

            let bbox = observation.boundingBox
            let rect = CGRect(
                x: bbox.minX * pageSize.width,
                y: (1 - bbox.maxY) * pageSize.height,
                width: bbox.width * pageSize.width,
                height: bbox.height * pageSize.height
            )
            guard rect.height > 0.5, rect.width > 0.5 else { continue }

            let fontSize = max(1, rect.height * 0.8)
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byClipping
            paragraph.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.clear,
                .paragraphStyle: paragraph
            ]

            let attributed = NSAttributedString(string: text, attributes: attributes)
            attributed.draw(in: rect)
        }
    }

    private static func recognizeText(in image: UIImage) async -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = cgImagePropertyOrientation(from: image.imageOrientation)

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let results = (request.results as? [VNRecognizedTextObservation]) ?? []
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private static func cgImagePropertyOrientation(
        from uiOrientation: UIImage.Orientation
    ) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
