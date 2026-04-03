//
//  ShapeShuffleViewModel.swift
//  128RiprenstriFekarzor
//

import Foundation
import SwiftUI
import Combine

enum ShapeGlyph: Int, CaseIterable, Identifiable {
    case disk
    case ring
    case triangle
    case kite
    case square

    var id: Int { rawValue }
}

struct ShapeChallengeItem: Identifiable, Equatable {
    let id: UUID
    let glyph: ShapeGlyph
    var rotationQuarterTurns: Int

    init(glyph: ShapeGlyph, rotationQuarterTurns: Int = 0) {
        id = UUID()
        self.glyph = glyph
        self.rotationQuarterTurns = rotationQuarterTurns
    }
}

enum ShapeShuffleState: Equatable {
    case arranging
    case won
    case lost
}

@MainActor
final class ShapeShuffleViewModel: ObservableObject {
    @Published private(set) var slotTargets: [ShapeChallengeItem]
    @Published private(set) var slotPlacements: [ShapeChallengeItem?]
    @Published private(set) var tray: [ShapeChallengeItem]
    @Published private(set) var selectedTrayIndex: Int?
    @Published private(set) var playState: ShapeShuffleState = .arranging
    @Published private(set) var mistakes: Int = 0
    @Published private(set) var rotationLocked: Bool

    let levelIndex: Int
    let difficulty: StageDifficulty
    private let mistakeLimit: Int

    init(level: Int, difficulty: StageDifficulty) {
        levelIndex = level
        self.difficulty = difficulty
        let count = Self.slotCount(level: level, difficulty: difficulty)
        mistakeLimit = difficulty == .easy ? 5 : (difficulty == .normal ? 3 : 2)
        rotationLocked = difficulty != .hard

        var glyphs: [ShapeGlyph] = []
        while glyphs.count < count {
            glyphs.append(contentsOf: ShapeGlyph.allCases.shuffled())
        }
        glyphs = Array(glyphs.prefix(count))

        var targets: [ShapeChallengeItem] = glyphs.map { g in
            let rot = difficulty == .hard ? Int.random(in: 0..<4) : 0
            return ShapeChallengeItem(glyph: g, rotationQuarterTurns: rot)
        }
        targets.shuffle()

        slotTargets = targets
        slotPlacements = Array(repeating: nil, count: count)

        var trayItems = targets.map { t in
            ShapeChallengeItem(glyph: t.glyph, rotationQuarterTurns: difficulty == .hard ? Int.random(in: 0..<4) : 0)
        }
        trayItems.shuffle()
        tray = trayItems
    }

    private static func slotCount(level: Int, difficulty: StageDifficulty) -> Int {
        let tier = min(max(level, 1), GameProgress.levelsPerActivity)
        let base = 3 + min(tier / 3, 3)
        let bump = difficulty == .hard ? 2 : (difficulty == .normal ? 1 : 0)
        return min(6, base + bump)
    }

    func tapTray(index: Int) {
        guard playState == .arranging else { return }
        guard tray.indices.contains(index) else { return }
        if selectedTrayIndex == index {
            selectedTrayIndex = nil
        } else {
            selectedTrayIndex = index
        }
    }

    func tapSlot(index: Int) {
        guard playState == .arranging else { return }
        guard slotPlacements.indices.contains(index) else { return }

        if let ti = selectedTrayIndex {
            placeFromTray(trayIndex: ti, slotIndex: index)
            selectedTrayIndex = nil
            return
        }

        if slotPlacements[index] != nil {
            returnPieceToTray(fromSlot: index)
        }
    }

    func rotatePlacement(at index: Int) {
        guard playState == .arranging else { return }
        guard !rotationLocked else { return }
        guard var piece = slotPlacements[index] else { return }
        piece.rotationQuarterTurns = (piece.rotationQuarterTurns + 1) % 4
        slotPlacements[index] = piece
        tryFinalizeBoard()
    }

    private func placeFromTray(trayIndex: Int, slotIndex: Int) {
        guard tray.indices.contains(trayIndex) else { return }
        let piece = tray[trayIndex]
        if let existing = slotPlacements[slotIndex] {
            tray[trayIndex] = existing
        } else {
            tray.remove(at: trayIndex)
        }
        slotPlacements[slotIndex] = piece
        tryFinalizeBoard()
    }

    private func returnPieceToTray(fromSlot index: Int) {
        guard let piece = slotPlacements[index] else { return }
        slotPlacements[index] = nil
        tray.append(piece)
    }

    private func tryFinalizeBoard() {
        guard playState == .arranging else { return }
        guard slotPlacements.allSatisfy({ $0 != nil }) else { return }
        for i in slotTargets.indices {
            if let p = slotPlacements[i] {
                let target = slotTargets[i]
                let shapeOk = p.glyph == target.glyph
                let rotOk = rotationLocked || ((p.rotationQuarterTurns % 4) == (target.rotationQuarterTurns % 4))
                if !shapeOk || !rotOk {
                    handleFailedAssembly()
                    return
                }
            }
        }
        playState = .won
    }

    private func handleFailedAssembly() {
        mistakes += 1
        if mistakes >= mistakeLimit {
            playState = .lost
            return
        }
        let pieces = slotPlacements.compactMap { $0 }
        slotPlacements = Array(repeating: nil, count: slotTargets.count)
        tray = pieces.shuffled()
    }

}
