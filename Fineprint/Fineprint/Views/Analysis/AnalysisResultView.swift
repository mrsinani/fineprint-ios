import SwiftUI

/// Displays analysis results (used from both upload flow and document detail).
struct AnalysisResultView: View {
    let analysis: AnalyzeApiResponse
    let documentTitle: String
    var documentId: String?

    var body: some View {
        List {
            // Risk Score
            Section("Risk Score") {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(analysis.overallRiskScore)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(riskColor)
                        Text("out of 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // Summary
            Section("Summary") {
                Text(analysis.summary.overview)

                if !analysis.summary.parties.isEmpty {
                    DisclosureGroup("Parties") {
                        ForEach(analysis.summary.parties) { party in
                            HStack {
                                Text(party.role)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(party.name)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                if !analysis.summary.plainEnglish.isEmpty {
                    DisclosureGroup("Key Points") {
                        ForEach(analysis.summary.plainEnglish, id: \.self) { point in
                            Label(point, systemImage: "checkmark.circle")
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Flagged Clauses
            if !analysis.clauses.isEmpty {
                Section("Flagged Clauses (\(analysis.clauses.count))") {
                    ForEach(analysis.clauses) { clause in
                        ClauseRow(clause: clause)
                    }
                }
            }

            // Action Items
            if !analysis.actionItems.isEmpty {
                Section("Action Items (\(analysis.actionItems.count))") {
                    ForEach(analysis.actionItems) { item in
                        ActionItemRow(item: item)
                    }
                }
            }

            // Chat link
            if let docId = documentId {
                Section {
                    NavigationLink {
                        ChatView(documentId: docId, documentTitle: documentTitle)
                    } label: {
                        Label("Ask questions about this document", systemImage: "bubble.left.and.bubble.right")
                    }
                }
            }
        }
        .navigationTitle(documentTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var riskColor: Color {
        switch analysis.overallRiskScore {
        case 0..<40: .green
        case 40..<70: .orange
        default: .red
        }
    }
}
