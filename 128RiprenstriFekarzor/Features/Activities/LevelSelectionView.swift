//
//  LevelSelectionView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct LevelSelectionView: View {
    @EnvironmentObject private var progress: GameProgressStore
    let activity: CasualActivity
    @Binding var path: NavigationPath

    @State private var difficulty: StageDifficulty = .normal
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appHeadingDepth()

                Text("Tune challenge, then open any glowing stage tile.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                Picker("", selection: $difficulty) {
                    ForEach(StageDifficulty.allCases, id: \.self) { d in
                        Text(d.title).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .padding(10)
                .appInsetPanel(cornerRadius: 12)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...GameProgress.levelsPerActivity, id: \.self) { level in
                        levelCell(level)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .gameProgressDidReset)) { _ in
            path = NavigationPath()
        }
    }

    @ViewBuilder
    private func levelCell(_ level: Int) -> some View {
        let unlocked = progress.isLevelUnlocked(activity: activity, level: level)
        let stars = progress.stars(for: activity, level: level)

        Button {
            guard unlocked else { return }
            openLevel(level)
        } label: {
            VStack(spacing: 8) {
                if unlocked {
                    Text("\(level)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                    CompactStarRow(filled: stars, maxStars: 3)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Stage \(level)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(8)
            .levelTileChrome(unlocked: unlocked)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func openLevel(_ level: Int) {
        switch activity {
        case .colorCascade:
            path.append(FlowStep.playCascade(activity, difficulty, level))
        case .shapeShuffle:
            path.append(FlowStep.playShape(activity, difficulty, level))
        case .patternPlay:
            path.append(FlowStep.playPattern(activity, difficulty, level))
        }
    }
}

private struct LevelTileChrome: ViewModifier {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.1), lineWidth: 1.5)
                    )
            }
        }
    }
}

private extension View {
    func levelTileChrome(unlocked: Bool) -> some View {
        modifier(LevelTileChrome(unlocked: unlocked))
    }
}
