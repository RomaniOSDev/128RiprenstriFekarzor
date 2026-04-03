//
//  AppVisualEffects.swift
//  128RiprenstriFekarzor
//

import SwiftUI

// MARK: - Screen chrome

struct AppChromeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appBackground.opacity(0.94),
                    Color.appSurface.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.22),
                    Color.appAccent.opacity(0.1),
                    Color.clear
                ],
                center: UnitPoint(x: 0.9, y: -0.05),
                startRadius: 4,
                endRadius: 380
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.appBackground.opacity(0.55)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - View extensions

extension View {
    /// Full-screen layered gradient behind content (replaces flat `Color.appBackground`).
    func appRootBackground() -> some View {
        background {
            AppChromeBackground()
        }
    }

    /// Card / panel with volume: gradient fill, rim light, stacked shadows.
    func appElevatedSurface(cornerRadius: CGFloat = 18) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface,
                            Color.appSurface.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.45),
                                    Color.appTextPrimary.opacity(0.16),
                                    Color.appPrimary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                }
                .shadow(color: Color.appBackground.opacity(0.72), radius: 18, x: 0, y: 12)
                .shadow(color: Color.appAccent.opacity(0.14), radius: 10, x: 0, y: 5)
                .shadow(color: Color.appTextPrimary.opacity(0.06), radius: 2, x: 0, y: 1)
        }
    }

    /// Softer inset / secondary panel (less lift).
    func appInsetPanel(cornerRadius: CGFloat = 14) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.92),
                            Color.appBackground.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.appTextPrimary.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: Color.appBackground.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }

    /// Large headings: soft glow for depth on dark backdrops.
    func appHeadingDepth() -> some View {
        shadow(color: Color.appPrimary.opacity(0.2), radius: 14, x: 0, y: 2)
            .shadow(color: Color.appBackground.opacity(0.55), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Shared fills (buttons, chips)

enum AppFill {
    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary,
                Color.appAccent,
                Color.appPrimary.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var secondaryFaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface,
                Color.appSurface.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
