import SwiftUI

enum Brand {
    static let pageBackground = Color(hex: 0xF7F9FA)
    static let cardBackground = Color.white
    static let border = Color(hex: 0xEDEFF2)
    static let subtleBorder = Color(hex: 0xE7EBEE)

    static let ink = Color(hex: 0x111827)
    static let inkSecondary = Color(hex: 0x6B7280)
    static let inkTertiary = Color(hex: 0x9CA3AF)

    static let tealPrimary = Color(hex: 0x4FB3A9)
    static let tealDeep = Color(hex: 0x2F7F82)
    static let tealSoft = Color(hex: 0xE6F4F2)
    static let tealTint = Color(hex: 0xF1F8F6)

    static let riskLow = Color(hex: 0x10B981)
    static let riskMedium = Color(hex: 0xF59E0B)
    static let riskHigh = Color(hex: 0xEF4444)

    static let lightGradient = LinearGradient(
        colors: [Color(hex: 0xB7DEDA), Color(hex: 0x7CC4BA)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let deepGradient = LinearGradient(
        colors: [Color(hex: 0x3E9AA0), Color(hex: 0x296E74)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let summaryGradient = LinearGradient(
        colors: [Color(hex: 0x6AC6BE), Color(hex: 0x85D3AB)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let darkSummaryGradient = LinearGradient(
        colors: [Color(hex: 0x25787F), Color(hex: 0x2F8F78)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

struct SoftCardStyle: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Brand.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Brand.subtleBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func softCard(padding: CGFloat = 16, cornerRadius: CGFloat = 18) -> some View {
        modifier(SoftCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}
