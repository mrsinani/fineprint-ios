import SwiftUI

struct ActionItemRow: View {
    let item: AnalysisActionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(item.priority.label)
                    .font(.caption.bold())
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.15), in: Capsule())
            }

            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(item.category)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: .red
        case .medium: .orange
        case .low: .green
        }
    }
}
