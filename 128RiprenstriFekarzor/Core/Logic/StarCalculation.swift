//
//  StarCalculation.swift
//  128RiprenstriFekarzor
//

import Foundation

enum StarCalculation {
    static func forCascade(won: Bool, movesLeft: Int, initialMoves: Int) -> Int {
        guard won else { return 0 }
        var score = 3
        let reserve = Double(movesLeft) / Double(max(initialMoves, 1))
        if reserve < 0.2 { score -= 1 }
        if reserve < 0.05 { score -= 1 }
        return max(1, min(3, score))
    }

    static func forShuffle(won: Bool, mistakes: Int) -> Int {
        guard won else { return 0 }
        var score = 3
        if mistakes >= 1 { score -= 1 }
        if mistakes >= 2 { score -= 1 }
        return max(1, min(3, score))
    }

    static func forPattern(won: Bool, mistakes: Int, duration: TimeInterval, ideal: TimeInterval) -> Int {
        guard won else { return 0 }
        var score = 3
        if mistakes > 0 { score -= 1 }
        if duration > ideal * 1.4 { score -= 1 }
        return max(1, min(3, score))
    }
}
