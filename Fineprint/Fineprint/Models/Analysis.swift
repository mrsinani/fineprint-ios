import Foundation

enum RiskSeverity: String, Codable, CaseIterable {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"

    var label: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }
}

struct AnalysisSummary: Codable {
    let overview: String
    let parties: [Party]
    let plainEnglish: [String]

    enum CodingKeys: String, CodingKey {
        case overview, parties
        case plainEnglish = "plain_english"
    }

    init(overview: String, parties: [Party], plainEnglish: [String]) {
        self.overview = overview
        self.parties = parties
        self.plainEnglish = plainEnglish
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overview = (try? container.decode(String.self, forKey: .overview)) ?? ""
        parties = (try? container.decode([Party].self, forKey: .parties)) ?? []
        plainEnglish = (try? container.decode([String].self, forKey: .plainEnglish)) ?? []
    }
}

struct Party: Codable, Identifiable {
    var id: String { "\(role)-\(name)" }
    let role: String
    let name: String
}

struct AnalysisClause: Codable, Identifiable {
    let id: String
    let category: [String]
    let severity: RiskSeverity
    let quote: String
    let charStart: Int?
    let charEnd: Int?
    let triggeredFeatures: [String]
    let explanation: String
    let recommendation: String
    let section: String?
    let confidence: RiskSeverity

    enum CodingKeys: String, CodingKey {
        case id, category, severity, quote, explanation, recommendation, section, confidence
        case charStart = "char_start"
        case charEnd = "char_end"
        case triggeredFeatures = "triggered_features"
    }
}

struct AnalysisActionItem: Codable, Identifiable {
    var id: String { title }
    let title: String
    let description: String
    let priority: RiskSeverity
    let category: String
}

struct AnalyzeApiResponse: Codable {
    let summary: AnalysisSummary
    let clauses: [AnalysisClause]
    let actionItems: [AnalysisActionItem]
    let overallRiskScore: Int

    enum CodingKeys: String, CodingKey {
        case summary, clauses
        case actionItems = "action_items"
        case overallRiskScore = "overall_risk_score"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = (try? container.decode(AnalysisSummary.self, forKey: .summary))
            ?? AnalysisSummary(overview: "", parties: [], plainEnglish: [])
        clauses = (try? container.decode([AnalysisClause].self, forKey: .clauses)) ?? []
        actionItems = (try? container.decode([AnalysisActionItem].self, forKey: .actionItems)) ?? []
        overallRiskScore = (try? container.decode(Int.self, forKey: .overallRiskScore)) ?? 0
    }

    init(summary: AnalysisSummary, clauses: [AnalysisClause], actionItems: [AnalysisActionItem], overallRiskScore: Int) {
        self.summary = summary
        self.clauses = clauses
        self.actionItems = actionItems
        self.overallRiskScore = overallRiskScore
    }
}
