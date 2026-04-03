//
//  PrimaryGameButton.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct PrimaryGameButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
                .shadow(color: Color.appBackground.opacity(0.35), radius: 0, y: 1)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppFill.primaryButtonGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appTextPrimary.opacity(0.42),
                                    Color.appAccent.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.15
                        )
                }
                .shadow(color: Color.appAccent.opacity(0.48), radius: 14, x: 0, y: 7)
                .shadow(color: Color.appBackground.opacity(0.55), radius: 8, x: 0, y: 4)
                .shadow(color: Color.appPrimary.opacity(0.22), radius: 6, x: 0, y: 0)
        }
    }
}

struct SecondaryGameButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppFill.secondaryFaceGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.55),
                                    Color.appPrimary.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: Color.appBackground.opacity(0.6), radius: 12, x: 0, y: 6)
                .shadow(color: Color.appAccent.opacity(0.1), radius: 6, x: 0, y: 2)
        }
    }
}
