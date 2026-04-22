import SwiftUI

struct DocumentRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let type = document.documentType {
                        Text(type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let pages = document.pageCount {
                        Text("\(pages) pages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let score = document.overallRiskScore {
                RiskBadge(score: score)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        let ft = document.fileType ?? ""
        if ft.contains("pdf") { return "doc.fill" }
        if ft.contains("image") { return "photo" }
        return "doc.text"
    }
}

struct RiskBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor, in: Capsule())
    }

    private var badgeColor: Color {
        switch score {
        case 0..<40: .green
        case 40..<70: .orange
        default: .red
        }
    }
}
