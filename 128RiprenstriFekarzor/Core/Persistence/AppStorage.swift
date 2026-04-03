//
//  AppStorage.swift
//  128RiprenstriFekarzor
//

import Foundation
import Combine

final class GameProgressStore: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalPlaySeconds = "totalPlaySeconds"
        static let totalSessions = "totalSessions"
        static func stars(_ activity: CasualActivity, level: Int) -> String {
            "stars_\(activity.rawValue)_\(level)"
        }

        static func sessions(for activity: CasualActivity) -> String {
            "sessions_\(activity.rawValue)"
        }
    }

    @Published private(set) var hasSeenOnboarding: Bool

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        hasSeenOnboarding = true
    }

    func stars(for activity: CasualActivity, level: Int) -> Int {
        let key = Keys.stars(activity, level: level)
        return defaults.integer(forKey: key)
    }

    func bestStarsSum(for activity: CasualActivity) -> Int {
        (1...GameProgress.levelsPerActivity).reduce(0) { $0 + stars(for: activity, level: $1) }
    }

    func totalStarsAcrossApp() -> Int {
        CasualActivity.allCases.reduce(0) { partial, activity in
            partial + bestStarsSum(for: activity)
        }
    }

    func isLevelUnlocked(activity: CasualActivity, level: Int) -> Bool {
        if level <= 1 { return true }
        return stars(for: activity, level: level - 1) >= 1
    }

    func recordSession(duration: TimeInterval, activity: CasualActivity) {
        let current = defaults.double(forKey: Keys.totalPlaySeconds)
        defaults.set(current + duration, forKey: Keys.totalPlaySeconds)
        let sessions = defaults.integer(forKey: Keys.totalSessions)
        defaults.set(sessions + 1, forKey: Keys.totalSessions)
        let actKey = Keys.sessions(for: activity)
        defaults.set(defaults.integer(forKey: actKey) + 1, forKey: actKey)
        objectWillChange.send()
    }

    func sessions(for activity: CasualActivity) -> Int {
        defaults.integer(forKey: Keys.sessions(for: activity))
    }

    func totalPlaySeconds() -> TimeInterval {
        defaults.double(forKey: Keys.totalPlaySeconds)
    }

    func totalSessionsPlayed() -> Int {
        defaults.integer(forKey: Keys.totalSessions)
    }

    /// Returns achievements that became satisfied only after applying this star rating (best stored increases or first completion).
    func applyStarsIfBetter(activity: CasualActivity, level: Int, newStars: Int) -> [AchievementInfo] {
        let beforeIds = Set(snapshotAchievementInfos().filter { earned(key: $0.id) }.map(\.id))
        let key = Keys.stars(activity, level: level)
        let existing = defaults.integer(forKey: key)
        if newStars > existing {
            defaults.set(newStars, forKey: key)
        }
        objectWillChange.send()
        let after = snapshotAchievementInfos().filter { earned(key: $0.id) }
        return after.filter { !beforeIds.contains($0.id) }
    }

    func resetAll() {
        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys {
            defaults.removeObject(forKey: key)
        }
        hasSeenOnboarding = false
        NotificationCenter.default.post(name: .gameProgressDidReset, object: nil)
        objectWillChange.send()
    }

    // MARK: - Achievements (derived)

    struct AchievementInfo: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
    }

    func allEarnedAchievements() -> [AchievementInfo] {
        snapshotAchievementInfos().filter { earned(key: $0.id) }
    }

    func totalAchievementCount() -> Int {
        snapshotAchievementInfos().count
    }

    func unlockedAchievementCount() -> Int {
        snapshotAchievementInfos().filter { earned(key: $0.id) }.count
    }

    /// Unlocked trophies first, then locked; each row includes whether it is unlocked.
    func rewardsCatalogRows() -> [(info: AchievementInfo, unlocked: Bool)] {
        snapshotAchievementInfos()
            .map { ($0, earned(key: $0.id)) }
            .sorted { a, b in
                if a.unlocked != b.unlocked { return a.unlocked && !b.unlocked }
                return a.info.title.localizedCaseInsensitiveCompare(b.info.title) == .orderedAscending
            }
    }

    private func earned(key: String) -> Bool {
        let totalStars = totalStarsAcrossApp()
        let sessionsAll = totalSessionsPlayed()
        let playTime = totalPlaySeconds()

        switch key {
        case "first_step":
            return CasualActivity.allCases.contains { act in
                (1...GameProgress.levelsPerActivity).contains { stars(for: act, level: $0) > 0 }
            }
        case "spark_five":
            return totalStars >= 5
        case "spark_fifteen":
            return totalStars >= 15
        case "star_hunter":
            return totalStars >= 30
        case "astral_fifty":
            return totalStars >= 50
        case "deep_seventy":
            return totalStars >= 75
        case "full_sky":
            return totalStars >= 108

        case "sessions_five":
            return sessionsAll >= 5
        case "dedicated_player":
            return sessionsAll >= 10
        case "sessions_twentyfive":
            return sessionsAll >= 25
        case "sessions_fifty":
            return sessionsAll >= 50

        case "time_bloom":
            return playTime >= 600
        case "time_marathon":
            return playTime >= 1800
        case "time_endurance":
            return playTime >= 3600

        case "fan_cascade":
            return bestStarsSum(for: .colorCascade) >= 15
        case "fan_shuffle":
            return bestStarsSum(for: .shapeShuffle) >= 15
        case "fan_pattern":
            return bestStarsSum(for: .patternPlay) >= 15
        case "deep_cascade":
            return bestStarsSum(for: .colorCascade) >= 30
        case "deep_shuffle":
            return bestStarsSum(for: .shapeShuffle) >= 30
        case "deep_pattern":
            return bestStarsSum(for: .patternPlay) >= 30

        case "explorer_triple":
            return CasualActivity.allCases.allSatisfy { bestStarsSum(for: $0) >= 1 }
        case "balanced_rounds":
            return CasualActivity.allCases.allSatisfy { sessions(for: $0) >= 3 }
        case "orbit_regular":
            return CasualActivity.allCases.allSatisfy { sessions(for: $0) >= 8 }

        case "perfectionist":
            return totalThreeStarLevels() >= 5
        case "sharp_twelve":
            return totalThreeStarLevels() >= 12
        case "brilliant_twentyfour":
            return totalThreeStarLevels() >= 24
        case "flawless_grid":
            return totalThreeStarLevels() >= 36

        case "cascade_master":
            return activityFullyCleared(.colorCascade)
        case "shuffle_master":
            return activityFullyCleared(.shapeShuffle)
        case "pattern_master":
            return activityFullyCleared(.patternPlay)
        case "triad_crown":
            return activityFullyCleared(.colorCascade)
                && activityFullyCleared(.shapeShuffle)
                && activityFullyCleared(.patternPlay)

        case "peak_finale":
            return CasualActivity.allCases.contains { stars(for: $0, level: GameProgress.levelsPerActivity) >= 1 }

        case "dual_path":
            return fullPathClearCount() >= 2
        case "solo_devotion":
            return bestStarsSum(for: .colorCascade) >= 20
                || bestStarsSum(for: .shapeShuffle) >= 20
                || bestStarsSum(for: .patternPlay) >= 20

        default:
            return false
        }
    }

    private func activityFullyCleared(_ activity: CasualActivity) -> Bool {
        (1...GameProgress.levelsPerActivity).allSatisfy { stars(for: activity, level: $0) >= 1 }
    }

    private func fullPathClearCount() -> Int {
        CasualActivity.allCases.filter { activityFullyCleared($0) }.count
    }

    private func totalThreeStarLevels() -> Int {
        var n = 0
        for act in CasualActivity.allCases {
            for lv in 1...GameProgress.levelsPerActivity {
                if stars(for: act, level: lv) >= 3 { n += 1 }
            }
        }
        return n
    }

    private func snapshotAchievementInfos() -> [AchievementInfo] {
        [
            AchievementInfo(id: "first_step", title: "First Touch", subtitle: "Earn a star on any stage."),
            AchievementInfo(id: "spark_five", title: "Warm Ember", subtitle: "Collect 5 stars in total."),
            AchievementInfo(id: "spark_fifteen", title: "Growing Glow", subtitle: "Collect 15 stars in total."),
            AchievementInfo(id: "star_hunter", title: "Bright Trail", subtitle: "Collect 30 stars in total."),
            AchievementInfo(id: "astral_fifty", title: "Wide Orbit", subtitle: "Collect 50 stars in total."),
            AchievementInfo(id: "deep_seventy", title: "Deep Luminous", subtitle: "Collect 75 stars in total."),
            AchievementInfo(id: "full_sky", title: "Full Constellation", subtitle: "Collect every possible star."),
            AchievementInfo(id: "sessions_five", title: "Returning Visitor", subtitle: "Finish 5 sessions across all paths."),
            AchievementInfo(id: "dedicated_player", title: "Steady Rhythm", subtitle: "Finish 10 sessions."),
            AchievementInfo(id: "sessions_twentyfive", title: "Endless Loop", subtitle: "Finish 25 sessions."),
            AchievementInfo(id: "sessions_fifty", title: "Marathon Mind", subtitle: "Finish 50 sessions."),
            AchievementInfo(id: "time_bloom", title: "Quiet Quarter", subtitle: "Spend 10 minutes playing in total."),
            AchievementInfo(id: "time_marathon", title: "Long Arc", subtitle: "Spend 30 minutes playing in total."),
            AchievementInfo(id: "time_endurance", title: "Deep Hours", subtitle: "Spend 60 minutes playing in total."),
            AchievementInfo(id: "fan_cascade", title: "Cascade Regular", subtitle: "Earn 15 stars in Color Cascade."),
            AchievementInfo(id: "fan_shuffle", title: "Shuffle Regular", subtitle: "Earn 15 stars in Shape Shuffle."),
            AchievementInfo(id: "fan_pattern", title: "Pattern Regular", subtitle: "Earn 15 stars in Pattern Play."),
            AchievementInfo(id: "deep_cascade", title: "Cascade Devotion", subtitle: "Earn 30 stars in Color Cascade."),
            AchievementInfo(id: "deep_shuffle", title: "Shuffle Devotion", subtitle: "Earn 30 stars in Shape Shuffle."),
            AchievementInfo(id: "deep_pattern", title: "Pattern Devotion", subtitle: "Earn 30 stars in Pattern Play."),
            AchievementInfo(id: "explorer_triple", title: "Triple Visitor", subtitle: "Earn at least one star in every path."),
            AchievementInfo(id: "balanced_rounds", title: "Even Split", subtitle: "Finish 3 sessions in each path."),
            AchievementInfo(id: "orbit_regular", title: "Triple Orbit", subtitle: "Finish 8 sessions in each path."),
            AchievementInfo(id: "perfectionist", title: "Triple Shine", subtitle: "Earn top marks on 5 different stages."),
            AchievementInfo(id: "sharp_twelve", title: "Sharpened Dozen", subtitle: "Earn top marks on 12 different stages."),
            AchievementInfo(id: "brilliant_twentyfour", title: "Radiant Two Dozen", subtitle: "Earn top marks on 24 different stages."),
            AchievementInfo(id: "flawless_grid", title: "Flawless Field", subtitle: "Earn top marks on every stage in all paths."),
            AchievementInfo(id: "cascade_master", title: "Cascade Cleared", subtitle: "Earn a star on every Color Cascade stage."),
            AchievementInfo(id: "shuffle_master", title: "Shapes Aligned", subtitle: "Earn a star on every Shape Shuffle stage."),
            AchievementInfo(id: "pattern_master", title: "Signals Read", subtitle: "Earn a star on every Pattern Play stage."),
            AchievementInfo(id: "triad_crown", title: "Triad Crown", subtitle: "Clear all stages in all three paths."),
            AchievementInfo(id: "peak_finale", title: "Summit Stage", subtitle: "Beat the final stage in any path."),
            AchievementInfo(id: "dual_path", title: "Dual Dominion", subtitle: "Fully clear two complete paths."),
            AchievementInfo(id: "solo_devotion", title: "Focused Path", subtitle: "Earn 20 stars in a single path.")
        ]
    }
}
