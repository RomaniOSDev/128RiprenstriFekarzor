//
//  ActivityResultView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ActivityResultView: View {
    let payload: ActivitySummaryPayload
    @Binding var path: NavigationPath
    @State private var starVisibility: [Bool] = [false, false, false]
    @State private var showBanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text(payload.won ? "Stage complete" : "Stage incomplete")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .appHeadingDepth()

                HStack(spacing: 18) {
                    ForEach(0..<3, id: \.self) { i in
                        AnimatedResultStar(
                            show: i < payload.stars ? starVisibility[safe: i] ?? false : false,
                            index: i
                        )
                        .opacity(i < payload.stars ? 1 : 0.25)
                    }
                }
                .padding(.vertical, 8)

                VStack(spacing: 12) {
                    metricRow(title: "Duration", value: formatDuration(payload.durationSeconds))
                    metricRow(title: "Precision", value: "\(payload.accuracyPercent)%")
                    Text(payload.detailLineA)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                    Text(payload.detailLineB)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .appElevatedSurface(cornerRadius: 18)

                if let first = payload.freshAchievements.first {
                    if showBanner {
                        AchievementBanner(title: first.title, subtitle: first.subtitle)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                VStack(spacing: 12) {
                    if payload.won, payload.level < GameProgress.levelsPerActivity {
                        PrimaryGameButton(title: "Next stage") {
                            goNext()
                        }
                    }
                    SecondaryGameButton(title: "Retry stage") {
                        retry()
                    }
                    SecondaryGameButton(title: "Back to stage list") {
                        path.removeLast()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationTitle("Outcome")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            animateStars()
            if !payload.freshAchievements.isEmpty {
                withAnimation(.easeInOut(duration: 0.45).delay(0.55)) {
                    showBanner = true
                }
            }
        }
    }

    private func animateStars() {
        starVisibility = [false, false, false]
        for i in 0..<min(payload.stars, 3) {
            let delay = Double(i) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                    var next = starVisibility
                    if next.indices.contains(i) {
                        next[i] = true
                        starVisibility = next
                    }
                }
            }
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatDuration(_ t: Double) -> String {
        let s = Int(t.rounded())
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    private func goNext() {
        let nextLevel = payload.level + 1
        path.removeLast()
        switch payload.activity {
        case .colorCascade:
            path.append(FlowStep.playCascade(payload.activity, payload.difficulty, nextLevel))
        case .shapeShuffle:
            path.append(FlowStep.playShape(payload.activity, payload.difficulty, nextLevel))
        case .patternPlay:
            path.append(FlowStep.playPattern(payload.activity, payload.difficulty, nextLevel))
        }
    }

    private func retry() {
        path.removeLast()
        switch payload.activity {
        case .colorCascade:
            path.append(FlowStep.playCascade(payload.activity, payload.difficulty, payload.level))
        case .shapeShuffle:
            path.append(FlowStep.playShape(payload.activity, payload.difficulty, payload.level))
        case .patternPlay:
            path.append(FlowStep.playPattern(payload.activity, payload.difficulty, payload.level))
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
