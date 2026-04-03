//
//  PatternPlaySessionView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct PatternPlaySessionView: View {
    let activity: CasualActivity
    let difficulty: StageDifficulty
    let level: Int
    @Binding var path: NavigationPath
    @StateObject private var vm: PatternPlayViewModel
    @EnvironmentObject private var progress: GameProgressStore
    @State private var sessionStart = Date()
    @State private var outcomePosted = false
    @State private var roundStarted = false

    init(activity: CasualActivity, difficulty: StageDifficulty, level: Int, path: Binding<NavigationPath>) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: PatternPlayViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        PatternPlayScreen(viewModel: vm)
            .navigationTitle("Stage \(level)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sessionStart = Date()
                outcomePosted = false
                if !roundStarted {
                    roundStarted = true
                    vm.beginRound()
                }
            }
            .onDisappear {
                vm.cancelDemo()
            }
            .onChange(of: vm.phase) { newValue in
                guard !outcomePosted else { return }
                if newValue == .won || newValue == .lost {
                    outcomePosted = true
                    complete(won: newValue == .won)
                }
            }
    }

    private func complete(won: Bool) {
        let elapsed = Date().timeIntervalSince(sessionStart)
        progress.recordSession(duration: elapsed, activity: activity)
        let idealBase = Double(vm.sequenceIndices.count)
            * (difficulty == .easy ? 0.95 : (difficulty == .normal ? 0.75 : 0.55))
        let stars = StarCalculation.forPattern(
            won: won,
            mistakes: vm.mistakes,
            duration: elapsed,
            ideal: idealBase + 2
        )
        let freshInfos = won
            ? progress.applyStarsIfBetter(activity: activity, level: level, newStars: stars)
            : []
        let fresh = freshInfos.map { AchievementUnlockPayload(title: $0.title, subtitle: $0.subtitle) }
        let filled = max(vm.userEntries.count, 0)
        let target = vm.sequenceIndices.count
        let acc = won ? 100 : max(0, Int(Double(filled) / Double(max(target, 1)) * 100))
        let payload = ActivitySummaryPayload(
            activity: activity,
            difficulty: difficulty,
            level: level,
            stars: stars,
            won: won,
            durationSeconds: elapsed,
            accuracyPercent: acc,
            detailLineA: won ? "Sequence length \(target) cleared." : "Sequence broken after step \(filled).",
            detailLineB: "Observation cycles replayed: \(vm.mistakes)",
            freshAchievements: fresh
        )
        path.removeLast()
        path.append(FlowStep.wrapUp(payload))
    }
}

struct PatternPlayScreen: View {
    @ObservedObject var viewModel: PatternPlayViewModel

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: viewModel.gridSideLength)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                phaseLabel
                    .padding(16)
                    .appElevatedSurface(cornerRadius: 16)

                Text(explanationText)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<(viewModel.gridSideLength * viewModel.gridSideLength), id: \.self) { idx in
                        patternCell(index: idx)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
    }

    private var phaseLabel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(statusTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            Spacer()
            if viewModel.phase == .input {
                Text("Steps: \(viewModel.userEntries.count)/\(viewModel.sequenceIndices.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
        }
    }

    private var statusTitle: String {
        switch viewModel.phase {
        case .idle:
            return "Ready when you are"
        case .demonstrating:
            return "Watching the signal"
        case .input:
            return "Repeat on the grid"
        case .won:
            return "Perfect repeat"
        case .lost:
            return "Signal broken"
        }
    }

    private var explanationText: String {
        switch viewModel.phase {
        case .idle:
            return "Press begin to watch a short highlight path, then rebuild it with taps."
        case .demonstrating:
            return "Stay with the pacing—your turn arrives right after."
        case .input:
            return "Tap cells in the same order you just saw."
        case .won, .lost:
            return "Round complete. Results arrive next."
        }
    }

    private func patternCell(index: Int) -> some View {
        let lit = viewModel.highlightedIndex == index
        let isInput = viewModel.phase == .input
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                lit
                    ? LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : AppFill.secondaryFaceGradient
            )
            .aspectRatio(1, contentMode: .fit)
            .shadow(color: Color.appBackground.opacity(0.48), radius: lit ? 12 : 7, x: 0, y: lit ? 5 : 4)
            .shadow(color: Color.appAccent.opacity(lit ? 0.22 : 0.1), radius: lit ? 10 : 5, x: 0, y: 2)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(isInput ? 0.5 : 0.15), lineWidth: 2)
            }
            .overlay {
                if lit {
                    Circle()
                        .fill(Color.appBackground.opacity(0.25))
                        .padding(12)
                }
            }
            .onTapGesture {
                guard isInput else { return }
                viewModel.tapCell(index: index)
            }
    }
}
