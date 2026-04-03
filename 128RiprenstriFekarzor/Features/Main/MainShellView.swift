//
//  MainShellView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case activities
    case rewards
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .activities: return "Activities"
        case .rewards: return "Rewards"
        case .profile: return "Profile"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .activities: return "square.grid.3x3.fill"
        case .rewards: return "rosette"
        case .profile: return "person.crop.circle"
        }
    }
}

struct MainShellView: View {
    @State private var tab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            AppChromeBackground()
            Group {
                switch tab {
                case .home:
                    HomeDashboardView()
                case .activities:
                    ActivitiesFlowView()
                case .rewards:
                    RewardsVaultView()
                case .profile:
                    ProfileOverviewView()
                }
            }
            .padding(.bottom, 68)

            CasualTabBar(selection: $tab)
        }
    }
}

private struct CasualTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        selection = item
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == item ? Color.appPrimary : Color.appTextSecondary)
                    .shadow(
                        color: selection == item ? Color.appPrimary.opacity(0.55) : Color.clear,
                        radius: 10,
                        y: 0
                    )
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface,
                            Color.appSurface.opacity(0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.4),
                                    Color.appTextPrimary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                }
                .shadow(color: Color.appBackground.opacity(0.72), radius: 22, x: 0, y: -6)
                .shadow(color: Color.appAccent.opacity(0.16), radius: 14, x: 0, y: -3)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
