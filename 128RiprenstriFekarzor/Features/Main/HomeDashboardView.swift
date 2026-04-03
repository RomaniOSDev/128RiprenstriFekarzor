//
//  HomeDashboardView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var progress: GameProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your quiet arcade")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appHeadingDepth()
                        .padding(.top, 8)

                    Text("Short sessions, vivid feedback, and a star trail that marks how far you have wandered.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    heroCanvas

                    VStack(spacing: 12) {
                        statRow(title: "Total stars collected", value: "\(progress.totalStarsAcrossApp())")
                        statRow(title: "Time in play", value: formatTime(progress.totalPlaySeconds()))
                        statRow(title: "Sessions finished", value: "\(progress.totalSessionsPlayed())")
                        statRow(
                            title: "Rewards unlocked",
                            value: "\(progress.unlockedAchievementCount())/\(progress.totalAchievementCount())"
                        )
                    }
                    .padding(.vertical, 8)

                    Text("Highlights")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appAccent.opacity(0.12), radius: 6, y: 1)

                    ForEach(CasualActivity.allCases) { act in
                        ActivityTeaserCard(activity: act, starSum: progress.bestStarsSum(for: act))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Lobby")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 0)
                }
            }
        }
    }

    private var heroCanvas: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
            let rounded = RoundedRectangle(cornerRadius: 24, style: .continuous)
            let path = rounded.path(in: rect)
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color.appSurface, Color.appBackground.opacity(0.45)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
            context.stroke(path, with: .color(Color.appAccent.opacity(0.25)), lineWidth: 1.5)
            for i in 0..<5 {
                let inset = CGFloat(i) * 18
                let inner = rect.insetBy(dx: 20 + inset, dy: 20 + inset)
                var ring = Path()
                ring.addEllipse(in: inner)
                context.stroke(ring, with: .color(Color.appAccent.opacity(0.35 + Double(i) * 0.08)), lineWidth: 2)
            }
            let star = starPath(in: CGRect(x: rect.midX - 28, y: rect.midY - 28, width: 56, height: 56))
            context.fill(star, with: .color(Color.appPrimary))
        }
        .frame(height: 200)
        .appElevatedSurface(cornerRadius: 26)
    }

    private func starPath(in rect: CGRect) -> Path {
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

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .appElevatedSurface(cornerRadius: 16)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%dm %02ds", m, s)
    }
}

private struct ActivityTeaserCard: View {
    let activity: CasualActivity
    let starSum: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activity.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
            Text(activity.blurb)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            HStack {
                Text("Stars earned in this path")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("\(starSum)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedSurface(cornerRadius: 18)
    }
}
