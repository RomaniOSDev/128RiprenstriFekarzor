//
//  ColorCascadeSessionView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ColorCascadeSessionView: View {
    let activity: CasualActivity
    let difficulty: StageDifficulty
    let level: Int
    @Binding var path: NavigationPath
    @StateObject private var vm: ColorCascadeViewModel
    @EnvironmentObject private var progress: GameProgressStore
    @State private var sessionStart = Date()
    @State private var outcomePosted = false
    @State private var lastMatchTotal = 0

    init(activity: CasualActivity, difficulty: StageDifficulty, level: Int, path: Binding<NavigationPath>) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: ColorCascadeViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        ColorCascadePlayView(viewModel: vm)
            .navigationTitle("Stage \(level)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sessionStart = Date()
                lastMatchTotal = 0
            }
            .onChange(of: vm.matchesClearedTotal) { newValue in
                if newValue > lastMatchTotal {
                    vm.triggerHapticMatch()
                    lastMatchTotal = newValue
                }
            }
            .onChange(of: vm.playState) { newValue in
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
        let stars = StarCalculation.forCascade(won: won, movesLeft: vm.movesLeft, initialMoves: vm.initialMoves)
        let freshInfos = won
            ? progress.applyStarsIfBetter(activity: activity, level: level, newStars: stars)
            : []
        let fresh = freshInfos.map { AchievementUnlockPayload(title: $0.title, subtitle: $0.subtitle) }
        let acc: Int
        if won {
            acc = min(100, Int(Double(vm.matchesClearedTotal) / Double(max(vm.targetMatches, 1)) * 100))
        } else {
            acc = max(0, min(99, Int(Double(vm.matchesClearedTotal) / Double(max(vm.targetMatches, 1)) * 100)))
        }
        let payload = ActivitySummaryPayload(
            activity: activity,
            difficulty: difficulty,
            level: level,
            stars: stars,
            won: won,
            durationSeconds: elapsed,
            accuracyPercent: acc,
            detailLineA: won
                ? "Match groups cleared: \(vm.matchesClearedTotal) / \(vm.targetMatches)"
                : "Stopped at \(vm.matchesClearedTotal) / \(vm.targetMatches) groups",
            detailLineB: "Moves remaining: \(max(vm.movesLeft, 0))",
            freshAchievements: fresh
        )
        path.removeLast()
        path.append(FlowStep.wrapUp(payload))
    }
}

struct ColorCascadePlayView: View {
    @ObservedObject var viewModel: ColorCascadeViewModel

    private let gridSpacing: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let pad: CGFloat = 16
            let contentWidth = max(geometry.size.width - pad * 2, 120)
            let cols = CGFloat(viewModel.columnCount)
            let rows = CGFloat(viewModel.rowCount)
            let hGaps = gridSpacing * max(cols - 1, 0)
            let vGaps = gridSpacing * max(rows - 1, 0)
            let sideFromWidth = (contentWidth - hGaps) / max(cols, 1)
            let chrome: CGFloat = 168
            let availableHeight = max(geometry.size.height - chrome, 140)
            let sideFromHeight = (availableHeight - vGaps) / max(rows, 1)
            let cellSide = max(44, floor(min(sideFromWidth, sideFromHeight) * 100) / 100)
            let gridHeight = rows * cellSide + vGaps

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cascade goal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Text("Clear \(viewModel.targetMatches) match groups")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.appTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Moves")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Text("\(max(viewModel.movesLeft, 0))")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }

                    Text("Tap two orthogonal neighbors to swap. The swap stays only if it creates a straight line of three or more matching colors; otherwise tiles slide back.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .appElevatedSurface(cornerRadius: 18)

                cascadeGrid(cellSide: cellSide)
                    .frame(width: contentWidth, height: gridHeight, alignment: .topLeading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, pad)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
        }
        .background(Color.clear)
    }

    private func cascadeGrid(cellSide: CGFloat) -> some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<viewModel.rowCount, id: \.self) { r in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<viewModel.columnCount, id: \.self) { c in
                        let addr = GridAddress(row: r, column: c)
                        let isSelected = viewModel.selectedCell == addr
                        ColorCascadeInteractiveTile(
                            tile: viewModel.cells[r][c],
                            paletteIndex: viewModel.cells[r][c]?.colorIndex ?? 0,
                            isSelected: isSelected,
                            cellSide: cellSide,
                            onTap: { viewModel.selectCell(at: addr) }
                        )
                    }
                }
            }
        }
    }
}

private struct ColorCascadeInteractiveTile: View {
    let tile: CascadeTile?
    let paletteIndex: Int
    let isSelected: Bool
    let cellSide: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.clear)
                CascadeCellCanvas(
                    tile: tile,
                    paletteIndex: paletteIndex,
                    isSelected: isSelected
                )
            }
            .frame(width: cellSide, height: cellSide)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CascadeCellCanvas: View {
    let tile: CascadeTile?
    let paletteIndex: Int
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            if tile != nil {
                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
                    let rr = RoundedRectangle(cornerRadius: 8, style: .continuous)
                    let path = rr.path(in: rect)
                    let (a, b) = gradientColors(for: paletteIndex)
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [a, b]),
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                        )
                    )
                    context.stroke(path, with: .color(Color.appTextPrimary.opacity(0.12)), lineWidth: 1)
                }
                .shadow(color: Color.appBackground.opacity(0.45), radius: 6, x: 0, y: 3)
                .shadow(color: Color.appAccent.opacity(0.14), radius: 4, x: 0, y: 2)
                .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.appSurface.opacity(0.3))
                    .allowsHitTesting(false)
            }
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.appPrimary, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
    }

    private func gradientColors(for index: Int) -> (Color, Color) {
        let i = abs(index) % 6
        switch i {
        case 0: return (Color.appPrimary, Color.appAccent)
        case 1: return (Color.appAccent, Color.appTextPrimary)
        case 2: return (Color.appPrimary.opacity(0.85), Color.appSurface)
        case 3: return (Color.appAccent.opacity(0.9), Color.appPrimary.opacity(0.65))
        case 4: return (Color.appTextPrimary.opacity(0.95), Color.appAccent)
        default: return (Color.appSurface, Color.appPrimary)
        }
    }
}
