//
//  PatternPlayViewModel.swift
//  128RiprenstriFekarzor
//

import Foundation
import SwiftUI
import Combine

enum PatternPhaseState: Equatable {
    case idle
    case demonstrating
    case input
    case won
    case lost
}

@MainActor
final class PatternPlayViewModel: ObservableObject {
    @Published private(set) var phase: PatternPhaseState = .idle
    @Published private(set) var highlightedIndex: Int?
    @Published private(set) var sequenceIndices: [Int] = []
    @Published private(set) var userEntries: [Int] = []
    @Published private(set) var mistakes: Int = 0
    @Published private(set) var gridSideLength: Int

    let levelIndex: Int
    let difficulty: StageDifficulty

    private let sequenceLength: Int
    private let dwell: UInt64
    private let pauseBetween: UInt64
    private let mistakeCap: Int
    private var demoTask: Task<Void, Never>?

    init(level: Int, difficulty: StageDifficulty) {
        levelIndex = level
        self.difficulty = difficulty
        let tier = min(max(level, 1), GameProgress.levelsPerActivity)
        gridSideLength = difficulty == .easy ? 3 : 4
        sequenceLength = 3 + min(tier, 4) + (difficulty == .hard ? 2 : (difficulty == .normal ? 1 : 0))
        dwell = difficulty == .easy ? 550_000_000 : (difficulty == .normal ? 400_000_000 : 280_000_000)
        pauseBetween = difficulty == .easy ? 120_000_000 : 80_000_000
        mistakeCap = difficulty == .easy ? 2 : (difficulty == .normal ? 1 : 0)
    }

    func beginRound() {
        demoTask?.cancel()
        let cellCount = gridSideLength * gridSideLength
        sequenceIndices = (0..<sequenceLength).map { _ in Int.random(in: 0..<cellCount) }
        userEntries = []
        mistakes = 0
        phase = .demonstrating
        demoTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            for idx in sequenceIndices {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.highlightedIndex = idx
                }
                try? await Task.sleep(nanoseconds: dwell)
                await MainActor.run {
                    self.highlightedIndex = nil
                }
                try? await Task.sleep(nanoseconds: pauseBetween)
            }
            await MainActor.run {
                self.phase = .input
            }
        }
    }

    func tapCell(index: Int) {
        guard phase == .input else { return }
        let nextPosition = userEntries.count
        guard nextPosition < sequenceIndices.count else { return }
        let expected = sequenceIndices[nextPosition]
        if index == expected {
            userEntries.append(index)
            if userEntries.count == sequenceIndices.count {
                phase = .won
            }
        } else {
            mistakes += 1
            userEntries = []
            if mistakes > mistakeCap {
                phase = .lost
            } else {
                phase = .demonstrating
                demoTask?.cancel()
                demoTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await replayDemonstration()
                }
            }
        }
    }

    private func replayDemonstration() async {
        for idx in sequenceIndices {
            if Task.isCancelled { return }
            await MainActor.run {
                self.highlightedIndex = idx
            }
            try? await Task.sleep(nanoseconds: dwell)
            await MainActor.run {
                self.highlightedIndex = nil
            }
            try? await Task.sleep(nanoseconds: pauseBetween)
        }
        await MainActor.run {
            self.phase = .input
        }
    }

    func cancelDemo() {
        demoTask?.cancel()
        demoTask = nil
    }
}
