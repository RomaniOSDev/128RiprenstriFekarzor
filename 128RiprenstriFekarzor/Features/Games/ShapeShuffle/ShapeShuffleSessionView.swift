//
//  ShapeShuffleSessionView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ShapeShuffleSessionView: View {
    let activity: CasualActivity
    let difficulty: StageDifficulty
    let level: Int
    @Binding var path: NavigationPath
    @StateObject private var vm: ShapeShuffleViewModel
    @EnvironmentObject private var progress: GameProgressStore
    @State private var sessionStart = Date()
    @State private var outcomePosted = false

    init(activity: CasualActivity, difficulty: StageDifficulty, level: Int, path: Binding<NavigationPath>) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        _path = path
        _vm = StateObject(wrappedValue: ShapeShuffleViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        ShapeShufflePlayView(viewModel: vm)
            .navigationTitle("Stage \(level)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sessionStart = Date()
                outcomePosted = false
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
        let stars = StarCalculation.forShuffle(won: won, mistakes: vm.mistakes)
        let freshInfos = won
            ? progress.applyStarsIfBetter(activity: activity, level: level, newStars: stars)
            : []
        let fresh = freshInfos.map { AchievementUnlockPayload(title: $0.title, subtitle: $0.subtitle) }
        let acc = won ? max(0, 100 - vm.mistakes * 18) : max(0, 100 - vm.mistakes * 25)
        let payload = ActivitySummaryPayload(
            activity: activity,
            difficulty: difficulty,
            level: level,
            stars: stars,
            won: won,
            durationSeconds: elapsed,
            accuracyPercent: min(100, acc),
            detailLineA: won ? "Arrangement matches the blueprint." : "Blueprint still misaligned.",
            detailLineB: "Attempts used: \(vm.mistakes)",
            freshAchievements: fresh
        )
        path.removeLast()
        path.append(FlowStep.wrapUp(payload))
    }
}

struct ShapeShufflePlayView: View {
    @ObservedObject var viewModel: ShapeShuffleViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Reference strip")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.slotTargets.enumerated()), id: \.offset) { index, target in
                            VStack(spacing: 6) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.appTextSecondary)
                                ShapeGlyphCanvas(
                                    glyph: target.glyph,
                                    quarterTurns: target.rotationQuarterTurns,
                                    stroke: Color.appAccent
                                )
                                .frame(width: 52, height: 52)
                                .padding(8)
                                .appInsetPanel(cornerRadius: 12)
                            }
                        }
                    }
                }

                Text("Slots")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 86), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(viewModel.slotPlacements.indices, id: \.self) { index in
                        slotTile(index: index)
                    }
                }

                Text("Tray")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                Text(viewModel.rotationLocked
                    ? "Pick a tray piece, then tap a slot to place it."
                    : "After placing, tap the small turn control on a slot to spin its piece.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.tray.indices, id: \.self) { i in
                            let piece = viewModel.tray[i]
                            Button {
                                viewModel.tapTray(index: i)
                            } label: {
                                ShapeGlyphCanvas(
                                    glyph: piece.glyph,
                                    quarterTurns: piece.rotationQuarterTurns,
                                    stroke: viewModel.selectedTrayIndex == i ? Color.appPrimary : Color.appAccent
                                )
                                .frame(width: 58, height: 58)
                                .padding(10)
                                .appElevatedSurface(cornerRadius: 14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(
                                            viewModel.selectedTrayIndex == i ? Color.appPrimary : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private func slotTile(index: Int) -> some View {
        let placed = viewModel.slotPlacements[index]
        ZStack(alignment: .topTrailing) {
            Color.clear
            if let piece = placed {
                ShapeGlyphCanvas(
                    glyph: piece.glyph,
                    quarterTurns: piece.rotationQuarterTurns,
                    stroke: Color.appPrimary
                )
                .frame(width: 60, height: 60)
                .padding(12)
            } else {
                Text("Empty")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            if placed != nil, !viewModel.rotationLocked {
                Button {
                    viewModel.rotatePlacement(at: index)
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.appAccent))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .frame(minHeight: 88)
        .appElevatedSurface(cornerRadius: 16)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            viewModel.tapSlot(index: index)
        }
    }
}

struct ShapeGlyphCanvas: View {
    let glyph: ShapeGlyph
    let quarterTurns: Int
    let stroke: Color

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            let g = glyphPath(glyph, in: rect)
            context.stroke(
                g,
                with: .linearGradient(
                    Gradient(colors: [stroke, Color.appTextPrimary.opacity(0.85)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                ),
                lineWidth: 3.5
            )
        }
        .rotationEffect(.degrees(Double(quarterTurns % 4) * 90))
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: quarterTurns)
    }

    private func glyphPath(_ glyph: ShapeGlyph, in rect: CGRect) -> Path {
_GlyphBuilder.glyphPath(glyph, in: rect)
    }
}

enum _GlyphBuilder {
    static func glyphPath(_ glyph: ShapeGlyph, in rect: CGRect) -> Path {
        switch glyph {
        case .disk:
            return Circle().path(in: rect)
        case .ring:
            var p = Path()
            p.addEllipse(in: rect)
            let inset = rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.28)
            p.addEllipse(in: inset)
            return p
        case .triangle:
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
            return p
        case .kite:
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
            return p
        case .square:
            return RoundedRectangle(cornerRadius: 6, style: .continuous).path(in: rect)
        }
    }
}
