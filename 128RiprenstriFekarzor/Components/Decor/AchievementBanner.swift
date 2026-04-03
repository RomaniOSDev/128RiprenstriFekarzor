//
//  AchievementBanner.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct AchievementBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Achievement")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appBackground)
                .textCase(.uppercase)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appBackground)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .shadow(color: Color.appBackground.opacity(0.25), radius: 2, y: 1)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appBackground.opacity(0.88))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appAccent,
                            Color.appPrimary.opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Color.appTextPrimary.opacity(0.28),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.appAccent.opacity(0.55), radius: 20, x: 0, y: 10)
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
                .shadow(color: Color.appBackground.opacity(0.45), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
    }
}
