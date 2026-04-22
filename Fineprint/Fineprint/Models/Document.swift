import Foundation

struct Document: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let fileName: String
    let fileType: String?
    let pageCount: Int?
    let documentType: String?
    let overallRiskScore: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case fileName = "file_name"
        case fileType = "file_type"
        case pageCount = "page_count"
        case documentType = "document_type"
        case overallRiskScore = "overall_risk_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayTitle: String {
        title
    }

    var riskColor: String {
        guard let score = overallRiskScore else { return "gray" }
        switch score {
        case 0..<40: return "green"
        case 40..<70: return "yellow"
        default: return "red"
        }
    }
}

struct DocumentListResponse: Codable {
    let documents: [Document]
}

struct UploadSignResponse: Codable {
    let signedUrl: String
    let token: String
    let storagePath: String
    let docId: String
    let fileType: String
}

struct SaveDocumentResponse: Codable {
    let id: String
}

struct DocumentDetailResponse: Codable {
    let id: String
    let title: String
    let fileName: String
    let fileType: String?
    let pageCount: Int?
    let documentType: String?
    let overallRiskScore: Int?
    let analysis: AnalyzeApiResponse?

    enum CodingKeys: String, CodingKey {
        case id, title, analysis
        case fileName = "file_name"
        case fileType = "file_type"
        case pageCount = "page_count"
        case documentType = "document_type"
        case overallRiskScore = "overall_risk_score"
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
}

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct ChatRequest: Codable {
    let documentId: String
    let messages: [ChatMessagePayload]
}

struct ChatMessagePayload: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let reply: String
}

struct ExtractResponse: Codable {
    let text: String
}
