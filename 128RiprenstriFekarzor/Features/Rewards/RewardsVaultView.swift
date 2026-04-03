//
//  RewardsVaultView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct RewardsVaultView: View {
    @EnvironmentObject private var progress: GameProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    Text("Every milestone unlocks automatically when you meet its goal. Keep playing across all three paths to fill the vault.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    let rows = progress.rewardsCatalogRows()
                    LazyVStack(spacing: 12) {
                        ForEach(rows, id: \.info.id) { row in
                            rewardRow(info: row.info, unlocked: row.unlocked)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rewards")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 0)
                }
            }
        }
    }

    private var header: some View {
        let total = progress.totalAchievementCount()
        let done = progress.unlockedAchievementCount()
        let ratio = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("Trophy vault")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .appHeadingDepth()

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.appSurface, lineWidth: 10)
                        .frame(width: 86, height: 86)
                    Circle()
                        .trim(from: 0, to: ratio)
                        .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(done)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("of \(total)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Unlocked rewards")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(progress.totalStarsAcrossApp() > 0
                        ? "You have cleared \(done) goals. Chase the rest for a full vault."
                        : "Play any stage to start collecting recognition badges.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appElevatedSurface(cornerRadius: 20)
        }
    }

    private func rewardRow(info: GameProgressStore.AchievementInfo, unlocked: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RewardSealView(filled: unlocked)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(info.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(unlocked ? Color.appTextPrimary : Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    if !unlocked {
                        Text("Locked")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.appTextSecondary.opacity(0.7)))
                    }
                }
                Text(info.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(unlocked ? Color.appTextSecondary : Color.appTextSecondary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(RewardRowChrome(unlocked: unlocked))
    }
}

private struct RewardRowChrome: ViewModifier {
    let unlocked: Bool

    func body(content: Content) -> some View {
        Group {
            if unlocked {
                content
                    .appElevatedSurface(cornerRadius: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1.5)
                    )
            } else {
                content
                    .appInsetPanel(cornerRadius: 16)
            }
        }
    }
}

private struct RewardSealView: View {
    let filled: Bool

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            let star = rewardStarPath(in: rect)
            if filled {
                context.fill(star, with: .linearGradient(
                    Gradient(colors: [Color.appPrimary, Color.appAccent]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                ))
                context.stroke(star, with: .color(Color.appTextPrimary.opacity(0.2)), lineWidth: 1)
            } else {
                context.stroke(star, with: .color(Color.appTextSecondary.opacity(0.4)), lineWidth: 2)
            }
        }
    }

    private func rewardStarPath(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let points = 5
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? r : r * 0.45
            let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
