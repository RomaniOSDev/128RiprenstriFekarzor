//
//  ColorCascadeViewModel.swift
//  128RiprenstriFekarzor
//

import Foundation
import SwiftUI
import UIKit
import Combine

struct CascadeTile: Identifiable, Equatable {
    let id: UUID
    var colorIndex: Int

    init(colorIndex: Int) {
        id = UUID()
        self.colorIndex = colorIndex
    }
}

struct GridAddress: Hashable {
    var row: Int
    var column: Int
}

enum CascadePlayState: Equatable {
    case playing
    case won
    case lost
}

@MainActor
final class ColorCascadeViewModel: ObservableObject {
    let rowCount = 8
    let columnCount = 6

    @Published private(set) var cells: [[CascadeTile?]]
    @Published private(set) var matchesClearedTotal: Int = 0
    @Published private(set) var movesLeft: Int
    let initialMoves: Int
    @Published private(set) var targetMatches: Int
    @Published private(set) var playState: CascadePlayState = .playing
    @Published private(set) var colorPaletteCount: Int

    private(set) var levelIndex: Int
    private(set) var difficulty: StageDifficulty

    /// Published so SwiftUI rebuilds controls with reliable hit testing after first tap.
    @Published private(set) var selectedCell: GridAddress?

    init(level: Int, difficulty: StageDifficulty) {
        levelIndex = level
        self.difficulty = difficulty
        let cfg = Self.parameters(level: level, difficulty: difficulty)
        targetMatches = cfg.target
        movesLeft = cfg.moves
        initialMoves = cfg.moves
        colorPaletteCount = cfg.colors
        // Distinct rows (not `Array(repeating:count:)` for inner arrays). Literals avoid touching `self` before `cells` is set.
        cells = (0..<8).map { _ in
            Array<CascadeTile?>(repeating: nil, count: 6)
        }
        refillAllRandom()
        resolveAccidentalMatches()
    }

    private static func parameters(level: Int, difficulty: StageDifficulty) -> (target: Int, moves: Int, colors: Int) {
        let tier = min(max(level, 1), GameProgress.levelsPerActivity)
        let target = 5 + tier + (difficulty == .hard ? 5 : difficulty == .normal ? 3 : 1)
        var moves = 52 - tier * 2
        if difficulty == .easy { moves += 10 }
        if difficulty == .hard { moves -= 12 }
        moves = max(moves, 18)
        let colors = difficulty == .easy ? 4 : (difficulty == .normal ? 5 : 6)
        return (target, moves, colors)
    }

    private func randomColor() -> Int {
        Int.random(in: 0..<colorPaletteCount)
    }

    private func refillAllRandom() {
        var g = cells.map { Array($0) }
        for r in 0..<rowCount {
            for c in 0..<columnCount {
                g[r][c] = CascadeTile(colorIndex: randomColor())
            }
        }
        cells = g
    }

    private func resolveAccidentalMatches() {
        var guardCounter = 0
        while !findMatchCells().isEmpty, guardCounter < 200 {
            guardCounter += 1
            let matches = findMatchCells()
            var g = cells.map { Array($0) }
            for pos in matches {
                g[pos.row][pos.column] = CascadeTile(colorIndex: randomColor())
            }
            cells = g
        }
    }

    func selectCell(at address: GridAddress) {
        guard playState == .playing else { return }
        guard cells[address.row][address.column] != nil else { return }

        if let prev = selectedCell {
            if prev == address {
                selectedCell = nil
                return
            }
            if isAdjacent(prev, address) {
                attemptSwap(prev, address)
                selectedCell = nil
            } else {
                selectedCell = address
            }
        } else {
            selectedCell = address
        }
    }

    private func isAdjacent(_ a: GridAddress, _ b: GridAddress) -> Bool {
        let dr = abs(a.row - b.row)
        let dc = abs(a.column - b.column)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    private func attemptSwap(_ a: GridAddress, _ b: GridAddress) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.86)) {
            swapCells(a, b)
        }
        let created = findMatchCells()
        if created.isEmpty {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            DispatchQueue.main.async { [a, b] in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                    self.swapCells(a, b)
                }
            }
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            movesLeft -= 1
            processChainsFromUserMove()
            evaluateEnd()
        }
    }

    private func swapCells(_ a: GridAddress, _ b: GridAddress) {
        var g = cells.map { Array($0) }
        let t = g[a.row][a.column]
        g[a.row][a.column] = g[b.row][b.column]
        g[b.row][b.column] = t
        cells = g
    }

    private func processChainsFromUserMove() {
        var safety = 0
        repeat {
            safety += 1
            let batch = findMatchCells()
            if batch.isEmpty { break }
            let gained = settleMatches(batch)
            matchesClearedTotal += gained
            applyGravityAndRefill()
            if safety > 80 { break }
        } while true
    }

    private func settleMatches(_ match: Set<GridAddress>) -> Int {
        var groups = 0
        var visited = Set<GridAddress>()
        var g = cells.map { Array($0) }
        for pos in match where !visited.contains(pos) {
            var stack = [pos]
            var cluster = Set<GridAddress>()
            let color = g[pos.row][pos.column]?.colorIndex
            while let p = stack.popLast() {
                if cluster.contains(p) { continue }
                if !match.contains(p) { continue }
                if g[p.row][p.column]?.colorIndex != color { continue }
                cluster.insert(p)
                for n in neighbors(p) {
                    if match.contains(n), !cluster.contains(n) {
                        stack.append(n)
                    }
                }
            }
            if cluster.count >= 3 {
                groups += 1
                for c in cluster {
                    visited.insert(c)
                    g[c.row][c.column] = nil
                }
            }
        }
        cells = g
        return groups
    }

    private func neighbors(_ p: GridAddress) -> [GridAddress] {
        [GridAddress(row: p.row - 1, column: p.column),
         GridAddress(row: p.row + 1, column: p.column),
         GridAddress(row: p.row, column: p.column - 1),
         GridAddress(row: p.row, column: p.column + 1)]
    }

    private func findMatchCells() -> Set<GridAddress> {
        var out = Set<GridAddress>()
        for r in 0..<rowCount {
            var run = 1
            for c in 1..<columnCount {
                let same = cells[r][c]?.colorIndex == cells[r][c - 1]?.colorIndex
                    && cells[r][c] != nil
                if same { run += 1 } else {
                    if run >= 3 {
                        for k in 0..<run { out.insert(GridAddress(row: r, column: c - 1 - k)) }
                    }
                    run = 1
                }
            }
            if run >= 3 {
                for k in 0..<run { out.insert(GridAddress(row: r, column: columnCount - 1 - k)) }
            }
        }
        for c in 0..<columnCount {
            var run = 1
            for r in 1..<rowCount {
                let same = cells[r][c]?.colorIndex == cells[r - 1][c]?.colorIndex
                    && cells[r][c] != nil
                if same { run += 1 } else {
                    if run >= 3 {
                        for k in 0..<run { out.insert(GridAddress(row: r - 1 - k, column: c)) }
                    }
                    run = 1
                }
            }
            if run >= 3 {
                for k in 0..<run { out.insert(GridAddress(row: rowCount - 1 - k, column: c)) }
            }
        }
        return out
    }

    private func applyGravityAndRefill() {
        withAnimation(.easeInOut(duration: 0.22)) {
            var g = cells.map { Array($0) }
            for c in 0..<columnCount {
                var stack: [CascadeTile] = []
                for r in (0..<rowCount).reversed() {
                    if let t = g[r][c] {
                        stack.append(t)
                    }
                }
                var r = rowCount - 1
                for tile in stack {
                    g[r][c] = tile
                    r -= 1
                }
                while r >= 0 {
                    g[r][c] = CascadeTile(colorIndex: randomColor())
                    r -= 1
                }
            }
            cells = g
        }
    }

    private func evaluateEnd() {
        if matchesClearedTotal >= targetMatches {
            playState = .won
        } else if movesLeft <= 0 {
            playState = .lost
        } else if !hasAnyLegalSwap() {
            reshuffleBoard()
        }
    }

    private func hasAnyLegalSwap() -> Bool {
        for r in 0..<rowCount {
            for c in 0..<columnCount {
                let a = GridAddress(row: r, column: c)
                if c + 1 < columnCount {
                    let b = GridAddress(row: r, column: c + 1)
                    swapCells(a, b)
                    let ok = !findMatchCells().isEmpty
                    swapCells(a, b)
                    if ok { return true }
                }
                if r + 1 < rowCount {
                    let b = GridAddress(row: r + 1, column: c)
                    swapCells(a, b)
                    let ok = !findMatchCells().isEmpty
                    swapCells(a, b)
                    if ok { return true }
                }
            }
        }
        return false
    }

    private func reshuffleBoard() {
        refillAllRandom()
        resolveAccidentalMatches()
        var guardCounter = 0
        while !hasAnyLegalSwap(), guardCounter < 30 {
            guardCounter += 1
            refillAllRandom()
            resolveAccidentalMatches()
        }
    }

    func triggerHapticMatch() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }
}
