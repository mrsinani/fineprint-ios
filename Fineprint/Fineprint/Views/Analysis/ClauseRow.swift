import SwiftUI

struct ClauseRow: View {
    let clause: AnalysisClause
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(clause.quote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)

                Text(clause.explanation)
                    .font(.subheadline)

                if !clause.recommendation.isEmpty {
                    Label(clause.recommendation, systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if let section = clause.section {
                    Text("Section: \(section)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            HStack(spacing: 8) {
                severityDot
                VStack(alignment: .leading, spacing: 2) {
                    Text(clause.category.joined(separator: ", "))
                        .font(.subheadline.weight(.medium))
                    Text(clause.severity.label)
                        .font(.caption)
                        .foregroundStyle(severityColor)
                }
            }
        }
    }

    private var severityDot: some View {
        Circle()
            .fill(severityColor)
            .frame(width: 10, height: 10)
    }

    private var severityColor: Color {
        switch clause.severity {
        case .high: .red
        case .medium: .orange
        case .low: .green
        }
    }
}
