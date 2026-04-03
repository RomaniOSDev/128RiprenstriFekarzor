//
//  NavigationRoutes.swift
//  128RiprenstriFekarzor
//

import Foundation

enum FlowStep: Hashable {
    case pickLevels(CasualActivity)
    case playCascade(CasualActivity, StageDifficulty, Int)
    case playShape(CasualActivity, StageDifficulty, Int)
    case playPattern(CasualActivity, StageDifficulty, Int)
    case wrapUp(ActivitySummaryPayload)
}

struct AchievementUnlockPayload: Hashable {
    let title: String
    let subtitle: String
}

struct ActivitySummaryPayload: Hashable {
    let activity: CasualActivity
    let difficulty: StageDifficulty
    let level: Int
    let stars: Int
    let won: Bool
    let durationSeconds: Double
    let accuracyPercent: Int
    let detailLineA: String
    let detailLineB: String
    let freshAchievements: [AchievementUnlockPayload]
}
