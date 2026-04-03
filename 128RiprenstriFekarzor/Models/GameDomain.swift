//
//  GameDomain.swift
//  128RiprenstriFekarzor
//

import Foundation

enum CasualActivity: String, CaseIterable, Identifiable, Hashable, Codable {
    case colorCascade
    case shapeShuffle
    case patternPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colorCascade: return "Color Cascade"
        case .shapeShuffle: return "Shape Shuffle"
        case .patternPlay: return "Pattern Play"
        }
    }

    var blurb: String {
        switch self {
        case .colorCascade:
            return "Swipe adjacent tiles to build lines of three or more matching hues."
        case .shapeShuffle:
            return "Drag geometry into place until the layout mirrors the reference."
        case .patternPlay:
            return "Watch the signal, then repeat the exact order on the grid."
        }
    }
}

enum StageDifficulty: String, CaseIterable, Identifiable, Hashable, Codable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum GameProgress {
    static let levelsPerActivity = 12
}
