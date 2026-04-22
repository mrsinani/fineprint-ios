import SwiftUI

struct AnalysisResultView: View {
    let analysis: AnalyzeApiResponse
    let documentTitle: String
    var documentId: String?
    var documentType: String? = nil
    var uploadedAtText: String? = nil

    @State private var selectedTab: Tab = .summary

    enum Tab: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case risk = "Risk Analysis"
        case actions = "Action Items"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .summary: "doc.text"
            case .risk: "exclamationmark.triangle"
            case .actions: "checklist"
            }
        }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    segmentedBar
                        .padding(.horizontal, 20)

                    Group {
                        switch selectedTab {
                        case .summary: summaryTab
                        case .risk: riskTab
                        case .actions: actionsTab
                        }
                    }
                    .padding(.horizontal, 20)

                    if let docId = documentId {
                        NavigationLink {
                            ChatView(documentId: docId, documentTitle: documentTitle)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Ask questions about this document")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Brand.deepGradient)
                            )
                            .shadow(color: Brand.tealDeep.opacity(0.22), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(documentTitle)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Brand.ink)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(documentType ?? "Document")
                    .font(.system(size: 13))
                    .foregroundStyle(Brand.inkSecondary)
                if let uploadedAtText {
                    Text("•").foregroundStyle(Brand.inkTertiary)
                    Text(uploadedAtText)
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var segmentedBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Brand.tealDeep : Brand.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Brand.tealSoft)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Brand.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Brand.subtleBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Summary tab

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            ContractOverviewCard(overview: analysis.summary.overview)

            if !analysis.summary.parties.isEmpty {
                WhoIsInvolvedCard(parties: analysis.summary.parties)
            }

            if !analysis.clauses.isEmpty {
                KeyTermsCard(clauses: analysis.clauses)
            }

            if !analysis.summary.plainEnglish.isEmpty {
                PlainEnglishCard(points: analysis.summary.plainEnglish)
            }
        }
    }

    // MARK: - Risk tab

    private var riskTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            RiskScoreCard(score: analysis.overallRiskScore)

            if analysis.clauses.isEmpty {
                EmptyTabCard(icon: "checkmark.seal", title: "No flagged clauses", subtitle: "Nothing stood out as risky.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Flagged Clauses (\(analysis.clauses.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Brand.ink)

                    VStack(spacing: 10) {
                        ForEach(analysis.clauses) { clause in
                            ClauseCard(clause: clause)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions tab

    private var actionsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if analysis.actionItems.isEmpty {
                EmptyTabCard(icon: "checkmark.circle", title: "No action items", subtitle: "You're good to go.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Action Items (\(analysis.actionItems.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Brand.ink)

                    VStack(spacing: 10) {
                        ForEach(analysis.actionItems) { item in
                            ActionItemCard(item: item)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shared cards

private struct ContractOverviewCard: View {
    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contract Overview")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(overview.isEmpty ? "Overview unavailable." : overview)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.summaryGradient)
        )
        .shadow(color: Brand.tealPrimary.opacity(0.25), radius: 14, x: 0, y: 6)
    }
}

private struct WhoIsInvolvedCard: View {
    let parties: [Party]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who's Involved")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Brand.ink)

            VStack(spacing: 10) {
                ForEach(parties) { party in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Brand.tealSoft)
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Brand.tealDeep)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(party.role)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Brand.inkSecondary)
                            Text(party.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Brand.ink)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Brand.tealTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .softCard(padding: 16)
    }
}

private struct KeyTermsCard: View {
    let clauses: [AnalysisClause]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Key Terms Explained")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Brand.ink)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.inkSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(clauses.prefix(5)) { clause in
                        KeyTermRow(clause: clause)
                    }
                }
            }
        }
        .softCard(padding: 16)
    }
}

private struct KeyTermRow: View {
    let clause: AnalysisClause
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconBackground)
                            .frame(width: 36, height: 36)
                        Image(systemName: iconName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(iconTint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clause.category.first ?? "Clause")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                            .lineLimit(1)
                        Text(clause.explanation)
                            .font(.system(size: 13))
                            .foregroundStyle(Brand.inkSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isExpanded && !clause.quote.isEmpty {
                Text("\u{201C}\(clause.quote)\u{201D}")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(Brand.inkSecondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Brand.tealTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if isExpanded && !clause.recommendation.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Brand.tealDeep)
                    Text(clause.recommendation)
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.ink)
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Brand.border, lineWidth: 1)
        )
    }

    private var iconName: String {
        let cat = (clause.category.first ?? "").lowercased()
        if cat.contains("duration") || cat.contains("term") || cat.contains("date") { return "calendar" }
        if cat.contains("payment") || cat.contains("fee") || cat.contains("price") || cat.contains("money") { return "dollarsign.circle.fill" }
        if cat.contains("confidential") || cat.contains("privacy") { return "lock.fill" }
        if cat.contains("liability") || cat.contains("risk") { return "exclamationmark.shield.fill" }
        return "doc.text.fill"
    }

    private var iconBackground: Color {
        switch clause.severity {
        case .high: Color.red.opacity(0.1)
        case .medium: Color.orange.opacity(0.1)
        case .low: Brand.tealSoft
        }
    }

    private var iconTint: Color {
        switch clause.severity {
        case .high: Brand.riskHigh
        case .medium: Brand.riskMedium
        case .low: Brand.tealDeep
        }
    }
}

private struct PlainEnglishCard: View {
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What This Means for You (Plain English)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(point)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .lineSpacing(3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.darkSummaryGradient)
        )
        .shadow(color: Brand.tealDeep.opacity(0.3), radius: 14, x: 0, y: 6)
    }
}

private struct RiskScoreCard: View {
    let score: Int

    var body: some View {
        VStack(spacing: 14) {
            Text("Overall Risk Score")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            ZStack {
                Circle()
                    .stroke(Brand.border, lineWidth: 10)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(score, 0), 100)) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("of 100")
                        .font(.system(size: 11))
                        .foregroundStyle(Brand.inkSecondary)
                }
            }

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .softCard(padding: 20)
    }

    private var color: Color {
        switch score {
        case 0..<40: Brand.riskLow
        case 40..<70: Brand.riskMedium
        default: Brand.riskHigh
        }
    }

    private var label: String {
        switch score {
        case 0..<40: "Low Risk"
        case 40..<70: "Medium Risk"
        default: "High Risk"
        }
    }
}

private struct ClauseCard: View {
    let clause: AnalysisClause
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clause.category.joined(separator: ", "))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                        Text(clause.severity.label + " Risk")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(severityColor)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.inkSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !clause.quote.isEmpty {
                        Text("\u{201C}\(clause.quote)\u{201D}")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundStyle(Brand.inkSecondary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Brand.tealTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Text(clause.explanation)
                        .font(.system(size: 14))
                        .foregroundStyle(Brand.ink)

                    if !clause.recommendation.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Brand.tealDeep)
                            Text(clause.recommendation)
                                .font(.system(size: 13))
                                .foregroundStyle(Brand.ink)
                        }
                    }

                    if let section = clause.section {
                        Text("Section: \(section)")
                            .font(.system(size: 11))
                            .foregroundStyle(Brand.inkTertiary)
                    }
                }
            }
        }
        .softCard(padding: 14)
    }

    private var severityColor: Color {
        switch clause.severity {
        case .high: Brand.riskHigh
        case .medium: Brand.riskMedium
        case .low: Brand.riskLow
        }
    }
}

private struct ActionItemCard: View {
    let item: AnalysisActionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                Spacer()
                Text(item.priority.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(priorityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(priorityColor.opacity(0.12), in: Capsule())
            }

            Text(item.description)
                .font(.system(size: 13))
                .foregroundStyle(Brand.inkSecondary)

            Text(item.category)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Brand.tealDeep)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Brand.tealSoft, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(padding: 14)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: Brand.riskHigh
        case .medium: Brand.riskMedium
        case .low: Brand.riskLow
        }
    }
}

private struct EmptyTabCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Brand.tealPrimary)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Brand.ink)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Brand.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .softCard(padding: 20)
    }
}
