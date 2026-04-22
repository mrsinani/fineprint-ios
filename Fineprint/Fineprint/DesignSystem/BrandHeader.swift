import SwiftUI

struct BrandHeader: View {
    var onMenuTap: () -> Void = {}

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Brand.tealSoft)
                    .frame(width: 44, height: 44)
                Image("FineprintLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }

            Spacer()

            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Brand.tealDeep)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(Brand.pageBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Brand.border)
                .frame(height: 1)
        }
    }
}

struct PageTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Brand.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Brand.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
