import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized(String)
    case serverError(Int, String, String)
    case decodingError(Error)
    case networkError(Error)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .unauthorized(let detail):
            "Unauthorized (401): \(detail)"
        case .serverError(let code, let path, let body):
            "[\(code)] \(path)\n\(body)"
        case .decodingError(let err):
            "Failed to parse response: \(err.localizedDescription)"
        case .networkError(let err):
            "Network error: \(err.localizedDescription)"
        case .unknown(let msg):
            msg
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = Secrets.apiBaseURL
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Documents

    func fetchDocuments(limit: Int = 20, offset: Int = 0) async throws -> [Document] {
        let data = try await get("/api/documents?limit=\(limit)&offset=\(offset)")
        return try decoder.decode([Document].self, from: data)
    }

    func fetchDocument(id: String) async throws -> Document {
        let data = try await get("/api/documents/\(id)")
        return try decoder.decode(Document.self, from: data)
    }

    func fetchDocumentAnalysis(id: String) async throws -> DocumentDetailResponse {
        let data = try await get("/api/documents/\(id)")
        return try decoder.decode(DocumentDetailResponse.self, from: data)
    }

    // MARK: - Upload

    func getSignedUploadURL(fileName: String, fileType: String) async throws -> UploadSignResponse {
        let body: [String: Any] = ["fileName": fileName, "fileType": fileType]
        let data = try await post("/api/upload/sign", body: body)
        return try decoder.decode(UploadSignResponse.self, from: data)
    }

    func uploadFile(to signedUrl: String, data fileData: Data, fileType: String) async throws {
        guard let url = URL(string: signedUrl) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(fileType, forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData
        let (respData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: respData, encoding: .utf8) ?? "(no body)"
            throw APIError.serverError(code, signedUrl, body)
        }
    }

    // MARK: - Analysis

    func analyzeDocument(storagePath: String, fileType: String, documentType: String) async throws -> AnalyzeApiResponse {
        let body: [String: Any] = [
            "storagePath": storagePath,
            "fileType": fileType,
            "documentType": documentType
        ]
        let data = try await post("/api/analyze", body: body)
        return try decoder.decode(AnalyzeApiResponse.self, from: data)
    }

    func saveDocument(
        storagePath: String,
        docId: String,
        fileName: String,
        fileType: String,
        analysisResult: AnalyzeApiResponse,
        documentType: String,
        pageCount: Int?,
        title: String?
    ) async throws -> SaveDocumentResponse {
        var body: [String: Any] = [
            "storagePath": storagePath,
            "docId": docId,
            "fileName": fileName,
            "fileType": fileType,
            "documentType": documentType
        ]
        if let pageCount { body["pageCount"] = pageCount }
        if let title { body["title"] = title }

        let analysisData = try JSONEncoder().encode(analysisResult)
        if let analysisDict = try JSONSerialization.jsonObject(with: analysisData) as? [String: Any] {
            body["analysisResult"] = analysisDict
        }

        let data = try await post("/api/documents", body: body)
        return try decoder.decode(SaveDocumentResponse.self, from: data)
    }

    // MARK: - Chat

    func sendChatMessage(documentId: String, messages: [ChatMessage]) async throws -> String {
        let payloads = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let body: [String: Any] = [
            "documentId": documentId,
            "messages": payloads
        ]
        let data = try await post("/api/chat", body: body)
        let response = try decoder.decode(ChatResponse.self, from: data)
        return response.reply
    }

    // MARK: - Trash

    func trashDocument(id: String) async throws {
        _ = try await post("/api/documents/trash", body: ["id": id])
    }

    func restoreDocument(id: String) async throws {
        _ = try await patch("/api/documents/trash", body: ["id": id])
    }

    func permanentlyDeleteDocument(id: String) async throws {
        _ = try await delete("/api/documents/trash", body: ["id": id])
    }

    // MARK: - Private Helpers

    private func get(_ path: String) async throws -> Data {
        let request = try await makeRequest(path, method: "GET")
        return try await execute(request)
    }

    private func post(_ path: String, body: [String: Any]) async throws -> Data {
        var request = try await makeRequest(path, method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func patch(_ path: String, body: [String: Any]) async throws -> Data {
        var request = try await makeRequest(path, method: "PATCH")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func delete(_ path: String, body: [String: Any]) async throws -> Data {
        var request = try await makeRequest(path, method: "DELETE")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func makeRequest(_ path: String, method: String) async throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await AuthManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }
        let path = request.url?.path ?? "unknown"
        let responseBody = String(data: data, encoding: .utf8) ?? "(no body)"

        if http.statusCode == 401 {
            throw APIError.unauthorized(responseBody)
        }
        guard (200...299).contains(http.statusCode) else {
            print("❌ API Error [\(http.statusCode)] \(request.httpMethod ?? "?") \(path): \(responseBody)")
            throw APIError.serverError(http.statusCode, path, responseBody)
        }
        return data
    }
}
