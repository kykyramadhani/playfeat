//
//  GameCenter.swift
//  GetCooking
//
//  Game Center: sign in at launch, submit each planet's Buffet points to its
//  own leaderboard, read the top scores for the marathon screen, open the
//  dashboard, and report the story mode's achievements.
//
//  Everything here fails quietly on purpose. A player who declined the sign-in
//  prompt, or has no network, still gets the whole game — GameStorage stays
//  the source of truth for what the UI shows, and Game Center is a bonus
//  layer on top of it.
//

import GameKit
import UIKit

enum GameCenter {
    // Leaderboard IDs must match App Store Connect character for character —
    // a mismatch fails silently, scores just never show up.

    /// The Buffet (marathon) leaderboard of `planet`, in points. Leaderboard
    /// IDs take no hyphens, so the planet's are swapped for underscores.
    static func buffetLeaderboardID(on planet: Planet.ID) -> String {
        "com.reability.playfeat.buffet.\(planet.rawValue.replacingOccurrences(of: "-", with: "_"))"
    }

    /// Call once, from a view that's already on screen: GameKit can hand back a
    /// sign-in screen that needs a window to be presented from.
    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { signInScreen, _ in
            guard let signInScreen else { return }
            rootViewController?.present(signInScreen, animated: true)
        }
    }

    /// Submit every run, not just personal bests — Game Center keeps the best
    /// score per player itself, and a submit that loses to the stored one is a
    /// no-op on their side.
    static func submit(_ score: Int, to leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        Task {
            try? await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        }
    }

    /// Marks `achievements` complete. Reported again on later days, an
    /// achievement already earned stays as it is and shows no banner twice.
    static func report(_ achievements: Set<StoryAchievement>) {
        guard GKLocalPlayer.local.isAuthenticated, !achievements.isEmpty else { return }
        let completed = achievements.map { achievement in
            let report = GKAchievement(identifier: achievement.identifier)
            report.percentComplete = 100
            report.showsCompletionBanner = true
            return report
        }
        Task { try? await GKAchievement.report(completed) }
    }

    /// The best `count` players of all time. Empty when signed out, offline,
    /// or nobody has a score yet — the screen shows its empty state for all three.
    static func topEntries(count: Int, of leaderboardID: String) async -> [LeaderboardEntry] {
        guard GKLocalPlayer.local.isAuthenticated,
              let leaderboard = try? await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]).first,
              let (_, entries, _) = try? await leaderboard.loadEntries(
                  for: .global,
                  timeScope: .allTime,
                  range: NSRange(location: 1, length: count)
              )
        else { return [] }

        let localPlayerID = GKLocalPlayer.local.gamePlayerID
        return entries.map { entry in
            LeaderboardEntry(
                rank: entry.rank,
                name: entry.player.displayName,
                score: entry.score,
                isLocalPlayer: entry.player.gamePlayerID == localPlayerID
            )
        }
    }

    static func showLeaderboard(_ leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated, let root = rootViewController else { return }
        let dashboard = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        dashboard.gameCenterDelegate = dismisser
        root.present(dashboard, animated: true)
    }

    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
    }

    /// GKGameCenterViewController never dismisses itself, and its delegate has
    /// to be an NSObject — hence this one-job singleton.
    private static let dismisser = Dismisser()

    private final class Dismisser: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
